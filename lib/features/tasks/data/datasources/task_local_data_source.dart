// Task Local Data Source
// Handles all local database operations using Hive.

import 'dart:async';
import 'package:hive_ce/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getTasks({String? parentId});
  Future<TaskModel?> getTaskById(String id);
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<List<TaskModel>> searchTasks(String query);
  Stream<List<TaskModel>> watchTasks();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Box<TaskModel> _taskBox;
  final StreamController<List<TaskModel>> _taskStreamController =
      StreamController<List<TaskModel>>.broadcast();

  TaskLocalDataSourceImpl(this._taskBox);

  void _emitTasks() {
    _taskStreamController.add(_taskBox.values.toList());
  }

  @override
  Future<List<TaskModel>> getTasks({String? parentId}) async {
    final tasks = _taskBox.values.toList();
    if (parentId != null) {
      return tasks.where((t) => t.parentId == parentId).toList();
    }
    // Return only top-level tasks (no parent)
    return tasks.where((t) => t.parentId == null).toList();
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    try {
      return _taskBox.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addTask(TaskModel task) async {
    await _taskBox.put(task.id, task);
    _emitTasks();
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await _taskBox.put(task.id, task);
    _emitTasks();
  }

  @override
  Future<void> deleteTask(String id) async {
    // Also delete subtasks
    final subtasks = _taskBox.values.where((t) => t.parentId == id).toList();
    for (final subtask in subtasks) {
      await deleteTask(subtask.id);
    }
    await _taskBox.delete(id);
    _emitTasks();
  }

  @override
  Future<List<TaskModel>> searchTasks(String query) async {
    final lowerQuery = query.toLowerCase();
    return _taskBox.values
        .where(
          (t) =>
              t.title.toLowerCase().contains(lowerQuery) ||
              t.description.toLowerCase().contains(lowerQuery) ||
              t.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)),
        )
        .toList();
  }

  @override
  Stream<List<TaskModel>> watchTasks() {
    // Emit current state immediately
    Future.microtask(_emitTasks);
    return _taskStreamController.stream;
  }

  static Future<Box<TaskModel>> openBox() async {
    return await Hive.openBox<TaskModel>(AppConstants.taskBoxName);
  }
}
