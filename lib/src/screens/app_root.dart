import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/local_backend_service.dart';
import '../services/online_battle_service.dart';
import '../state/app_controller.dart';
import 'battle_screen.dart';
import 'friends_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'upgrades_screen.dart';
import 'stats_screen.dart';

class BattleBoatsApp extends StatefulWidget {
  const BattleBoatsApp({super.key});

  @override
  State<BattleBoatsApp> createState() => _BattleBoatsAppState();
}

class _BattleBoatsAppState extends State<BattleBoatsApp>
    with WidgetsBindingObserver {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyImmersiveMode();
    _controller = AppController(
      backend: LocalBackendService(),
      onlineService: OnlineBattleService(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyImmersiveMode();
    }
    _controller.handleAppLifecycleState(state);
  }

  void _applyImmersiveMode() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: <SystemUiOverlay>[],
      );
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BattleBoats',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF071A2B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4FC3F7),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.08),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          if (!_controller.isLoggedIn) {
            return LoginScreen(controller: _controller);
          }

          return HomeScreen(
            controller: _controller,
            onOpenFriends: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FriendsScreen(controller: _controller),
                ),
              );
            },
            onOpenUpgrades: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => UpgradesScreen(controller: _controller),
                ),
              );
            },
            onOpenStats: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StatsScreen(controller: _controller),
                ),
              );
            },
            onStartBattle: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BattleScreen(controller: _controller),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
