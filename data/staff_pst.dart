import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class StaffPst extends HiveObject {
  @HiveField(0)
  final DateTime tanggal;

  @HiveField(1)
  final int shift;

  @HiveField(2)
  final String namaStaff;

  @HiveField(3)
  final String pathFoto;

  StaffPst({
    required this.tanggal,
    required this.shift,
    required this.namaStaff,
    required this.pathFoto,
  });
}