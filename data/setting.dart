import 'package:hive/hive.dart';

part 'setting.g.dart';

@HiveType(typeId: 2)
class Setting extends HiveObject {
  @HiveField(0)
  String lokasiExport;

  @HiveField(1)
  String lokasiLog;

  @HiveField(2)
  String lokasiData;

  @HiveField(3)
  String foto1;

  @HiveField(4)
  String foto2;

  @HiveField(5)
  bool tampilkanTotalAntrian;

  @HiveField(6)
  String csvShiftPath;

  @HiveField(7)
  String gambarFolderPath;

  @HiveField(8)
  double delayRotasi;

  @HiveField(9)
  Map<String, List<String?>> jadwal;

  @HiveField(10)
  bool tampilkanCustomFooter;

  @HiveField(11)
  String runningText;

  Setting({
    required this.lokasiExport,
    required this.lokasiLog,
    required this.lokasiData,
    required this.foto1,
    required this.foto2,
    required this.tampilkanTotalAntrian,
    required this.csvShiftPath,
    required this.gambarFolderPath,
    required this.delayRotasi,
    required this.jadwal,
    required this.tampilkanCustomFooter,
    required this.runningText,
  });
}
