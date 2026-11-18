import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  // needed before reading files when the app starts
  WidgetsFlutterBinding.ensureInitialized();
  await loadData();
  runApp(const ChronoApp());
}

class ChronoApp extends StatelessWidget {
  const ChronoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chrono',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.white,
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
