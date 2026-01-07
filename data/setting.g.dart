// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingAdapter extends TypeAdapter<Setting> {
  @override
  final int typeId = 2;

  @override
  Setting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Setting(
      lokasiExport: fields[0] as String,
      lokasiLog: fields[1] as String,
      lokasiData: fields[2] as String,
      foto1: fields[3] as String,
      foto2: fields[4] as String,
      tampilkanTotalAntrian: fields[5] as bool,
      csvShiftPath: fields[6] as String,
      gambarFolderPath: fields[7] as String,
      delayRotasi: fields[8] as double,
      jadwal: (fields[9] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String?>())),
      tampilkanCustomFooter: fields[10] as bool,
      runningText: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Setting obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.lokasiExport)
      ..writeByte(1)
      ..write(obj.lokasiLog)
      ..writeByte(2)
      ..write(obj.lokasiData)
      ..writeByte(3)
      ..write(obj.foto1)
      ..writeByte(4)
      ..write(obj.foto2)
      ..writeByte(5)
      ..write(obj.tampilkanTotalAntrian)
      ..writeByte(6)
      ..write(obj.csvShiftPath)
      ..writeByte(7)
      ..write(obj.gambarFolderPath)
      ..writeByte(8)
      ..write(obj.delayRotasi)
      ..writeByte(9)
      ..write(obj.jadwal)
      ..writeByte(10)
      ..write(obj.tampilkanCustomFooter)
      ..writeByte(11)
      ..write(obj.runningText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
