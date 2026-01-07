// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tamu.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TamuAdapter extends TypeAdapter<Tamu> {
  @override
  final int typeId = 1;

  @override
  Tamu read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tamu(
      nomor: fields[0] as int,
      id: fields[1] as int,
      nama: fields[2] as String,
      keperluan: fields[3] as String,
      instansi: fields[4] as String,
      arrivalTime: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Tamu obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.nomor)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.nama)
      ..writeByte(3)
      ..write(obj.keperluan)
      ..writeByte(4)
      ..write(obj.instansi)
      ..writeByte(5)
      ..write(obj.arrivalTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TamuAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
