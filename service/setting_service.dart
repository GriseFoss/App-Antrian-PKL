// lib/service/setting_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/setting.dart';
import 'file_helper.dart';

class SettingService {
  static const String _boxName = 'settingBox';
  static const String _settingKey = 'appSetting';
  static late Box<Setting> _settingBox;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(SettingAdapter().typeId)) {
      Hive.registerAdapter(SettingAdapter());
    }

    if (!Hive.isBoxOpen(_boxName)) {
      _settingBox = await Hive.openBox<Setting>(_boxName);
    } else {
      _settingBox = Hive.box<Setting>(_boxName);
    }

    // Jika belum ada setting, buat default
    if (_settingBox.isEmpty) {
      final paths = await FileHelper.buatFolderDefault();

      final defaultSetting = Setting(
        lokasiExport: paths['export'] ?? '',
        lokasiLog: paths['log'] ?? '',
        lokasiData: paths ['base'] ?? '',
        foto1: paths['gambar1'] ?? '',
        foto2: paths['gambar2'] ?? '',
        csvShiftPath: paths['csv'] ?? '',
        gambarFolderPath: '',
        tampilkanTotalAntrian: false,
        delayRotasi: 5.0,
        jadwal: {
          'Senin': [null, null, null],
          'Selasa': [null, null, null],
          'Rabu': [null, null, null],
          'Kamis': [null, null, null],
          'Jumat': [null, null, null],
          'Sabtu': [null, null, null],
          'Minggu': [null, null, null],
        },
        tampilkanCustomFooter: true,
        runningText:
        'Selamat Datang di BPS Metro | Data akurat untuk Indonesia Maju | Jam Pelayanan Sen-Kamis: 08.00–15.30, Jumat: 08.00–16.00 | Hubungi kami di (62-725)41758 | bps1872@bps.go.id | @bpskotametro |',
      );

      await _settingBox.put(_settingKey, defaultSetting);
    }
  }

  static Setting getSetting() =>
      _settingBox.get(_settingKey) ??
          (throw Exception('❌ Setting belum diinisialisasi'));

  static Future<void> saveSetting(Setting setting) async {
    await _settingBox.put(_settingKey, setting);
  }

  static ValueListenable<Box<Setting>> get settingListenable =>
      _settingBox.listenable(keys: [_settingKey]);

  static String getLokasiData() => getSetting().lokasiData;
  static String getLokasiExport() => getSetting().lokasiExport;
  static double getDelayRotasi() => getSetting().delayRotasi;
}
