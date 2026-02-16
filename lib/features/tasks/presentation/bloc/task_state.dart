// Task Bloc - States

import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';
import 'task_event.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskEntity> tasks;
  final List<TaskEntity> filteredTasks;
  final TaskFilter activeFilter;
  final int completedCount;
  final int totalCount;

  const TaskLoaded({
    required this.tasks,
    required this.filteredTasks,
    this.activeFilter = TaskFilter.all,
    this.completedCount = 0,
    this.totalCount = 0,
  });

  double get completionRate => totalCount > 0 ? completedCount / totalCount : 0;

  @override
  List<Object?> get props => [
    tasks,
    filteredTasks,
    activeFilter,
    completedCount,
    totalCount,
  ];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
