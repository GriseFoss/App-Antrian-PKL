import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import '../component/custom_header.dart';
import '../component/custom_footer.dart';
import '../component/nav_drawer.dart' as Custom;
import '../service/hive_service.dart';
import '../service/setting_service.dart';
import '../data/setting.dart';
import 'package:hive/hive.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final TextEditingController _lokasiExportController = TextEditingController();
  final TextEditingController _lokasiLogController    = TextEditingController();
  final TextEditingController _lokasiDataController   = TextEditingController();
  final TextEditingController _foto1Controller        = TextEditingController();
  final TextEditingController _foto2Controller        = TextEditingController();
  final TextEditingController _csvShiftController     = TextEditingController();
  final TextEditingController _gambarFolderController = TextEditingController();
  final TextEditingController _runningTextController  = TextEditingController();
  double _delayRotasi = 5.0;

  Map<String, List<TimeOfDay?>> jadwal = {};

  bool tampilkanTotalAntrian = false;
  bool tampilkanFooter= true;
  late Setting _currentSetting;

  List<FileSystemEntity> gambarList = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  TimeOfDay? _stringToTimeOfDay(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
  String? _timeOfDayToString(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _loadSettings() {
    final Setting savedSetting = SettingService.getSetting();
    _currentSetting = savedSetting;
    _lokasiExportController.text  = savedSetting.lokasiExport;
    _lokasiLogController.text     = savedSetting.lokasiLog;
    _lokasiDataController.text    = savedSetting.lokasiData;
    _foto1Controller.text         = savedSetting.foto1;
    _foto2Controller.text         = savedSetting.foto2;
    _csvShiftController.text      = savedSetting.csvShiftPath;
    _gambarFolderController.text  = savedSetting.gambarFolderPath;
    _runningTextController.text   = savedSetting.runningText;

    setState(() {
      _delayRotasi = savedSetting.delayRotasi;
      tampilkanTotalAntrian = savedSetting.tampilkanTotalAntrian;
      tampilkanFooter = savedSetting.tampilkanCustomFooter;
      jadwal = savedSetting.jadwal.map((key, value) {
        return MapEntry(
            key, value.map((timeStr) => _stringToTimeOfDay(timeStr)).toList());
      });
    });

    if (savedSetting.gambarFolderPath.isNotEmpty) {
      _muatGambarDariFolder(savedSetting.gambarFolderPath);
    }
  }

  void _saveSettings() {
    final jadwalToSave = jadwal.map((key, value) {
      return MapEntry(
          key, value.map((time) => _timeOfDayToString(time)).toList());
    });

    final Setting newSetting = Setting(
      lokasiExport: _lokasiExportController.text,
      lokasiLog : _lokasiLogController.text,
      lokasiData: _lokasiDataController.text,
      foto1: _foto1Controller.text,
      foto2: _foto2Controller.text,
      csvShiftPath: _csvShiftController.text,
      gambarFolderPath: _gambarFolderController.text,
      delayRotasi: _delayRotasi,
      tampilkanTotalAntrian: tampilkanTotalAntrian,
      jadwal: jadwalToSave,
      tampilkanCustomFooter: tampilkanFooter,
      runningText: _runningTextController.text,
    );

    SettingService.saveSetting(newSetting);
  }

  @override
  void dispose() {
    _lokasiExportController.dispose();
    _lokasiLogController.dispose();
    _lokasiDataController.dispose();
    _foto1Controller.dispose();
    _foto2Controller.dispose();
    _csvShiftController.dispose();
    _gambarFolderController.dispose();
    _runningTextController.dispose();
    super.dispose();
  }

  Future<void> _pilihFolder(TextEditingController controller) async {
    String? hasil = await FilePicker.platform.getDirectoryPath();
    if (hasil != null) {
      setState(() {
        controller.text = hasil;
      });
      _saveSettings();
    }
  }

  Future<void> _pilihFile(TextEditingController controller) async {
    FilePickerResult? hasil = await FilePicker.platform.pickFiles();
    if (hasil != null && hasil.files.single.path != null) {
      setState(() {
        controller.text = hasil.files.single.path!;
      });
      _saveSettings();
    }
  }

  Future<void> _pilihWaktu(String hari, int sesiIndex) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: jadwal[hari]![sesiIndex] ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        jadwal[hari]![sesiIndex] = picked;
      });
      _saveSettings();
    }
  }

  void _hapusSesi(String hari, int index) {
    if (!jadwal.containsKey(hari)) return;
    setState(() {
      if (index >= 0 && index < jadwal[hari]!.length) {
        jadwal[hari]![index] = null;
      }
    });
    _saveSettings();
  }

  Future<void> _bacaExcelShift(String path) async {
    try {
      final bytes = File(path).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      for (var table in excel.tables.keys) {
        debugPrint('Sheet: $table, Baris: ${excel.tables[table]?.maxRows}');
      }
    } catch (e) {
      debugPrint("Gagal membaca file Excel: $e");
    }
  }

  Future<void> _muatGambarDariFolder(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      final List<FileSystemEntity> files = dir.listSync().where((f) {
        final ext = f.path.split('.').last.toLowerCase();
        return ['jpg', 'jpeg', 'png', 'bmp', 'gif'].contains(ext);
      }).toList();

      setState(() {
        gambarList = files;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Custom.NavigationDrawer(),
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                if (width > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: Container(color: Colors.grey[300])), // Kiri (30%)

                      Expanded(
                        flex: 4, // Tengah (40%)
                        child: _buildSettingsContent(),
                      ),

                      Expanded(flex: 3, child: Container(color: Colors.grey[300])), // Kanan (30%)
                    ],
                  );
                } else {
                  return _buildSettingsContent();
                }
              },
            ),
          ),

          ValueListenableBuilder<Box<Setting>>(
            valueListenable: SettingService.settingListenable,
            builder: (context, box, child) {
              final setting = box.get('appSetting') ?? SettingService.getSetting();
              final tampilkanFooter = setting.tampilkanCustomFooter;

              if (tampilkanFooter) {
                return const CustomFooter();
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return Center(
      child: Container(
        color: const Color(0xFFC67B02),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KATEGORI PENYIMPANAN
              const Text("Lokasi Penyimpanan",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white70),
              _buildLokasiExport(),
              const SizedBox(height: 16),
              _buildLokasilog(),
              const SizedBox(height: 16),
              _buildLokasiData(),
              const SizedBox(height: 16),
              _buildFotoField("Letak File Foto Kiri", _foto1Controller),
              const SizedBox(height: 16),
              _buildFotoField("Letak File Foto Kanan", _foto2Controller),
              const SizedBox(height: 16),
              _buildFileField("Path CSV Shift Petugas", _csvShiftController, isExcel: true),
              const SizedBox(height: 25),

              // KATEGORI JADWAL
              const Text(
                "Jadwal ",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white70),
              ...jadwal.entries
                  .where((entry) => entry.key != 'Sabtu' && entry.key != 'Minggu') // Hilangkan weekend
                  .map((entry) {
                final hari = entry.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(hari,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                      ),

                      Expanded(
                        flex: 7,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: List.generate(3, (i) {
                            final jam = entry.value[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ElevatedButton(
                                onPressed: () => _pilihWaktu(hari, i),
                                onLongPress: () => _hapusSesi(hari, i),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding:
                                    const EdgeInsets.symmetric(horizontal: 6)),
                                child: Text(
                                  jam == null
                                      ? "Sesi ${i + 1}"
                                      : '${jam.hour.toString().padLeft(2, '0')}:${jam.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.white),
                        tooltip: "Hapus semua sesi $hari",
                        onPressed: () {
                          setState(() {
                            jadwal[hari] = [null, null, null];
                          });
                          _saveSettings();
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 25),

              // KATEGORI TAMPILAN
              const Text("Tampilan",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white70),

              // Opsi Tampilkan Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tampilkan Footer",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Switch.adaptive(
                    value: tampilkanFooter,
                    onChanged: (val) {
                      setState(() => tampilkanFooter = val);
                      _saveSettings();
                    },
                    activeThumbColor: Colors.white,
                    //activeColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Running Text Field
              _buildRunningTextField("Running Text", _runningTextController),
              const SizedBox(height: 16),

              // Opsi Tampilkan Info Total Antrian
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tampilkan Info Total Antrian",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Switch.adaptive(
                    value: tampilkanTotalAntrian,
                    onChanged: (val) {
                      setState(() => tampilkanTotalAntrian = val);
                      debugPrint('Nilai tampilkanTotalAntrian: $tampilkanTotalAntrian');
                      _saveSettings();
                    },
                    activeThumbColor: Colors.white,
                    //activeColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slider Delay Rotasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Waktu Delay Rotasi Gambar (detik)",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text("${_delayRotasi.toInt()}",
                      style: const TextStyle(color: Colors.white))
                ],
              ),
              Slider(
                value: _delayRotasi,
                min: 1,
                max: 30,
                divisions: 29,
                label: "${_delayRotasi.toInt()} detik",
                onChanged: (val) {
                  setState(() => _delayRotasi = val);
                },
                onChangeEnd: (val) {
                  _saveSettings();
                },
              ),
              const SizedBox(height: 16),

              // Gambar Rotasi Preview
              if (gambarList.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: gambarList.length,
                    itemBuilder: (context, index) {
                      final file = gambarList[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(
                          File(file.path),
                          fit: BoxFit.cover,
                          width: 180,
                          height: 180,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 30),

              // KATEGORI DATA
              const Text("Data",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white70),
              const SizedBox(height: 10),

              _buildDeleteButton("Hapus Seluruh Data Tamu",
                  onConfirm: HiveService.clearAll),
              const SizedBox(height: 10),
              _buildDeleteButton("Hapus Seluruh Data Antrian",
                  onConfirm: HiveService.clearAllAntrian),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLokasiExport() => _buildFileField("Lokasi Export", _lokasiExportController, isFolder: true);
  Widget _buildLokasilog() => _buildFileField("Lokasi Log", _lokasiLogController, isFolder: true);
  Widget _buildLokasiData() => _buildFileField("Lokasi Data", _lokasiDataController, isFolder: true);

  Widget _buildFotoField(String title, TextEditingController controller) =>
      _buildFileField(title, controller, isFolder: true);

  Widget _buildFileField(String title, TextEditingController controller,
      {bool isFolder = false, bool isExcel = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: true,
                decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.folder_open, color: Colors.white),
              onPressed: () async {
                if (isFolder) {
                  await _pilihFolder(controller);
                } else {
                  await _pilihFile(controller);
                }
                if (isExcel && controller.text.isNotEmpty) {
                  _bacaExcelShift(controller.text);
                  _saveSettings();
                }
                if (!isExcel) {
                  _saveSettings();
                }
              },
            )
          ],
        ),
      ],
    );
  }


  Widget _buildDeleteButton(String title,
      {required Future<void> Function() onConfirm}) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.delete_forever),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Konfirmasi"),
            content: Text("Yakin ingin $title?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Batal")),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Hapus")),
            ],
          ),
        );
        if (confirm == true) {
          await onConfirm();
        }
      },
    );
  }

  Widget _buildRunningTextField(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3, // Izinkan multi-baris
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Masukkan running teks di sini...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (value) {
           },
          onEditingComplete: _saveSettings,
          onSubmitted: (value) => _saveSettings(),
        ),
      ],
    );
  }
}