import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color darkBlue = Color(0xFF224480);
const Color lightGray = Color(0xFFD9D9D9);
const Color brightOrange = Color(0xFFC67B02);

class CustomHeader extends StatefulWidget {
  const CustomHeader({super.key});

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  final double desiredHeight = 100.0;
  final String logoPath = 'assets/icon/logo_bps.png';
  final String iconPath = 'assets/icon/logo_waktu.png';
  late String _waktuSekarang;
  late String _tanggalSekarang;
  Timer? _timer;

  @override
  void initState(){
    super.initState();
    // Pastikan locale Indonesia dimuat untuk format tanggal
    Intl.defaultLocale = 'id_ID';
    _perbaruiWaktu();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _perbaruiWaktu());
  }

  void _perbaruiWaktu() {
    final DateTime now = DateTime.now();
    // Panggil format waktu dan tanggal
    final String formattedTime = DateFormat('HH:mm:ss').format(now);
    final String formattedDate = DateFormat('EEEE, d MMMM yyyy').format(now);
    if (mounted) {
      setState(() {
        _waktuSekarang = formattedTime;
        _tanggalSekarang = formattedDate;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Helper untuk menampilkan ikon menu
  Widget _buildMenuIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Scaffold.of(context).openDrawer();
      },
      child: const Padding(
        padding: EdgeInsets.only(left: 20, right: 10),
        child: Icon(
          Icons.menu,
          color: lightGray,
          size: 40,
        ),
      ),
    );
  }

  // Helper untuk menampilkan logo dan teks judul
  Widget _buildTitleSection(double width) {
    final bool useShortText = width < 650;
    final bool useOnlyLogo = width < 450;
    String titleText = useShortText ? 'BPS Metro' : 'Badan Pusat Statistik';
    String subtitleText = 'Kota Metro';

    if (useOnlyLogo) {
      titleText = '';
      subtitleText = '';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Image.asset(
            logoPath,
            width: 70,
            height: 70,
            fit: BoxFit.contain,
          ),
        ),
        if (!useOnlyLogo)
          const SizedBox(width: 12),
        if (!useOnlyLogo)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titleText,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Roboto',
                  fontSize: useShortText ? 24 : 28, // Ukuran font mengecil jika disingkat
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              if (!useShortText) // Sembunyikan 'Kota Metro' jika teks sudah disingkat
                Text(
                  subtitleText,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // Helper untuk menampilkan waktu
  Widget _buildTimeSection({required bool hideTime}) {
    if (hideTime) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Image.asset(
          iconPath,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _tanggalSekarang,
              style: const TextStyle(
                color: lightGray,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
            ),
            Text(
              _waktuSekarang,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(width: 20), // Padding kanan
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: desiredHeight,
      color: darkBlue,
      child: SafeArea( //SafeArea untuk menghindari notch atau status bar
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            bool hideTime = width < 750; // Sembunyikan waktu di layar kurang dari 750 (untuk 2 kolom layout)
            double horizontalPadding = width < 400 ? 10 : 0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Builder(builder: (context) => _buildMenuIcon(context)),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: horizontalPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildTitleSection(width),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: _buildTimeSection(hideTime: hideTime),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}