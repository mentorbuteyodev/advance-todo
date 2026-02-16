// Task Repository Interface
// Defines the contract for data operations on tasks. Domain layer only
// knows this interface, not the implementation.

import '../entities/task_entity.dart';

abstract class TaskRepository {
  /// Get all tasks, optionally filtered by parent ID.
  Future<List<TaskEntity>> getTasks({String? parentId});

  /// Get a single task by ID.
  Future<TaskEntity?> getTaskById(String id);

  /// Add a new task.
  Future<void> addTask(TaskEntity task);

  /// Update an existing task.
  Future<void> updateTask(TaskEntity task);

  /// Delete a task by ID.
  Future<void> deleteTask(String id);

  /// Get tasks filtered by status.
  Future<List<TaskEntity>> getTasksByStatus(TaskStatus status);

  /// Get tasks due today.
  Future<List<TaskEntity>> getTasksDueToday();

  /// Get upcoming tasks (due in the future).
  Future<List<TaskEntity>> getUpcomingTasks();

  /// Search tasks by query string.
  Future<List<TaskEntity>> searchTasks(String query);

  /// Watch all tasks (reactive stream).
  Stream<List<TaskEntity>> watchTasks();

  /// Trigger a full bidirectional sync with remote.
  Future<void> syncNow();
}
