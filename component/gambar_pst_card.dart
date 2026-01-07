import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'dart:async';
import '../service/setting_service.dart';

class StaffPstCard extends StatefulWidget {
  const StaffPstCard({super.key});

  @override
  State<StaffPstCard> createState() => _StaffPstCardState();
}

class _StaffPstCardState extends State<StaffPstCard> {
  String? _pathFotoAktif;
  String? _namaStaffAktif;
  String? _namaStaffBerikutnya;
  bool _loading = true;
  String? _errorMessage;

  //refresh otomatis
  Timer? _shiftCheckTimer;
  int? _shiftAktifSaatIni; // Menggunakan nama yang konsisten

  @override
  void initState() {
    super.initState();
    _muatStaffAktif();
    _mulaiTimerCekShift();
  }

  @override
  void dispose() {
    _shiftCheckTimer?.cancel();
    super.dispose();
  }

  // Metode untuk memulai timer
  void _mulaiTimerCekShift() {
    _shiftCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_loading) {
        debugPrint('DEBUG TIMER: Skip cek shift, masih loading...');
        return;
      }

      // 🏆 PERBAIKAN: Gunakan DateTime.now() untuk penentuan shift
      final now = DateTime.now();
      final setting = SettingService.getSetting();
      final shiftBaru = _tentukanShift(now, setting.jadwal); // Passing DateTime

      debugPrint('DEBUG TIMER: Cek shift...');
      debugPrint('DEBUG TIMER: Shift Aktif Saat Ini: $_shiftAktifSaatIni, Shift Baru: $shiftBaru');

