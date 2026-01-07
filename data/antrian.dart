import 'package:hive/hive.dart';

part 'antrian.g.dart';

@HiveType(typeId: 0)
class Antrian extends HiveObject {
  @HiveField(0)
  final int nomorAntrian;

  @HiveField(1)
  final DateTime entryTime;

  @HiveField(2)
  final int tamuId;

  @HiveField(3)
  final bool isSelesai;

  Antrian({
    required this.nomorAntrian,
    required this.entryTime,
    required this.tamuId,
    this.isSelesai = false,
  });
}