import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/remote_task_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;
  final RemoteTaskDataSource remoteDataSource;
  final AuthRepository authRepository;
  StreamSubscription? _remoteSubscription;
  StreamSubscription? _authSubscription;
  bool _isSyncing = false;

  TaskRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.authRepository,
  }) {
    _initAuthListener();
  }

  String? get _currentUid => authRepository.currentUser?.uid;

  // ── Auth Listener ──────────────────────────────────────────
  void _initAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = authRepository.authStateChanges.listen((user) async {
      if (user != null) {
        debugPrint('🔔 User logged in: ${user.uid}. Starting sync...');
        _initRemoteListener();
        // Trigger a sync immediately on login
        await syncNow();
      } else {
        debugPrint(
          '🔕 User logged out. Stopping sync and clearing local data.',
        );
        _remoteSubscription?.cancel();
        _remoteSubscription = null;
        await clearLocalData();
      }
    });
  }

  // ── Remote → Local Listener ──────────────────────────────────
  void _initRemoteListener() {
    final uid = _currentUid;
    if (uid == null) return;

    _remoteSubscription?.cancel();
    _remoteSubscription = remoteDataSource.getTasksStream(uid).listen((
      remoteTasks,
    ) async {
      if (_isSyncing) return; // Skip during active sync to avoid loops
      for (final remoteTask in remoteTasks) {
        final localTask = await localDataSource.getTaskById(remoteTask.id);
        if (localTask == null) {
          // New from remote, add locally
          await localDataSource.addTask(remoteTask);
        } else if (!localTask.pendingSync &&
            remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
          // Remote is newer AND local has no pending changes → update
          await localDataSource.updateTask(remoteTask);
        }
        // If localTask.pendingSync is true, keep local version (will push on next sync)
      }
    }, onError: (e) => debugPrint('⚠️ Remote sync listener error: $e'));
  }

  // ── Full Bidirectional Sync ──────────────────────────────────
  @override
  Future<void> syncNow() async {
    final uid = _currentUid;
    if (uid == null || _isSyncing) return;
    _isSyncing = true;
    debugPrint('🔄 Starting full sync for $uid...');

    try {
      // 1. Push pending local changes to remote
      final pendingTasks = await localDataSource.getPendingSyncTasks();
      for (final task in pendingTasks) {
        try {
          if (task.isDeleted) {
            // Soft-deleted locally → delete from remote and purge
            await remoteDataSource.deleteTask(uid, task.id);
            await localDataSource.purgeTask(task.id);
            debugPrint('🗑️ Synced deletion: ${task.id}');
          } else {
            // Push upsert to remote
            final syncedTask = TaskModel(
              id: task.id,
              title: task.title,
              description: task.description,
              statusIndex: task.statusIndex,
              priorityIndex: task.priorityIndex,
              createdAt: task.createdAt,
              updatedAt: task.updatedAt,
              dueDate: task.dueDate,
              tags: task.tags,
              parentId: task.parentId,
              isRecurring: task.isRecurring,
              recurringPattern: task.recurringPattern,
              sortOrder: task.sortOrder,
              isDeleted: false,
              pendingSync: false,
            );
            await remoteDataSource.saveTask(uid, syncedTask);
            // Clear pending flag locally
            await localDataSource.updateTask(syncedTask);
            debugPrint('⬆️ Pushed: ${task.id}');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to sync ${task.id}: $e');
          // Leave pendingSync = true so it retries next time
        }
      }

      // 2. Pull remote tasks and merge into local
      final remoteTasks = await remoteDataSource.getTasks(uid);
      final localTasks = await localDataSource.getAllTasksRaw();
      final localMap = {for (final t in localTasks) t.id: t};

      for (final remoteTask in remoteTasks) {
        final localTask = localMap[remoteTask.id];
        if (localTask == null) {
          // New from remote
          await localDataSource.addTask(remoteTask);
        } else if (!localTask.pendingSync &&
            remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
          // Remote is newer, local has no pending changes
          await localDataSource.updateTask(remoteTask);
        }
        localMap.remove(remoteTask.id);
      }

      // 3. Remaining in localMap are tasks not on remote
      //    — they were either created offline (pendingSync) or deleted remotely
      for (final orphan in localMap.values) {
        if (!orphan.pendingSync && !orphan.isDeleted) {
          // Not pending and not in remote → was deleted remotely
          await localDataSource.purgeTask(orphan.id);
          debugPrint('🧹 Purged locally (deleted remotely): ${orphan.id}');
        }
      }

      debugPrint('✅ Sync complete');
    } catch (e) {
      debugPrint('❌ Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> clearLocalData() async {
    await localDataSource.clear();
    debugPrint('🧹 Local data cleared');
  }

  void dispose() {
    _remoteSubscription?.cancel();
    _authSubscription?.cancel();
  }

  // ── CRUD Operations ──────────────────────────────────────────

  @override
  Future<List<TaskEntity>> getTasks({String? parentId}) async {
    final models = await localDataSource.getTasks(parentId: parentId);
    return _mapModelsToEntities(models);
  }

  @override
  Future<TaskEntity?> getTaskById(String id) async {
    final model = await localDataSource.getTaskById(id);
    if (model == null) return null;
    return _mapModelToEntity(model);
  }

  @override
  Future<void> addTask(TaskEntity task) async {
    final uid = _currentUid;
    final model = TaskModel.fromEntity(task.copyWith(pendingSync: true));
    await localDataSource.addTask(model);
    if (uid != null) {
      try {
        await remoteDataSource.saveTask(uid, model);
        // Remote succeeded → clear pendingSync flag
        final synced = TaskModel.fromEntity(task.copyWith(pendingSync: false));
        await localDataSource.updateTask(synced);
      } catch (e) {
        debugPrint('⚠️ Remote add failed (queued): $e');
        // Stays pendingSync = true → will push on next syncNow()
      }
    }
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final uid = _currentUid;
    final model = TaskModel.fromEntity(task.copyWith(pendingSync: true));
    await localDataSource.updateTask(model);
    if (uid != null) {
      try {
        await remoteDataSource.saveTask(uid, model);
        final synced = TaskModel.fromEntity(task.copyWith(pendingSync: false));
        await localDataSource.updateTask(synced);
      } catch (e) {
        debugPrint('⚠️ Remote update failed (queued): $e');
      }
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    final uid = _currentUid;
    // Soft delete: mark as deleted + pendingSync
    final existing = await localDataSource.getTaskById(id);
    if (existing != null) {
      final softDeleted = TaskModel(
        id: existing.id,
        title: existing.title,
        description: existing.description,
        statusIndex: existing.statusIndex,
        priorityIndex: existing.priorityIndex,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        dueDate: existing.dueDate,
        tags: existing.tags,
        parentId: existing.parentId,
        isRecurring: existing.isRecurring,
        recurringPattern: existing.recurringPattern,
        sortOrder: existing.sortOrder,
        isDeleted: true,
        pendingSync: true,
      );
      await localDataSource.updateTask(softDeleted);

      // Also soft-delete subtasks
      final subtasks = await localDataSource.getTasks(parentId: id);
      for (final sub in subtasks) {
        await deleteTask(sub.id);
      }
    }

    // Try to delete remotely immediately
    if (uid != null) {
      try {
        await remoteDataSource.deleteTask(uid, id);
        // If remote delete succeeded, purge locally
        await localDataSource.purgeTask(id);
      } catch (e) {
        debugPrint('⚠️ Remote delete failed (queued): $e');
        // Will purge on next syncNow()
      }
    }
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
      return _mapModelsToEntities(models);
    });
  }

  // ── Helper Mapping Methods ──

  Future<List<TaskEntity>> _mapModelsToEntities(List<TaskModel> models) async {
    final topLevel = models.where((m) => m.parentId == null).toList();
    final entities = <TaskEntity>[];

    for (final model in topLevel) {
      entities.add(await _mapModelToEntity(model));
    }

    entities.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return entities;
  }

  Future<TaskEntity> _mapModelToEntity(TaskModel model) async {
    final subtaskModels = await localDataSource.getTasks(parentId: model.id);
    final subtasks = subtaskModels.map((s) => s.toEntity()).toList();
    return model.toEntity(subtasks: subtasks);
  }
}
