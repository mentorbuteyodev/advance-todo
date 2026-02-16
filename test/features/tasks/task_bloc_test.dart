// Unit tests for TaskBloc
// Tests all events and state transitions.

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todo_test/core/services/notification_service.dart';
import 'package:todo_test/features/tasks/domain/entities/task_entity.dart';
import 'package:todo_test/features/tasks/domain/repositories/task_repository.dart';
import 'package:todo_test/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:todo_test/features/tasks/presentation/bloc/task_event.dart';
import 'package:todo_test/features/tasks/presentation/bloc/task_state.dart';

// Mocks
class MockTaskRepository extends Mock implements TaskRepository {}

class MockNotificationService extends Mock implements NotificationService {}

class FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late MockTaskRepository mockRepo;
  late MockNotificationService mockNotifications;
  late TaskBloc taskBloc;

  final tTask = TaskEntity(
    id: 'test-1',
    title: 'Test Task',
    description: 'A test task',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    priority: TaskPriority.medium,
  );

  setUpAll(() {
    registerFallbackValue(FakeTaskEntity());
  });

  setUp(() {
    mockRepo = MockTaskRepository();
    mockNotifications = MockNotificationService();
    taskBloc = TaskBloc(
      repository: mockRepo,
      notificationService: mockNotifications,
    );

    // Default stub for notification methods
    when(
      () => mockNotifications.scheduleTaskReminder(
        taskId: any(named: 'taskId'),
        title: any(named: 'title'),
        dueDate: any(named: 'dueDate'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotifications.cancelTaskReminder(any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    taskBloc.close();
  });

  group('TaskBloc', () {
    test('initial state is TaskInitial', () {
      expect(taskBloc.state, isA<TaskInitial>());
    });

    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoaded] when LoadTasks is added and tasks are returned',
      build: () {
        when(
          () => mockRepo.watchTasks(),
        ).thenAnswer((_) => Stream.value([tTask]));
        return TaskBloc(
          repository: mockRepo,
          notificationService: mockNotifications,
        );
      },
      act: (bloc) => bloc.add(LoadTasks()),
      expect: () => [isA<TaskLoading>(), isA<TaskLoaded>()],
      verify: (_) {
        verify(() => mockRepo.watchTasks()).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoaded] with empty list when no tasks exist',
      build: () {
        when(() => mockRepo.watchTasks()).thenAnswer((_) => Stream.value([]));
        return TaskBloc(
          repository: mockRepo,
          notificationService: mockNotifications,
        );
      },
      act: (bloc) => bloc.add(LoadTasks()),
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskLoaded>().having((s) => s.tasks.length, 'tasks count', 0),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'calls repository.addTask when AddTask event is added',
      build: () {
        when(() => mockRepo.addTask(any())).thenAnswer((_) async {});
        when(
          () => mockRepo.watchTasks(),
        ).thenAnswer((_) => Stream.value([tTask]));
        return TaskBloc(
          repository: mockRepo,
          notificationService: mockNotifications,
        );
      },
      seed: () => TaskLoaded(
        tasks: [tTask],
        filteredTasks: [tTask],
        completedCount: 0,
        totalCount: 1,
      ),
      act: (bloc) => bloc.add(const AddTask(title: 'New Task')),
      verify: (_) {
        verify(() => mockRepo.addTask(any())).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'calls repository.deleteTask when DeleteTask event is added',
      build: () {
        when(() => mockRepo.deleteTask(any())).thenAnswer((_) async {});
        when(
          () => mockRepo.watchTasks(),
        ).thenAnswer((_) => Stream.value([tTask]));
        return TaskBloc(
          repository: mockRepo,
          notificationService: mockNotifications,
        );
      },
      seed: () => TaskLoaded(
        tasks: [tTask],
        filteredTasks: [tTask],
        completedCount: 0,
        totalCount: 1,
      ),
      act: (bloc) => bloc.add(const DeleteTask('test-1')),
      verify: (_) {
        verify(() => mockRepo.deleteTask('test-1')).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'calls repository.updateTask when ToggleTaskStatus is added',
      build: () {
        when(() => mockRepo.updateTask(any())).thenAnswer((_) async {});
        when(
          () => mockRepo.watchTasks(),
        ).thenAnswer((_) => Stream.value([tTask]));
        return TaskBloc(
          repository: mockRepo,
          notificationService: mockNotifications,
        );
      },
      seed: () => TaskLoaded(
        tasks: [tTask],
        filteredTasks: [tTask],
        completedCount: 0,
        totalCount: 1,
      ),
      act: (bloc) => bloc.add(ToggleTaskStatus(tTask)),
      verify: (_) {
        verify(() => mockRepo.updateTask(any())).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoaded] with filtered tasks when FilterTasks is added',
      build: () {
        when(
          () => mockRepo.watchTasks(),
        ).thenAnswer((_) => Stream.value([tTask]));
        return TaskBloc(
          repository: mockRepo,
          notificationService: mockNotifications,
        );
      },
      seed: () => TaskLoaded(
        tasks: [tTask],
        filteredTasks: [tTask],
        completedCount: 0,
        totalCount: 1,
      ),
      act: (bloc) => bloc.add(const FilterTasks(TaskFilter.completed)),
      expect: () => [
        isA<TaskLoaded>()
            .having((s) => s.activeFilter, 'filter', TaskFilter.completed)
            .having((s) => s.filteredTasks.length, 'filtered', 0),
      ],
    );
  });

  group('TaskEntity', () {
    test('copyWith creates a new instance with updated fields', () {
      final updated = tTask.copyWith(title: 'Updated Title');
      expect(updated.title, 'Updated Title');
      expect(updated.id, tTask.id);
      expect(updated.description, tTask.description);
    });

    test('isCompleted returns true when status is completed', () {
      final completed = tTask.copyWith(status: TaskStatus.completed);
      expect(completed.isCompleted, true);
    });

    test('isOverdue returns true for past due date on incomplete task', () {
      final overdue = tTask.copyWith(
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: TaskStatus.todo,
      );
      expect(overdue.isOverdue, true);
    });

    test('isOverdue returns false for completed task', () {
      final completed = tTask.copyWith(
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: TaskStatus.completed,
      );
      expect(completed.isOverdue, false);
    });
  });
}
