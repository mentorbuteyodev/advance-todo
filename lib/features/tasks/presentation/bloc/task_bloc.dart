// Task Bloc - Business Logic Component
// Manages all task-related state transitions.

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/notification_service.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;
  final NotificationService notificationService;
  final Uuid _uuid = const Uuid();
  StreamSubscription? _taskSubscription;

  TaskBloc({required this.repository, required this.notificationService})
    : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<ToggleTaskStatus>(_onToggleTaskStatus);
    on<DeleteTask>(_onDeleteTask);
    on<AddSubtask>(_onAddSubtask);
    on<FilterTasks>(_onFilterTasks);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      // Subscribe to the reactive stream
      await _taskSubscription?.cancel();

      await emit.forEach<List<TaskEntity>>(
        repository.watchTasks(),
        onData: (tasks) {
          final currentFilter = state is TaskLoaded
              ? (state as TaskLoaded).activeFilter
              : TaskFilter.all;
          final filtered = _applyFilter(tasks, currentFilter);
          return TaskLoaded(
            tasks: tasks,
            filteredTasks: filtered,
            activeFilter: currentFilter,
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
    try {
      final now = DateTime.now();
      final taskId = _uuid.v4();
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
      );
      await repository.addTask(task);

      // Schedule notification if due date is set
      if (event.dueDate != null) {
        await notificationService.scheduleTaskReminder(
          taskId: taskId,
          title: event.title,
          dueDate: event.dueDate!,
        );
        // Show confirmation notification
        await notificationService.showImmediate(
          title: '✅ Reminder Set',
          body:
              'You\'ll be reminded about "${event.title}" 30 min before it\'s due',
        );
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      await repository.updateTask(
        event.task.copyWith(updatedAt: DateTime.now()),
      );

      // Reschedule notification if due date changed
      if (event.task.dueDate != null) {
        await notificationService.scheduleTaskReminder(
          taskId: event.task.id,
          title: event.task.title,
          dueDate: event.task.dueDate!,
        );
      } else {
        await notificationService.cancelTaskReminder(event.task.id);
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
      final newStatus = event.task.isCompleted
          ? TaskStatus.todo
          : TaskStatus.completed;
      await repository.updateTask(
        event.task.copyWith(status: newStatus, updatedAt: DateTime.now()),
      );

      // Cancel notification when completed, reschedule when reopened
      if (newStatus == TaskStatus.completed) {
        await notificationService.cancelTaskReminder(event.task.id);
      } else if (event.task.dueDate != null) {
        await notificationService.scheduleTaskReminder(
          taskId: event.task.id,
          title: event.task.title,
          dueDate: event.task.dueDate!,
        );
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
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
      final filtered = _applyFilter(currentState.tasks, event.filter);
      emit(
        TaskLoaded(
          tasks: currentState.tasks,
          filteredTasks: filtered,
          activeFilter: event.filter,
          completedCount: currentState.completedCount,
          totalCount: currentState.totalCount,
        ),
      );
    }
  }

  List<TaskEntity> _applyFilter(List<TaskEntity> tasks, TaskFilter filter) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    switch (filter) {
      case TaskFilter.all:
        return tasks.where((t) => !t.isCompleted).toList();
      case TaskFilter.today:
        return tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.isAfter(
                    todayStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  t.dueDate!.isBefore(todayEnd),
            )
            .toList();
      case TaskFilter.upcoming:
        return tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      case TaskFilter.completed:
        return tasks.where((t) => t.isCompleted).toList();
    }
  }

  @override
  Future<void> close() {
    _taskSubscription?.cancel();
    return super.close();
  }
}
