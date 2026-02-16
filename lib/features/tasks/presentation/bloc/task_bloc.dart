// Task Bloc - Business Logic Component
// Manages all task-related state transitions.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/notification_service.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;
  final NotificationService notificationService;
  final SettingsCubit settingsCubit;
  final Uuid _uuid = const Uuid();
  StreamSubscription? _taskSubscription;

  bool get _notificationsEnabled => settingsCubit.state.notificationsEnabled;

  TaskBloc({
    required this.repository,
    required this.notificationService,
    required this.settingsCubit,
  }) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<ToggleTaskStatus>(_onToggleTaskStatus);
    on<DeleteTask>(_onDeleteTask);
    on<AddSubtask>(_onAddSubtask);
    on<FilterTasks>(_onFilterTasks);
    on<SearchQueryChanged>(_onSearchQueryChanged);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      // Subscribe to the reactive stream
      await _taskSubscription?.cancel();

      // Trigger background sync (non-blocking)
      repository.syncNow();

      await emit.forEach<List<TaskEntity>>(
        repository.watchTasks(),
        onData: (tasks) {
          final currentFilter = state is TaskLoaded
              ? (state as TaskLoaded).activeFilter
              : TaskFilter.all;
          final currentQuery = state is TaskLoaded
              ? (state as TaskLoaded).searchQuery
              : '';
          final filtered = _applyFilter(tasks, currentFilter, currentQuery);
          return TaskLoaded(
            tasks: tasks,
            filteredTasks: filtered,
            activeFilter: currentFilter,
            searchQuery: currentQuery,
            completedCount: tasks.where((t) => t.isCompleted).length,
            totalCount: tasks.length,
          );
        },
        onError: (error, stackTrace) => TaskError(error.toString()),
      );
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    final taskId = _uuid.v4();
    try {
      // GATED: Only show/schedule notifications for top-level tasks (no parentId)
      if (event.parentId == null && _notificationsEnabled) {
        // 1) Show immediate notification BEFORE any potentially slow repo calls
        notificationService
            .showImmediate(
              title: '✅ Task Created',
              body: '"${event.title}" has been added to your tasks',
            )
            .catchError((e) => debugPrint('⚠️ Notification error: $e'));

        // 2) Schedule timed reminders if due date is set
        if (event.dueDate != null) {
          notificationService
              .scheduleTaskReminder(
                taskId: taskId,
                title: event.title,
                dueDate: event.dueDate!,
              )
              .catchError((e) => debugPrint('⚠️ Reminder error: $e'));
        }
      }

      final now = DateTime.now();
      final task = TaskEntity(
        id: taskId,
        title: event.title,
        description: event.description,
        priority: event.priority,
        dueDate: event.dueDate,
        tags: event.tags,
        parentId: event.parentId,
        createdAt: now,
        updatedAt: now,
        sortOrder: state is TaskLoaded ? (state as TaskLoaded).tasks.length : 0,
        isRecurring: event.isRecurring,
        recurringPattern: event.recurringPattern,
      );
      await repository.addTask(task);
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      await repository.updateTask(
        event.task.copyWith(updatedAt: DateTime.now()),
      );

      // GATED: Only for top-level tasks
      if (event.task.parentId == null && _notificationsEnabled) {
        if (event.task.dueDate != null) {
          await notificationService.scheduleTaskReminder(
            taskId: event.task.id,
            title: event.task.title,
            dueDate: event.task.dueDate!,
          );
        } else {
          await notificationService.cancelTaskReminder(event.task.id);
        }
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onToggleTaskStatus(
    ToggleTaskStatus event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final isCompleting = !event.task.isCompleted;
      final newStatus = isCompleting ? TaskStatus.completed : TaskStatus.todo;

      await repository.updateTask(
        event.task.copyWith(status: newStatus, updatedAt: DateTime.now()),
      );

      if (isCompleting) {
        await notificationService.cancelTaskReminder(event.task.id);

        // Handle Recurrence
        if (event.task.isRecurring && event.task.dueDate != null) {
          final nextDueDate = _calculateNextDueDate(
            event.task.dueDate!,
            event.task.recurringPattern,
          );

          if (nextDueDate != null) {
            final nextTask = event.task.copyWith(
              id: _uuid.v4(),
              status: TaskStatus.todo,
              dueDate: nextDueDate,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await repository.addTask(nextTask);

            // GATED: Only schedule for top-level tasks
            if (nextTask.parentId == null && _notificationsEnabled) {
              await notificationService.scheduleTaskReminder(
                taskId: nextTask.id,
                title: nextTask.title,
                dueDate: nextDueDate,
              );
            }
          }
        }
      } else {
        // Reopened - GATED: Only for top-level tasks
        if (event.task.parentId == null &&
            event.task.dueDate != null &&
            _notificationsEnabled) {
          await notificationService.scheduleTaskReminder(
            taskId: event.task.id,
            title: event.task.title,
            dueDate: event.task.dueDate!,
          );
        }
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  DateTime? _calculateNextDueDate(DateTime current, String? pattern) {
    if (pattern == 'daily') return current.add(const Duration(days: 1));
    if (pattern == 'weekly') return current.add(const Duration(days: 7));
    if (pattern == 'monthly') {
      return DateTime(
        current.year,
        current.month + 1,
        current.day,
        current.hour,
        current.minute,
      );
    }
    return null;
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await notificationService.cancelTaskReminder(event.taskId);
      await repository.deleteTask(event.taskId);
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onAddSubtask(AddSubtask event, Emitter<TaskState> emit) async {
    try {
      // GATED: Notifications disabled for subtasks by requirement

      final now = DateTime.now();
      final subtask = TaskEntity(
        id: _uuid.v4(),
        title: event.title,
        parentId: event.parentId,
        createdAt: now,
        updatedAt: now,
        sortOrder: state is TaskLoaded ? (state as TaskLoaded).tasks.length : 0,
      );
      await repository.addTask(subtask);
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  void _onFilterTasks(FilterTasks event, Emitter<TaskState> emit) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final filtered = _applyFilter(
        currentState.tasks,
        event.filter,
        currentState.searchQuery,
      );
      emit(
        TaskLoaded(
          tasks: currentState.tasks,
          filteredTasks: filtered,
          activeFilter: event.filter,
          searchQuery: currentState.searchQuery,
          completedCount: currentState.completedCount,
          totalCount: currentState.totalCount,
        ),
      );
    }
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<TaskState> emit,
  ) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final filtered = _applyFilter(
        currentState.tasks,
        currentState.activeFilter,
        event.query,
      );
      emit(
        TaskLoaded(
          tasks: currentState.tasks,
          filteredTasks: filtered,
          activeFilter: currentState.activeFilter,
          searchQuery: event.query,
          completedCount: currentState.completedCount,
          totalCount: currentState.totalCount,
        ),
      );
    }
  }

  List<TaskEntity> _applyFilter(
    List<TaskEntity> tasks,
    TaskFilter filter,
    String query,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    var filteredTasks = switch (filter) {
      TaskFilter.all => tasks.where((t) => !t.isCompleted).toList(),
      TaskFilter.today =>
        tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.isAfter(
                    todayStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  t.dueDate!.isBefore(todayEnd),
            )
            .toList(),
      TaskFilter.upcoming =>
        tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!)),
      TaskFilter.completed => tasks.where((t) => t.isCompleted).toList(),
    };

    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filteredTasks = filteredTasks.where((t) {
        return t.title.toLowerCase().contains(lowerQuery) ||
            t.description.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return filteredTasks;
  }

  @override
  Future<void> close() {
    _taskSubscription?.cancel();
    return super.close();
  }
}
