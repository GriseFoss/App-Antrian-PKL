import 'package:flutter/material.dart';
import '../data/antrian.dart';
import '../data/setting.dart';
import '../service/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../service/setting_service.dart';

const Color darkBlue = Color(0xFF224480);
const Color lightGray = Color(0xFFD9D9D9);
const Color brightOrange = Color(0xFFC67B02);

class antrian_card extends StatelessWidget {
  final String currentNumber;
  final String totalInfo;
  final String? currentName;
  final VoidCallback? onDaftarPressed;
  final VoidCallback? onNextPressed;
  final VoidCallback? onPreviousPressed;

  const antrian_card ({
    super.key,
    required this.currentNumber,
    required this.totalInfo,
    this.currentName,
    this.onDaftarPressed,
    this.onNextPressed,
    this.onPreviousPressed,
  });

  factory antrian_card.fromData(Antrian data,
      {VoidCallback? onDaftarPressed,
        String? currentName,
        VoidCallback? onNextPressed,
        VoidCallback? onPreviousPressed,
        required int antrianSekarang,
        required int totalAntrian}) {

    final String? namaTamu = HiveService.getTamuNameByAntrianNumber(data.tamuId);

    return antrian_card(
      currentNumber: antrianSekarang.toString(),
      totalInfo: "Dari Total Antrian\n$totalAntrian",
      currentName: namaTamu,
      onDaftarPressed: onDaftarPressed,
      onNextPressed: onNextPressed,
      onPreviousPressed: onPreviousPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Variabel settingsBox sudah tidak diperlukan di sini
    return Container(
      color: Color(0xFFC67B02),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Nomor Antrian\nSaat Ini',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),

          if (currentName != null && currentName!.isNotEmpty) ...[
            Builder(
              builder: (context) {
                debugPrint("[DEBUG] Nama tamu tampil di UI: $currentName");
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 10),
            Text(
              currentName!,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),

          Row(
            children: [
              const Expanded(flex: 4, child: SizedBox()),
              Expanded(
                flex: 4,
                child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          currentNumber,
                          style: TextStyle(
                            fontSize: 70,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3
                              ..color = Colors.black,
                          ),
                        ),
                        Text(
                          currentNumber,
                          style: const TextStyle(
                            fontSize: 70,
                            fontWeight: FontWeight.bold,
                            color: brightOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Expanded(flex: 4, child: SizedBox()),
            ],
          ),

          // ValueListenableBuilder menggantikan Text(totalInfo)
          ValueListenableBuilder<Box<Setting>>(
            valueListenable: SettingService.settingListenable,
            builder: (context, box, child) {
              final setting = box.get('appSetting');
              final tampilkanInfo = setting?.tampilkanTotalAntrian ?? false ;
              debugPrint('[DEBUG antrian_card] tampilkanTotalAntrian yang dibaca dari Hive: $tampilkanInfo');

              if (tampilkanInfo) {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      totalInfo,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              } else {
                return const SizedBox(height: 32);
                }
            },
          ),

          ElevatedButton(
            onPressed: onDaftarPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text('Daftar Tamu'),
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tombol Sebelumnya
              ElevatedButton(
                onPressed: onPreviousPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back),
                    SizedBox(width: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onNextPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}