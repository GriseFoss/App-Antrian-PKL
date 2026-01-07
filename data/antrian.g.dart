// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'antrian.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AntrianAdapter extends TypeAdapter<Antrian> {
  @override
  final int typeId = 0;

  @override
  Antrian read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Antrian(
      nomorAntrian: fields[0] as int,
      entryTime: fields[1] as DateTime,
      tamuId: fields[2] as int,
      isSelesai: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Antrian obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.nomorAntrian)
      ..writeByte(1)
      ..write(obj.entryTime)
      ..writeByte(2)
      ..write(obj.tamuId)
      ..writeByte(3)
      ..write(obj.isSelesai);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AntrianAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
