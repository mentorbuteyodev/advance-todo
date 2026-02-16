// Remote Data Source — syncs tasks with Cloud Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/task_model.dart';

abstract class RemoteTaskDataSource {
  Future<void> saveTask(String uid, TaskModel task);
  Future<void> deleteTask(String uid, String taskId);
  Future<List<TaskModel>> getTasks(String uid);
  Stream<List<TaskModel>> getTasksStream(String uid);
}

class RemoteTaskDataSourceImpl implements RemoteTaskDataSource {
  final FirebaseFirestore _firestore;

  RemoteTaskDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('tasks');
  }

  @override
  Future<void> saveTask(String uid, TaskModel task) async {
    await _tasksCollection(uid).doc(task.id).set(task.toJson());
  }

  @override
  Future<void> deleteTask(String uid, String taskId) async {
    await _tasksCollection(uid).doc(taskId).delete();
  }

  @override
  Future<List<TaskModel>> getTasks(String uid) async {
    final snapshot = await _tasksCollection(uid).get();
    return snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
  }

  @override
  Stream<List<TaskModel>> getTasksStream(String uid) {
    return _tasksCollection(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data()))
          .toList();
    });
  }
}
