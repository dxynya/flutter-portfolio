import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/network_health_provider.dart';

import 'screens/home_screen.dart';
import 'screens/activity1_screen.dart';
import 'screens/activity2_screen.dart';
import 'screens/activity3_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => NetworkHealthProvider(),
        ),
      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'My Flutter Portfolio',

      theme: ThemeData(
        brightness: Brightness.light,

        scaffoldBackgroundColor:
            Colors.white,

        colorScheme:
            const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black,
          surface: Colors.white,
        ),

        appBarTheme:
            const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),

        cardTheme:
            CardThemeData(
          color: Colors.white,
          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),

            side: const BorderSide(
              color: Colors.black12,
            ),
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.black,

            foregroundColor:
                Colors.white,

            padding:
                const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(15),
            ),
          ),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,

        scaffoldBackgroundColor:
            const Color(0xFF0B0B0B),

        colorScheme:
            const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          surface:
              Color(0xFF151515),
        ),

        appBarTheme:
            const AppBarTheme(
          backgroundColor:
              Color(0xFF0B0B0B),

          foregroundColor:
              Colors.white,

          elevation: 0,
        ),

        cardTheme:
            CardThemeData(
          color:
              const Color(0xFF151515),

          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),

            side: const BorderSide(
              color: Colors.white12,
            ),
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.white,

            foregroundColor:
                Colors.black,

            padding:
                const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(15),
            ),
          ),
        ),
      ),

      themeMode:
          themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,

      initialRoute: '/',

      routes: {
        '/':
            (context) =>
                const HomeScreen(),

        '/activity1':
            (context) =>
                const Activity1Screen(),

        '/activity2':
            (context) =>
                const Activity2Screen(),

        '/activity3':
            (context) =>
                const Activity3Screen(),

        '/settings':
            (context) =>
                const SettingsScreen(),
      },
    );
  }
}