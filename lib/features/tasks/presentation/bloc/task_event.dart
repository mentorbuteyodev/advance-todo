// Task Bloc - Events

import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class AddTask extends TaskEvent {
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final List<String> tags;
  final String? parentId;

  const AddTask({
    required this.title,
    this.description = '',
    this.priority = TaskPriority.none,
    this.dueDate,
    this.tags = const [],
    this.parentId,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    priority,
    dueDate,
    tags,
    parentId,
  ];
}

class UpdateTask extends TaskEvent {
  final TaskEntity task;

  const UpdateTask(this.task);

  @override
  List<Object?> get props => [task];
}

class ToggleTaskStatus extends TaskEvent {
  final TaskEntity task;

  const ToggleTaskStatus(this.task);

  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TaskEvent {
  final String taskId;

  const DeleteTask(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class AddSubtask extends TaskEvent {
  final String parentId;
  final String title;

  const AddSubtask({required this.parentId, required this.title});

  @override
  List<Object?> get props => [parentId, title];
}

class FilterTasks extends TaskEvent {
  final TaskFilter filter;

  const FilterTasks(this.filter);

  @override
  List<Object?> get props => [filter];
}

enum TaskFilter { all, today, upcoming, completed }
