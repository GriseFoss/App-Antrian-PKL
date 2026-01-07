import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

const Color darkBlue = Color(0xFF224480);
const Color lightGray = Color(0xFFD9D9D9);
const Color brightOrange = Color(0xFFC67B02);

class CustomFooter extends StatelessWidget {
  final double desiredHeight = 40.0;
  static const String _defaultRunningText = 'Selamat Datang di BPS Metro | Data akurat untuk Indonesia Maju | Jam Pelayanan Sen-Kamis : 08.00 - 15.30 jumat : 08.00 - 16.00 | Hubungi kami di (62-725)41758 dan bps1872@bps.go.id juga di instagram @bpskotametro | Alamat kami Jl. AR Prawiranegara, Metro, Lampung |';
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: desiredHeight,
      color: darkBlue,
      alignment: Alignment.center,
      child: Marquee(
        text: _defaultRunningText,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        blankSpace: 20.0,
        velocity: 80.0,
        pauseAfterRound: const Duration(seconds: 1),
        startPadding: 10.0,
        accelerationDuration: const Duration(seconds: 1),
        accelerationCurve: Curves.linear,
        decelerationDuration: const Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
      ),
    );
  }
}