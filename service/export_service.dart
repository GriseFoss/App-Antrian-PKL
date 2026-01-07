import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../data/tamu.dart';
import 'setting_service.dart';

class ExportService {
  static Future<void> exportTamuToExcel(
      List<Tamu> tamuList,
      int month,
      int year,
      DateTime? startDate,
      DateTime? endDate,
      )async {
    final excel = Excel.createExcel();
    const sheetTitle = 'Laporan Tamu';

    excel.rename('Sheet1', sheetTitle);
    final Sheet sheet = excel[sheetTitle];
    sheet.appendRow([
      TextCellValue('No.'),
      TextCellValue('ID'),
      TextCellValue('Nama'),
      TextCellValue('Instansi'),
      TextCellValue('Keperluan'),
      TextCellValue('Waktu Kedatangan'),
    ]);

    for (int i = 0; i < tamuList.length; i++) {
      final tamu = tamuList[i];
      final formattedTime = DateFormat('dd-MM-yyyy HH:mm:ss').format(tamu.arrivalTime);

      sheet.appendRow([
        IntCellValue(i + 1),
        IntCellValue(tamu.id),
        TextCellValue(tamu.nama),
        TextCellValue(tamu.instansi),
        TextCellValue(tamu.keperluan),
        TextCellValue(formattedTime),
      ]);
    }

    for (var i = 0; i < 6; i++) {
      sheet.setColumnAutoFit(i);
    }

    try {
      final List<int>? excelBytes = excel.save();
      if (excelBytes == null) return;

      String fileName;
      if (startDate != null && endDate != null) {
        final startStr = DateFormat('dd-MM').format(startDate);
        final endStr = DateFormat('dd-MM-yyyy').format(endDate);
        fileName = 'Laporan_Tamu_${startStr}_sampai_${endStr}.xlsx';
      } else {
        fileName = 'Laporan_Tamu_${month}_$year.xlsx';
      }

      // ambil lokasi export custom, jika kosong gunakan default
      String lokasiExport = SettingService.getLokasiExport();

      Directory? targetDir;
      if (lokasiExport.isNotEmpty && await Directory(lokasiExport).exists()) {
        targetDir = Directory(lokasiExport);
      } else {
        if (Platform.isAndroid) {
          targetDir = await getExternalStorageDirectory(); // Android default
        } else if (Platform.isWindows || Platform.isMacOS) {
          targetDir = await getDownloadsDirectory();
        } else {
          targetDir = await getApplicationDocumentsDirectory();
        }
      }

      final filePath = '${targetDir!.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(excelBytes);

      debugPrint('✅ File berhasil disimpan di: $filePath');
    } catch (e) {
      debugPrint('❌ Gagal menyimpan file Excel: $e');
      rethrow;
    }
  }
}
