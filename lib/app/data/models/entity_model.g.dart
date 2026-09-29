// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EntityModelAdapter extends TypeAdapter<EntityModel> {
  @override
  final int typeId = 1;

  @override
  EntityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EntityModel(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      name: fields[2] as String,
      description: fields[3] as String?,
      address: fields[4] as String?,
      phoneNumbers: (fields[5] as List).cast<PhoneNumberModel>(),
      openingHours: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      media: (fields[9] as List?)?.cast<MediaModel>(),
      averageRating: fields[10] as double?,
      reviewCount: fields[11] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, EntityModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.phoneNumbers)
      ..writeByte(6)
      ..write(obj.openingHours)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.media)
      ..writeByte(10)
      ..write(obj.averageRating)
      ..writeByte(11)
      ..write(obj.reviewCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
