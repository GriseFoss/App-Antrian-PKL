import 'dart:async';
import 'dart:io';
import 'package:app_antrian/service/setting_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

File? _logFile;
IOSink? _logSink;

class LogToFile {
  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      final setting = SettingService.getSetting();
      final logDir = Directory(setting.lokasiLog);

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final logFileName = 'app_log_${DateTime.now().toIso8601String().substring(0, 10)}.txt';
      _logFile = File('${logDir.path}/$logFileName');
      _logSink = _logFile!.openWrite(mode: FileMode.append);
      debugPrint = (String? message, {int? wrapWidth}) => _logPrint(message ?? '');

      _logSink!.writeln('--- Log Aplikasi Dimulai: ${DateTime.now()} ---');
      debugPrint('✅ File Logging diaktifkan. Log tersimpan di: ${_logFile!.path}');

    } catch (e) {
      debugPrint('❌ Gagal menginisialisasi file logging: $e');
      debugPrint = debugPrintThrottled;
    }
  }

  static void _logPrint(String message) {
    debugPrintThrottled(message);

    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    _logSink?.writeln('[$timestamp] $message');
  }

  static Future<void> close() async {
    await _logSink?.close();
  }

  static String? get logFilePath => _logFile?.path;
}