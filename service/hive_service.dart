import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../data/setting.dart';
import '../data/tamu.dart';
import '../data/antrian.dart';

class HiveService {
  static const String tamuBoxName = 'TamuBox';
  static const String antrianBoxName = 'antrianBox';
  static const String settingBoxName = 'settingBox';

  static String? getTamuNameByAntrianNumber(int tamuId) {
    final box = Hive.box<Tamu>(tamuBoxName);
    if (box.isEmpty) {
      debugPrint("⚠️ Box tamu kosong");
      return null;
    }

    debugPrint("🔍 Mencari tamuId: $tamuId");
    for (var t in box.values) {
      debugPrint("Cek tamu: id=${t.id}, nama=${t.nama}");
    }

    final tamu = box.values.firstWhere(
            (t) => t.id == tamuId,
        orElse: () {
          debugPrint("❌ Tamu dengan id=$tamuId tidak ditemukan.");
          return Tamu(
            nomor: 0,
            id: -1,
            nama: "",
            keperluan: "",
            instansi: "",
            arrivalTime: DateTime.now(),
          );
        }
    );

    return tamu.id == -1 ? null : tamu.nama;
  }

  //inisialisasi hive
  static Future<void> init({String? customPath}) async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    final Directory dataDir = Directory('${baseDir.path}/data');

    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    final hivePath = customPath ?? dataDir.path;
    Hive.init(hivePath);

    if (!Hive.isAdapterRegistered(TamuAdapter().typeId)) {
      Hive.registerAdapter(TamuAdapter());
    }
    if (!Hive.isAdapterRegistered(AntrianAdapter().typeId)) {
      Hive.registerAdapter(AntrianAdapter());
    }
    if (!Hive.isAdapterRegistered(SettingAdapter().typeId)) {
      Hive.registerAdapter(SettingAdapter());
    }

    await Hive.openBox<Tamu>(tamuBoxName);
    await Hive.openBox<Antrian>(antrianBoxName);
    await Hive.openBox<Setting>(settingBoxName);
  }
  //====================
  //Tamu
  //get tamu
  static Box<Tamu> getTamuBox() => Hive.box<Tamu>(tamuBoxName);

  //write tamu
  static Future<void> saveTamu(Tamu tamu) async {
    final box = Hive.box<Tamu>(tamuBoxName);
    await box.add(tamu); // auto assign index key
  }

  //get all tamu
  static List<Tamu> getAllTamu() {
    final box = Hive.box<Tamu>(tamuBoxName);
    return box.values.toList();
  }

  //hapus tamu berdasarkan key
  static Future<void> deleteTamu (dynamic key) async {
    final box = Hive.box<Tamu>(tamuBoxName);
    await box.delete(key);
  }

  //hapus semua tamu
  static Future<void> clearAll() async {
    final box = Hive.box<Tamu>(tamuBoxName);
    await box.clear();
  }
  //======================
  // Antrian

  //get tamu
  static Box<Antrian> getAntrianBox() => Hive.box<Antrian>(antrianBoxName);

  // ctrl + alt + del hapus semua antrian
  static Future<void> clearAllAntrian() async {
    final box = Hive.box<Antrian>(antrianBoxName);
    await box.clear();
  }

  //delete antrian
  static Future<void> deleteAntrian(dynamic key) async{
    final box = Hive.box<Antrian>(antrianBoxName);
    return box.delete(key);
  }

  //======================
  // Tabel
  // log bulannan
  static List<Tamu> getMonthlyReport(int year, int month) {
    final box = getTamuBox();
    final List<Tamu> allTamu = box.values.toList();

    // Filter tamu yang bulan dan tahunnya cocok
    final List<Tamu> monthlyTamu = allTamu.where((tamu) {
      return
        tamu.arrivalTime.year == year &&
            tamu.arrivalTime.month == month;
    }).toList();

    // Urutkan berdasarkan waktu kedatangan
    monthlyTamu.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));

    return monthlyTamu;
  }
  //====================
  //setting
  //bagian setting dipisah
}