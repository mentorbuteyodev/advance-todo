// Remote Data Source — syncs tasks with Cloud Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/task_model.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

abstract class RemoteTaskDataSource {
  Future<void> saveTask(TaskModel task);
  Future<void> deleteTask(String taskId);
  Future<List<TaskModel>> getTasks();
  Stream<List<TaskModel>> getTasksStream();
}

class RemoteTaskDataSourceImpl implements RemoteTaskDataSource {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  RemoteTaskDataSourceImpl({
    FirebaseFirestore? firestore,
    required AuthRepository authRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _authRepository = authRepository;

  String? get _userId => _authRepository.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _tasksCollection {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('tasks');
  }

  @override
  Future<void> saveTask(TaskModel task) async {
    final collection = _tasksCollection;
    if (collection == null) return;

    await collection.doc(task.id).set(task.toJson());
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final collection = _tasksCollection;
    if (collection == null) return;

    await collection.doc(taskId).delete();
  }

  @override
  Future<List<TaskModel>> getTasks() async {
    final collection = _tasksCollection;
    if (collection == null) return [];

    final snapshot = await collection.get();
    return snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
  }

  @override
  Stream<List<TaskModel>> getTasksStream() {
    // Note: We need to handle the case where userId changes or is null
    // This simple implementation assumes the user is logged in when this is called
    // A more robust solution would listen to auth state changes
    final collection = _tasksCollection;
    if (collection == null) return Stream.value([]);

    return collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data()))
          .toList();
    });
  }
}
