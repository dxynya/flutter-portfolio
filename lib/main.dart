import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/activity1_screen.dart';
import 'screens/activity2_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Portfolio',

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Colors.black12,
            ),
          ),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0B),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          surface: Color(0xFF151515),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0B0B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF151515),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Colors.white12,
            ),
          ),
        ),
      ),

      themeMode: themeProvider.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,

      initialRoute: '/',

      routes: {
        '/': (context) => const HomeScreen(),
        '/activity1': (context) => const Activity1Screen(),
        '/activity2': (context) => const Activity2Screen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}