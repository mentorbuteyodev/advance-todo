// Task Model - Data layer representation of a Task.
// Handles serialization/deserialization for Hive storage.

import 'package:hive_ce/hive.dart';
import '../../domain/entities/task_entity.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int statusIndex; // Maps to TaskStatus enum

  @HiveField(4)
  final int priorityIndex; // Maps to TaskPriority enum

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final DateTime? dueDate;

  @HiveField(8)
  final List<String> tags;

  @HiveField(9)
  final String? parentId;

  @HiveField(10)
  final bool isRecurring;

  @HiveField(11)
  final String? recurringPattern;

  @HiveField(12)
  final int sortOrder;

  @HiveField(13)
  final bool isDeleted;

  @HiveField(14)
  final bool pendingSync;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.statusIndex = 0,
    this.priorityIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.tags = const [],
    this.parentId,
    this.isRecurring = false,
    this.recurringPattern,
    this.sortOrder = 0,
    this.isDeleted = false,
    this.pendingSync = false,
  });

  /// Convert from Domain Entity to Data Model.
  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      statusIndex: entity.status.index,
      priorityIndex: entity.priority.index,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      dueDate: entity.dueDate,
      tags: List<String>.from(entity.tags),
      parentId: entity.parentId,
      isRecurring: entity.isRecurring,
      recurringPattern: entity.recurringPattern,
      sortOrder: entity.sortOrder,
      isDeleted: entity.isDeleted,
      pendingSync: entity.pendingSync,
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    int? statusIndex,
    int? priorityIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    List<String>? tags,
    String? parentId,
    bool? isRecurring,
    String? recurringPattern,
    int? sortOrder,
    bool? isDeleted,
    bool? pendingSync,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      statusIndex: statusIndex ?? this.statusIndex,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      parentId: parentId ?? this.parentId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      sortOrder: sortOrder ?? this.sortOrder,
      isDeleted: isDeleted ?? this.isDeleted,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  /// Convert from Data Model to Domain Entity.
  TaskEntity toEntity({List<TaskEntity> subtasks = const []}) {
    return TaskEntity(
      id: id,
      title: title,
      description: description,
      status: TaskStatus.values[statusIndex],
      priority: TaskPriority.values[priorityIndex],
      createdAt: createdAt,
      updatedAt: updatedAt,
      dueDate: dueDate,
      tags: List<String>.from(tags),
      subtasks: subtasks,
      parentId: parentId,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
      sortOrder: sortOrder,
      isDeleted: isDeleted,
      pendingSync: pendingSync,
    );
  }

  // ── JSON Serialization ──
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'statusIndex': statusIndex,
      'priorityIndex': priorityIndex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'tags': tags,
      'parentId': parentId,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'sortOrder': sortOrder,
      'isDeleted': isDeleted,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      statusIndex: json['statusIndex'] as int? ?? 0,
      priorityIndex: json['priorityIndex'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      tags: List<String>.from(json['tags'] as List? ?? []),
      parentId: json['parentId'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringPattern: json['recurringPattern'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      pendingSync: false, // Remote data is already synced
    );
  }
}
