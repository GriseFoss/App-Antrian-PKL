import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/setting.dart';
import '../service/setting_service.dart';

class GambarInfoCard extends StatefulWidget {
  final int delayDetik;

  const GambarInfoCard({
    super.key,
    this.delayDetik = 5,
  });

  @override
  State<GambarInfoCard> createState() => _GambarInfoCardState();
}

class _GambarInfoCardState extends State<GambarInfoCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _halamanSekarang = 0;
  List<String> _daftarPathGambar = [];
  bool _loading = true;
  int _delayDetik = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _muatGambarDariSetting();
  }

  Future<void> _muatGambarDariSetting() async {
    try {
      setState(() => _loading = true);
      final setting = SettingService.getSetting();
      final folderPath = setting.foto2;
      final delayRotasi = setting.delayRotasi;
      _delayDetik = delayRotasi.toInt();

      if (folderPath.isEmpty || !Directory(folderPath).existsSync()) {
        setState(() {
          _daftarPathGambar = [];
          _loading = false;
        });
        return;
      }

      final dir = Directory(folderPath);
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) =>
      f.path.toLowerCase().endsWith('.jpg') ||
          f.path.toLowerCase().endsWith('.png') ||
          f.path.toLowerCase().endsWith('.jpeg'))
          .map((f) => f.path)
          .toList();

      setState(() {
        _daftarPathGambar = files;
        _loading = false;
      });

      if (files.length > 1) _mulaiTimer();
    } catch (e) {
      debugPrint('Gagal memuat gambar: $e');
      setState(() => _loading = false);
    }
  }

  void _mulaiTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: _delayDetik), (timer) {
      int halamanBerikutnya = _halamanSekarang + 1;
      if (halamanBerikutnya >= _daftarPathGambar.length) halamanBerikutnya = 0;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          halamanBerikutnya,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Setting>>(
      valueListenable: SettingService.settingListenable,
      builder: (context, box, _) {
        // setiap kali setting berubah (misal ganti shift)
        // widget otomatis refresh gambar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _muatGambarDariSetting();
        });

        if (_loading) {
          return const Card(
            elevation: 4,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (_daftarPathGambar.isEmpty) {
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
                  'Tidak ada gambar.\nAtur folder gambar di halaman Pengaturan.',
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

        return Card(
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _daftarPathGambar.length,
            onPageChanged: (index) {
              _halamanSekarang = index;
            },
            itemBuilder: (context, index) {
              final filePath = _daftarPathGambar[index];
              return Image.file(
                File(filePath),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.red),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
