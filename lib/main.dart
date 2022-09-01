import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:songeet/helper/material_color_creator.dart';

import 'package:songeet/services/audio_handler.dart';
import 'package:songeet/services/audio_manager.dart';
import 'package:songeet/style/app_colors.dart';
import 'package:songeet/ui/root.dart';

import 'model/play.dart';

GetIt getIt = GetIt.instance;
bool _interrupted = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TechAdapter());
  await Hive.openBox('settings');
  await Hive.openBox('user');
  await Hive.openBox('cache');

  await initialisation();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static Future<void> setAccentColor(
    BuildContext context,
    Color newAccentColor,
  ) async {
    final state = context.findAncestorStateOfType<MyAppState>()!;
    state.changeAccentColor(newAccentColor);
  }

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  void changeAccentColor(Color newAccentColor) {
    setState(() {
      accent = newAccentColor;
    });
  }

  @override
  void dispose() {
    Hive.close();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        scaffoldBackgroundColor: bgColor,
        canvasColor: bgColor,
        appBarTheme: AppBarTheme(backgroundColor: bgColor),
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: createMaterialColor(accent)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Ubuntu',
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: createMaterialColor(accent)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Ubuntu',
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      home: const Songeet(),
    );
  }
}

Future<void> initialisation() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  session.interruptionEventStream.listen((event) {
    if (event.begin) {
      if (audioPlayer.playing) {
        pause();
        _interrupted = true;
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.pause:
        case AudioInterruptionType.duck:
          if (!audioPlayer.playing && _interrupted) {
            play();
          }
          break;
        case AudioInterruptionType.unknown:
          break;
      }
      _interrupted = false;
    }
  });
  final audioHandler = await AudioService.init(
    builder: MyAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.sks.songeet',
      androidNotificationChannelName: 'Songeet',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidNotificationIcon: "drawable/ic_stat_listening",
    ),
  );
  getIt.registerSingleton<AudioHandler>(audioHandler);
  await enableBooster();
}
