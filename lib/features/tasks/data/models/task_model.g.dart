// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-written Hive TypeAdapter for TaskModel.

part of 'task_model.dart';

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      statusIndex: fields[3] as int? ?? 0,
      priorityIndex: fields[4] as int? ?? 0,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      dueDate: fields[7] as DateTime?,
      tags: (fields[8] as List?)?.cast<String>() ?? [],
      parentId: fields[9] as String?,
      isRecurring: fields[10] as bool? ?? false,
      recurringPattern: fields[11] as String?,
      sortOrder: fields[12] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(13) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.statusIndex)
      ..writeByte(4)
      ..write(obj.priorityIndex)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.dueDate)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.parentId)
      ..writeByte(10)
      ..write(obj.isRecurring)
      ..writeByte(11)
      ..write(obj.recurringPattern)
      ..writeByte(12)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
