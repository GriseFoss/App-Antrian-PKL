import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import '../data/tamu.dart';
import 'hive_service.dart';

class ImportService {
  static Future<void> importTamuFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (result == null || result.files.single.path == null) {
        debugPrint('❌ Import dibatalkan.');
        return;
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);

      if (filePath.endsWith('.xlsx')) {
        await _importFromExcel(file);
      } else if (filePath.endsWith('.csv')) {
        await _importFromCsv(file);
      } else {
        debugPrint('⚠️ Format file tidak didukung.');
      }

      debugPrint('✅ Import selesai dari: $filePath');
    } catch (e) {
      debugPrint('❌ Gagal mengimpor data: $e');
    }
  }

  static Future<void> _importFromExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.length < 6) continue;

      try {
        final id = int.tryParse(row[1]?.value.toString() ?? '') ?? 0;
        final nama = row[2]?.value.toString() ?? '-';
        final instansi = row[3]?.value.toString() ?? '-';
        final keperluan = row[4]?.value.toString() ?? '-';
        final waktuStr = row[5]?.value.toString() ?? '';

        final arrivalTime = DateFormat('dd-MM-yyyy HH:mm:ss').parse(waktuStr);

        final tamu = Tamu(
          nomor: i,
          id: id,
          nama: nama,
          instansi: instansi,
          keperluan: keperluan,
          arrivalTime: arrivalTime,
        );

        await HiveService.saveTamu(tamu);
      } catch (e) {
        debugPrint('⚠️ Gagal memproses baris $i: $e');
      }
    }
  }

  static Future<void> _importFromCsv(File file) async {
    final csvStr = await file.readAsString();
    final rows = const CsvToListConverter().convert(csvStr);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 6) continue;

      try {
        final id = int.tryParse(row[1].toString()) ?? 0;
        final nama = row[2].toString();
        final instansi = row[3].toString();
        final keperluan = row[4].toString();
        final waktuStr = row[5].toString();

        final arrivalTime = DateFormat('dd-MM-yyyy HH:mm:ss').parse(waktuStr);

        final tamu = Tamu(
          nomor: i,
          id: id,
          nama: nama,
          instansi: instansi,
          keperluan: keperluan,
          arrivalTime: arrivalTime,
        );

        await HiveService.saveTamu(tamu);
      } catch (e) {
        debugPrint('⚠️ Gagal memproses baris $i: $e');
      }
    }
  }
}