      if (_shiftAktifSaatIni != null && _shiftAktifSaatIni != shiftBaru) {
        debugPrint('DEBUG TIMER: PERUBAHAN SHIFT TERDETEKSI. Memuat ulang staff...');
        _muatStaffAktif();
      }
    });
  }

  Future<void> _muatStaffAktif() async {
    setState(() {
      _errorMessage = null;
      _loading = true;
      _namaStaffBerikutnya = null;
    });

    try {
      final setting = SettingService.getSetting();
      final filePath = setting.csvShiftPath;
      final folderFoto = setting.foto1;

      debugPrint('--- DEBUG STAFF PST CARD ---');
      debugPrint('Path File Shift: $filePath');
      debugPrint('Path Folder Foto: $folderFoto');

      if (filePath.isEmpty || !File(filePath).existsSync()) {
        setState(() {
          _errorMessage = filePath.isEmpty ? 'Path file kosong.' : 'File Shift tidak ditemukan.';
          _loading = false;
          _shiftAktifSaatIni = null; // Reset shift aktif jika file tidak ada
        });
        return;
      }

      final fileExt = filePath.toLowerCase().split('.').last;
      List<List<dynamic>> dataShift;

      if (fileExt == 'csv') {
        dataShift = await _bacaCsv(filePath);
      } else if (fileExt == 'xlsx' || fileExt == 'xls') {
        dataShift = await _bacaExcel(filePath);
      } else {
        setState(() {
          _errorMessage = 'Tipe file tidak didukung: .$fileExt';
          _loading = false;
          _shiftAktifSaatIni = null;
        });
        return;
      }

      if (dataShift.isEmpty || dataShift.first.length < 3) {
        setState(() {
          _errorMessage = 'Data file kosong atau format kolom tidak sesuai (Harus: Tgl, Shift, Nama).';
          _loading = false;
          _shiftAktifSaatIni = null;
        });
        return;
      }

      // 🏆 PERBAIKAN: Gunakan DateTime.now() untuk penentuan shift dan tanggal hari ini
      final now = DateTime.now();
      final shiftAktifSaatIni = _tentukanShift(now, setting.jadwal);
      final todayInt = int.tryParse(DateFormat('d').format(now)); // Gunakan 'now' DateTime

      if (todayInt == null) {
        setState(() {
          _errorMessage = 'Gagal memproses tanggal hari ini (internal error).';
          _loading = false;
          _shiftAktifSaatIni = null;
        });
        return;
      }

      debugPrint('DEBUG SHIFT AKTIF: Tanggal Hari Ini: $todayInt');
      debugPrint('DEBUG SHIFT AKTIF: Shift yang Dicari: $shiftAktifSaatIni');

      final rowSekarang = dataShift.firstWhere(
            (r) => r.length >= 3 && int.tryParse(r[0].toString().trim().split('.').first) == todayInt && r[1].toString() == shiftAktifSaatIni.toString(),
        orElse: () => <String>[],
      );

      if (rowSekarang.isNotEmpty) {
        final namaStaff = rowSekarang[2].toString().trim();
        final fotoPath = _cariFotoStaff(folderFoto, namaStaff);
        setState(() {
          _namaStaffAktif = namaStaff;
          _pathFotoAktif = fotoPath;
          _shiftAktifSaatIni = shiftAktifSaatIni; // 🏆 PENTING: Simpan shift aktif di state
        });
        debugPrint('DEBUG STAFF DITEMUKAN: Nama: $_namaStaffAktif, Foto: $_pathFotoAktif');

        if (shiftAktifSaatIni < 3) {
          final shiftBerikutnya = shiftAktifSaatIni + 1;
          final rowBerikutnya = dataShift.firstWhere(
                (r) => r.length >= 3 && int.tryParse(r[0].toString().trim().split('.').first) == todayInt && r[1].toString() == shiftBerikutnya.toString(),
            orElse: () => <String>[],
          );

          if (rowBerikutnya.isNotEmpty) {
            setState(() {
              _namaStaffBerikutnya = rowBerikutnya[2].toString().trim();
            });
            debugPrint('DEBUG STAFF BERIKUTNYA DITEMUKAN: Nama: $_namaStaffBerikutnya');
          }
        }

      } else {
        setState(() {
          _namaStaffAktif = null;
          _pathFotoAktif = null;
          _shiftAktifSaatIni = shiftAktifSaatIni; // 🏆 PENTING: Simpan shift aktif di state (meski data kosong)
        });
        debugPrint('DEBUG STAFF TIDAK DITEMUKAN: Tidak ada data shift yang cocok.');
      }

      setState(() { _loading = false; });

    } catch (e) {
      debugPrint('Gagal memuat data staff (Catch All): $e');
      setState(() {
        _errorMessage = 'Gagal memproses file. Pastikan format benar.';
        _loading = false;
        _shiftAktifSaatIni = null;
      });
    }
  }

  // Revisi: Menerima DateTime sebagai input
  int _tentukanShift(DateTime now, Map<String, List<String?>> jadwalSetting) {
    // Gunakan DateTime object untuk mendapatkan nama hari
    final namaHari = DateFormat('EEEE', 'id_ID').format(now);
    final jadwalHariIni = jadwalSetting[namaHari] ?? [];

    final sesiMenit = jadwalHariIni.map((t) {
      if (t == null || t.isEmpty) return null;
      try {
        final parts = t.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      } catch (_) {
        return null;
      }
    }).whereType<int>().toList();

    if (sesiMenit.length < 3) return 1;

    // Hitung total menit saat ini (00:00 = 0)
    final totalMenitNow = now.hour * 60 + now.minute;

    final menitSesi2 = sesiMenit[1];
    final menitSesi3 = sesiMenit[2];

    if (totalMenitNow >= menitSesi3) return 3;
    if (totalMenitNow >= menitSesi2) return 2;
    return 1;
  }

  // --- Fungsi Pembaca File Tetap Sama ---

  Future<List<List<dynamic>>> _bacaCsv(String path) async {
    debugPrint('🟡 [CSV DEBUG] Mulai membaca file: $path');

    final file = File(path);
    if (!file.existsSync()) {
      debugPrint('❌ [CSV DEBUG] File tidak ditemukan di path: $path');
      return [];
    }

    String csvString;
    try {
      csvString = await file.readAsString();
      debugPrint('✅ [CSV DEBUG] File berhasil dibaca, panjang isi: ${csvString.length}');
    } catch (e) {
      debugPrint('❌ [CSV DEBUG] Gagal membaca file CSV: $e');
      return [];
    }

    if (csvString.trim().isEmpty) {
      debugPrint('⚠️ [CSV DEBUG] File kosong, tidak ada isi.');
      return [];
    }

    // 🔹 Deteksi otomatis pemisah (delimiter)
    String delimiter = ',';
    final hasComma = csvString.contains(',');
    final hasSemicolon = csvString.contains(';');

    if (hasSemicolon && !hasComma) {
      delimiter = ';';
    } else if (hasSemicolon && hasComma) {
      final countSemicolon = RegExp(';').allMatches(csvString).length;
      final countComma = RegExp(',').allMatches(csvString).length;
      delimiter = countSemicolon > countComma ? ';' : ',';
    }

    debugPrint('🟢 [CSV DEBUG] Deteksi delimiter: "$delimiter"');

    // 🔹 Deteksi karakter akhir baris
    final eol = csvString.contains('\r\n') ? '\r\n' : '\n';
    debugPrint('🟢 [CSV DEBUG] Deteksi end-of-line: ${eol == '\r\n' ? 'Windows (\\r\\n)' : 'Unix (\\n)'}');

    // 🔹 Parsing isi CSV
    List<List<dynamic>> csvData = [];
    try {
      final converter = CsvToListConverter(
        fieldDelimiter: delimiter,
        shouldParseNumbers: false,
        eol: eol,
      );

      csvData = converter.convert(csvString);
      debugPrint('✅ [CSV DEBUG] Berhasil parsing CSV, total baris: ${csvData.length}');
    } catch (e) {
      debugPrint('❌ [CSV DEBUG] Gagal parsing CSV: $e');
      return [];
    }

    if (csvData.isEmpty) {
      debugPrint('⚠️ [CSV DEBUG] Tidak ada data setelah parsing.');
      return [];
    }

    if (csvData.first.isNotEmpty &&
        csvData.first[0].toString().toLowerCase().contains('tanggal')) {
      debugPrint('ℹ️ [CSV DEBUG] Header terdeteksi dan dihapus: ${csvData.first}');
      csvData.removeAt(0);
    }

    csvData = csvData
        .where((row) => row.isNotEmpty && row.any((cell) => cell.toString().trim().isNotEmpty))
        .map((row) => row.map((cell) => cell.toString().trim()).toList())
        .toList();

    if (csvData.isEmpty) {
      debugPrint('⚠️ [CSV DEBUG] Setelah pembersihan, semua baris kosong.');
    }

    for (int i = 0; i < csvData.length && i < 5; i++) {
      debugPrint('📄 [CSV DEBUG] Baris ${i + 1}: ${csvData[i]}');
    }

    debugPrint('✅ [CSV DEBUG] Pembacaan CSV selesai. Total baris valid: ${csvData.length}');
    return csvData;
  }

  Future<List<List<dynamic>>> _bacaExcel(String path) async {
    final bytes = File(path).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    final List<List<dynamic>> excelData = [];
    for (var i = 1; i < sheet.maxRows; i++) {
      var row = sheet.row(i);
      excelData.add(row.map((cell) => cell?.value.toString() ?? '').toList());
    }
    return excelData;
  }

  String? _cariFotoStaff(String folder, String nama) {
    try {
      final dir = Directory(folder);
      if (!dir.existsSync()) {
        debugPrint("DEBUG FOTO: Folder foto TIDAK ditemukan di: $folder");
        return null;
      }

      final namaDicari = nama.trim().toLowerCase();

      final files = dir.listSync().whereType<File>().where((f) {
        final ext = f.path.split('.').last.toLowerCase();
        return ['jpg', 'jpeg', 'png'].contains(ext);
      }).toList();

      if (files.isEmpty) {
        debugPrint("DEBUG FOTO: Folder DITEMUKAN, tetapi TIDAK ada file JPG/PNG.");
      }

      for (var f in files) {
        final fullFileName = f.path.split(Platform.pathSeparator).last.toLowerCase();
        final lastDot = fullFileName.lastIndexOf('.');
        final fileNameWithoutExt = lastDot != -1
            ? fullFileName.substring(0, lastDot)
            : fullFileName;

        debugPrint("DEBUG FOTO: Mencari '$namaDicari', Membandingkan dengan: '$fileNameWithoutExt'");

        if (fileNameWithoutExt == namaDicari) {
          debugPrint("DEBUG FOTO: FOTO DITEMUKAN: ${f.path}");
          return f.path;
        }
      }
      debugPrint("DEBUG FOTO: Tidak ada foto yang cocok ditemukan untuk staff: $nama");

    } catch (e) {
      debugPrint("ERROR saat mencari foto staff: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        elevation: 4,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Card(
        elevation: 4,
        color: Colors.red.shade50,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 30),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Periksa Pengaturan > Path CSV/Excel Shift dan Folder Foto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_pathFotoAktif == null) {
      return const Card(
        elevation: 4,
        color: Color(0xFFF9F3FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Tidak ada data dan gambar staff.\n''Atur CSV dan foto staff di Pengaturan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    // Tampilkan data dan foto
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: Image.file(
              File(_pathFotoAktif!),
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (context, _, __) =>
              const Center(
                child: Icon(Icons.broken_image, size: 60, color: Colors.red),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Column(
              children: [
                // Tampilkan nama staff sesi berikutnya jika ada
                if (_namaStaffBerikutnya != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sesi berikutnya -> $_namaStaffBerikutnya',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}