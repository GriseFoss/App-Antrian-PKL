import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_antrian/service/hive_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'service/setting_service.dart';
import 'pages/home.dart';
import 'pages/guestbook.dart';
import 'pages/setting.dart';
import 'service/Log_file.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    //await windowManager.setFullScreen(true);
  });

  runApp(const MyAppLoader());
  await LogToFile.initialize();
}

class MyAppLoader extends StatelessWidget {
  const MyAppLoader({super.key});

  Future<void> _initializeHive() async {
    try {
      await HiveService.init();
      await SettingService.init();
      debugPrint("✅ Hive Service (Box dan Adapter) terinisialisasi.");
    } catch (e, st) {
      debugPrint("❌ Hive init error: $e");
      debugPrint("Stacktrace: $st");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeHive(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('❌ Gagal Inisialisasi Hive: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return const MyApp();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Antrian BPS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        '/setting': (context) => const SettingPage(),
        '/guestbook': (context) => const GuestBookPage(),
      },
    );

  }
}
