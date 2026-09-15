import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context);

    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF151515)
                    : Colors.white,

                borderRadius:
                    BorderRadius.circular(22),

                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.black12,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Icon(
                    isDark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    size: 40,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'APPEARANCE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isDark
                        ? 'Dark Mode'
                        : 'Light Mode',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Choose how the portfolio looks.',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white54
                          : Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,

                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    value: isDark,

                    onChanged: (_) {
                      themeProvider.toggleTheme();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Powered by Provider',
              style: TextStyle(
                color: isDark
                    ? Colors.white38
                    : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}     