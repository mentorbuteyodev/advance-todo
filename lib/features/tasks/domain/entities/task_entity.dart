// Task Entity - Pure domain object representing a single task.
// This is the core business object, independent of any framework.

import 'package:equatable/equatable.dart';

enum TaskPriority { none, low, medium, high, urgent }

enum TaskStatus { todo, inProgress, completed }

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final List<String> tags;
  final List<TaskEntity> subtasks;
  final String? parentId;
  final bool isRecurring;
  final String? recurringPattern; // e.g., 'daily', 'weekly', 'monthly'
  final int sortOrder;
  final bool isDeleted;
  final bool pendingSync;

  const TaskEntity({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.none,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.tags = const [],
    this.subtasks = const [],
    this.parentId,
    this.isRecurring = false,
    this.recurringPattern,
    this.sortOrder = 0,
    this.isDeleted = false,
    this.pendingSync = false,
  });

  bool get isCompleted => status == TaskStatus.completed;

  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    List<String>? tags,
    List<TaskEntity>? subtasks,
    String? parentId,
    bool? isRecurring,
    String? recurringPattern,
    int? sortOrder,
    bool? isDeleted,
    bool? pendingSync,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      parentId: parentId ?? this.parentId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      sortOrder: sortOrder ?? this.sortOrder,
      isDeleted: isDeleted ?? this.isDeleted,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    status,
    priority,
    createdAt,
    updatedAt,
    dueDate,
    tags,
    subtasks,
    parentId,
    isRecurring,
    recurringPattern,
    sortOrder,
    isDeleted,
    pendingSync,
  ];
}
