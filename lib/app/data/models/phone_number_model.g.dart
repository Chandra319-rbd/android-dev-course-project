// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_number_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PhoneNumberModelAdapter extends TypeAdapter<PhoneNumberModel> {
  @override
  final int typeId = 5;

  @override
  PhoneNumberModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhoneNumberModel(
      label: fields[0] as String,
      number: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PhoneNumberModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.number);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneNumberModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
