// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] == null ? '' : fields[2] as String,
      statusIndex: fields[3] == null ? 0 : (fields[3] as num).toInt(),
      priorityIndex: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      dueDate: fields[7] as DateTime?,
      tags: fields[8] == null ? const [] : (fields[8] as List).cast<String>(),
      parentId: fields[9] as String?,
      isRecurring: fields[10] == null ? false : fields[10] as bool,
      recurringPattern: fields[11] as String?,
      sortOrder: fields[12] == null ? 0 : (fields[12] as num).toInt(),
      isDeleted: fields[13] == null ? false : fields[13] as bool,
      pendingSync: fields[14] == null ? false : fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.sortOrder)
      ..writeByte(13)
      ..write(obj.isDeleted)
      ..writeByte(14)
      ..write(obj.pendingSync);
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
