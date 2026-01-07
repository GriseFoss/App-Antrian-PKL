import 'package:app_antrian/component/gambar_pst_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../data/antrian.dart';
import '../data/setting.dart';
import '../data/tamu.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../component/antrian_card.dart';
import '../component/antrian_form.dart';
import '../component/custom_header.dart';
import '../component/custom_footer.dart';
import '../component/nav_drawer.dart' as Custom;
import '../component/gambar_infografis_card.dart';
import '../service/hive_service.dart';
import '../service/setting_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  bool showForm = false;
  bool _isFullScreen = false;
  List<int> _tamuIdList = [];
  int _antrianSekarangIndex = 0;
  late int _antrianSelesai;
  final FocusNode _focusNode = FocusNode();

  List<String> _pathsGambarRotasi = [];

  // Getter antrian
  int get _totalAntrian => _tamuIdList.length;

  // Getter ID dari List berdasarkan indeks
  int? get _tamuIdAntrianSekarang {
    if (_antrianSekarangIndex <= 0 || _antrianSekarangIndex > _tamuIdList.length) {
      return null;
    }
    // Indeks List adalah (nomor antrian - 1)
    return _tamuIdList[_antrianSekarangIndex - 1];
  }

  // Getter untuk tampilan (1-based)
  int get _antrianSekarangNumber => _antrianSekarangIndex;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadAntrian();
    _setFullScreen();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _setFullScreen() async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      if (!await windowManager.isFullScreen()){
        await windowManager.setFullScreen(true);
        debugPrint("✅ Fullscreen aktif");
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
    }
  }

  Future<void> _toggleFullScreen() async {
    final isFullScreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFullScreen);
    setState(() {
      _isFullScreen = !isFullScreen;
    });
    debugPrint(_isFullScreen ? "✅ Fullscreen ON" : "✅ Fullscreen OFF");
  }

  @override
  void onWindowEnterFullScreen() {
    setState(() {
      _isFullScreen = true;
    });
  }

  @override
  void onWindowLeaveFullScreen() {
    setState(() {
      _isFullScreen = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //Atur Fullscreen
      if (!(await windowManager.isFullScreen())) {
        await windowManager.setFullScreen(true);
        debugPrint("✅ Jendela diatur ke Fullscreen setelah render Home.");
      }

      //fokus jendela
      await windowManager.focus();
      debugPrint("✅ Fokus jendela ditegaskan.");
    });
  _loadAntrian();
  }

  void _loadAntrian() {
    final antrianBox = HiveService.getAntrianBox();
    final today = DateTime.now();

    final todayAntrian = antrianBox.values
        .where((a) =>
    a.entryTime.year == today.year &&
        a.entryTime.month == today.month &&
        a.entryTime.day == today.day)
        .toList();

    // Urutkan berdasarkan nomor Antrian
    todayAntrian.sort((a, b) => a.nomorAntrian.compareTo(b.nomorAntrian));

    setState(() {
      _tamuIdList = todayAntrian.map((a) => a.tamuId).toList();
      _antrianSelesai = todayAntrian.where((a) => a.isSelesai).length;
      if (_tamuIdList.isEmpty) {
        _antrianSekarangIndex = 0;
        _antrianSelesai = 0;
      } else if (_antrianSekarangIndex == 0) {
        _antrianSekarangIndex = 1; // Mulai dari antrian ke-1
      }
    });
  }

  Future<void> _handleDataSaved(Map<String, String> data) async {
    if ((data["nama"]?.isEmpty ?? true) || (data["keperluan"]?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data tidak boleh kosong")),
      );
      return;
    }

    final now = DateTime.now();
    final antrianBox = HiveService.getAntrianBox();

    final todayAntrianCount = antrianBox.values
        .where((a) =>
    a.entryTime.year == now.year &&
        a.entryTime.month == now.month &&
        a.entryTime.day == now.day)
        .length;

    final newTotal = todayAntrianCount + 1;

    //Revisi 1 perbaiki urutan
    final hari = now.day.toString().padLeft(2, '0');
    final bulan = now.month.toString().padLeft(2, '0');
    final tahun = now.year.toString().substring(2, 4);
    final urutanStr = newTotal.toString().padLeft(2, '0');
    final idStr = "$tahun$bulan$hari$urutanStr";
    final id = int.parse(idStr);

    final tamu = Tamu(
      nomor: newTotal,
      id: id,
      nama: data["nama"] ?? "-",
      keperluan: data["keperluan"] ?? "-",
      instansi: data["instansi"] ?? "-",
      arrivalTime: now,
    );

    await HiveService.saveTamu(tamu);
    await Future.delayed(const Duration(milliseconds: 50));

    final antrian = Antrian(
      nomorAntrian: newTotal,
      entryTime: now,
      tamuId: id,
      isSelesai: false,
    );

    await antrianBox.add(antrian);

    if (_antrianSekarangIndex == 0) {
      _antrianSekarangIndex = 1;
    }

    setState(() => showForm = false);
    _loadAntrian();
  }

  void _handleNext() async {
    if (_antrianSekarangIndex < _totalAntrian) {
      final newAntrianSekarang = _antrianSekarangIndex + 1;
      await _updateAntrianSelesai(_antrianSekarangIndex, true);

      setState(() {
        _antrianSekarangIndex = newAntrianSekarang;
      });

      _loadAntrian();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ini adalah antrian terakhir.")),
      );
    }
  }

  void _handlePrevious() async {
    if (_antrianSekarangIndex > 1) {
      final newAntrianSekarang = _antrianSekarangIndex - 1;
      await _updateAntrianSelesai(newAntrianSekarang, false);

      setState(() {
        _antrianSekarangIndex = newAntrianSekarang;
      });

      _loadAntrian();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ini adalah antrian pertama.")),
      );
    }
  }

  Future<void> _updateAntrianSelesai(int nomorAntrian, bool isFinished) async {
    final antrianBox = HiveService.getAntrianBox();
    final today = DateTime.now();

    final antrianKey = antrianBox.keys.firstWhere(
          (k) {
        final antrian = antrianBox.get(k);
        return antrian?.nomorAntrian == nomorAntrian &&
            antrian?.entryTime.year == today.year &&
            antrian?.entryTime.month == today.month &&
            antrian?.entryTime.day == today.day;
      },
      orElse: () => null,
    );

    if (antrianKey != null) {
      final antrianLama = antrianBox.get(antrianKey);
      if (antrianLama != null) {
        final antrianBaru = Antrian(
          nomorAntrian: antrianLama.nomorAntrian,
          entryTime: antrianLama.entryTime,
          tamuId: antrianLama.tamuId,
          isSelesai: isFinished,
        );
        await antrianBox.put(antrianKey, antrianBaru);
      }
    }
  }


  void _handleCancel() => setState(() => showForm = false);
  void _handleClose() => setState(() => showForm = false);

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode..requestFocus(),
      autofocus: true,
      onKeyEvent:(event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.f11) {
          _toggleFullScreen();
        }
        // ESC untuk keluar dari fullscreen
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _isFullScreen) {
          _toggleFullScreen();
        }
      },
      child : Scaffold(
      drawer: const Custom.NavigationDrawer(),
      body: Column(
        children: [
          const CustomHeader(),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;

                if (width > 1000) {
                  // Tampilan 3 Kolom (Layar Lebar)
                  return _buildTigaKolomLayout();
                } else if (width > 600) {
                  // Tampilan 2 Kolom (Layar Sedang)
                  return _buildDuaKolomLayout();
                } else {
                  // Tampilan 1 Kolom (Layar Sempit/Mobile)
                  return _buildSatuKolomLayout();
                }
              },
            ),
          ),

          // Custom Footer (Tetap di bawah dan responsif terhadap setting)
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
    )
    );
  }

  // Helper Kolom Tengah (Kartu Antrian/Form)
  Widget _buildKolomTengah({bool isSmallScreen = false}) {
    return Expanded(
      flex: isSmallScreen ? 0 : 5,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: showForm
              ? antrian_form(
            onDataSaved: _handleDataSaved,
            onCancel: _handleCancel,
            onClose: _handleClose,
          )
              : antrian_card.fromData(
            Antrian(
              nomorAntrian: 0,
              entryTime: DateTime.now(),
              tamuId: _tamuIdAntrianSekarang ?? 0,
              isSelesai: false,
            ),
            antrianSekarang: _antrianSekarangNumber,
            totalAntrian: _totalAntrian,
            onDaftarPressed: () {
              setState(() => showForm = true);
            },
            onNextPressed: _handleNext,
            onPreviousPressed: _handlePrevious,
          ),
        ),
      ),
    );
  }

  // 1. Tiga Kolom (Lebar > 1000)
  Widget _buildTigaKolomLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kolom Kiri (Pegawai)
        const Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: StaffPstCard(),
            ),
          ),
        ),
        // Kolom Tengah (Antrian/Form)
        _buildKolomTengah(),
        // Kolom Kanan (Infografis)
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: GambarInfoCard(
                //daftarPathGambar: _pathsGambarRotasi,
                //delayDetik: _delayGambarDetik,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Dua Kolom (Lebar > 600)
  Widget _buildDuaKolomLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kolom Kiri Gabungan (Pegawai + Infografis)
        Expanded(
          flex: 5, // 50% lebar
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Kartu Pegawai
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 450),
                    child: const StaffPstCard(),
                  ),
                ),
                // Kartu Infografis
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 450),
                    child: GambarInfoCard(
                      //daftarPathGambar: _pathsGambarRotasi,
                      //delayDetik: _delayGambarDetik,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Kolom Kanan (Antrian/Form Tetap)
        _buildKolomTengah(), // 50% lebar
      ],
    );
  }

  // 3. Satu Kolom (Lebar <= 600)
  Widget _buildSatuKolomLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Kolom Tengah (Antrian/Form)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildKolomTengah(isSmallScreen: true),
          ),
          // Kartu Pegawai
          Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 450, maxWidth: 400),
              child: const StaffPstCard(),
            ),
          ),
          // Kartu Infografis
          Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 450, maxWidth: 400),
              child: GambarInfoCard(
                //daftarPathGambar: _pathsGambarRotasi,
                //delayDetik: _delayGambarDetik,
              ),
            ),
          ),
        ],
      ),
    );
  }
}