// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'services/data_service.dart';
import 'utils/theme.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/global_action_toolbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize sqflite ffi for desktop platforms so `databaseFactory` is set.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final svc = DataService();
  await svc.init();
  runApp(
    ChangeNotifierProvider<DataService>.value(
      value: svc,
      child: const MarshBitesApp(),
    ),
  );
}

class MarshBitesApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();
  const MarshBitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Vertexis - The Marsh Bites',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: svc.themeMode,
      home: const LoginScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            Positioned(
              top: 20, // Moved higher
              right: 16,
              child: SafeArea(
                child: GlobalActionToolbar(navigatorKey: navigatorKey),
              ),
            ),
          ],
        );
      },
    );
  }
}
