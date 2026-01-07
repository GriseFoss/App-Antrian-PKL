import 'package:hive/hive.dart';

part 'tamu.g.dart';

@HiveType(typeId: 1)
class Tamu extends HiveObject {
  @HiveField(0)
  int nomor;

  @HiveField(1)
  int id;

  @HiveField(2)
  String nama;

  @HiveField(3)
  String keperluan;

  @HiveField(4)
  String instansi;

  @HiveField(5)
  DateTime arrivalTime;

  Tamu({
    required this.nomor,
    required this.id,
    required this.nama,
    required this.keperluan,
    required this.instansi,
    required this.arrivalTime,
  });
}
