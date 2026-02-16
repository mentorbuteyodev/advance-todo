// Task Repository Implementation
// Bridges the Domain layer interface with the Data layer.

import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({required this.localDataSource});

  @override
  Future<List<TaskEntity>> getTasks({String? parentId}) async {
    final models = await localDataSource.getTasks(parentId: parentId);
    final entities = <TaskEntity>[];
    for (final model in models) {
      final subtaskModels = await localDataSource.getTasks(parentId: model.id);
      final subtasks = subtaskModels.map((s) => s.toEntity()).toList();
      entities.add(model.toEntity(subtasks: subtasks));
    }
    entities.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return entities;
  }

  @override
  Future<TaskEntity?> getTaskById(String id) async {
    final model = await localDataSource.getTaskById(id);
    if (model == null) return null;
    final subtaskModels = await localDataSource.getTasks(parentId: id);
    final subtasks = subtaskModels.map((s) => s.toEntity()).toList();
    return model.toEntity(subtasks: subtasks);
  }

  @override
  Future<void> addTask(TaskEntity task) async {
    final model = TaskModel.fromEntity(task);
    await localDataSource.addTask(model);
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final model = TaskModel.fromEntity(task);
    await localDataSource.updateTask(model);
  }

  @override
  Future<void> deleteTask(String id) async {
    await localDataSource.deleteTask(id);
  }

  @override
  Future<List<TaskEntity>> getTasksByStatus(TaskStatus status) async {
    final allTasks = await getTasks();
    return allTasks.where((t) => t.status == status).toList();
  }

  @override
  Future<List<TaskEntity>> getTasksDueToday() async {
    final allTasks = await getTasks();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return allTasks
        .where(
          (t) =>
              t.dueDate != null &&
              t.dueDate!.isAfter(todayStart) &&
              t.dueDate!.isBefore(todayEnd),
        )
        .toList();
  }

  @override
  Future<List<TaskEntity>> getUpcomingTasks() async {
    final allTasks = await getTasks();
    final now = DateTime.now();
    return allTasks
        .where(
          (t) => t.dueDate != null && t.dueDate!.isAfter(now) && !t.isCompleted,
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  @override
  Future<List<TaskEntity>> searchTasks(String query) async {
    final models = await localDataSource.searchTasks(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<TaskEntity>> watchTasks() {
    return localDataSource.watchTasks().asyncMap((models) async {
      final topLevel = models.where((m) => m.parentId == null).toList();
      final entities = <TaskEntity>[];
      for (final model in topLevel) {
        final subtaskModels = models
            .where((m) => m.parentId == model.id)
            .toList();
        final subtasks = subtaskModels.map((s) => s.toEntity()).toList();
        entities.add(model.toEntity(subtasks: subtasks));
      }
      entities.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return entities;
    });
  }
}
