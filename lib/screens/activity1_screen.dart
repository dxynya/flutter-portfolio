import 'package:flutter/material.dart';

class Activity1Screen extends StatelessWidget {
  const Activity1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ACTIVITY 01',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1000,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),

                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white
                          : Colors.black,
                      borderRadius:
                          BorderRadius.circular(25),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100 POINTS',
                          style: TextStyle(
                            color: isDark
                                ? Colors.black54
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'HANDS-ON ACTIVITY #1',
                          style: TextStyle(
                            color: isDark
                                ? Colors.black
                                : Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Flutter Portfolio & State Management',
                          style: TextStyle(
                            color: isDark
                                ? Colors.black87
                                : Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: isDark
                                  ? Colors.black54
                                  : Colors.white70,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              'Due Tomorrow, 23:59',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.black54
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // OBJECTIVE
                  _sectionTitle(
                    'OBJECTIVE',
                    isDark,
                  ),

                  const SizedBox(height: 10),

                  _contentCard(
                    isDark,
                    child: const Text(
                      'Build a multi-screen Flutter application '
                      'that will serve as the master compilation '
                      'app for all your future laboratory activities.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // INSTRUCTIONS
                  _sectionTitle(
                    'INSTRUCTIONS',
                    isDark,
                  ),

                  const SizedBox(height: 10),

                  _instructionCard(
                    isDark,
                    number: '01',
                    title: 'Project Setup',
                    description:
                        'Create a new Flutter project.',
                    icon: Icons.folder_open_outlined,
                  ),

                  const SizedBox(height: 12),

                  _instructionCard(
                    isDark,
                    number: '02',
                    title: 'Multi-Screen Navigation',
                    description:
                        'Design a responsive Home Dashboard '
                        'that acts as a menu. Implement navigation '
                        'routes to at least two separate Activity screens.',
                    icon: Icons.screen_lock_portrait_outlined,
                  ),

                  const SizedBox(height: 12),

                  _instructionCard(
                    isDark,
                    number: '03',
                    title: 'Widget Architecture',
                    description:
                        'Demonstrate clear declarative UI principles. '
                        'Use StatelessWidget for static components '
                        'like custom buttons or cards and StatefulWidget '
                        'for local, screen-specific interactions.',
                    icon: Icons.widgets_outlined,
                  ),

                  const SizedBox(height: 12),

                  _instructionCard(
                    isDark,
                    number: '04',
                    title: 'Responsive Layout',
                    description:
                        'Use native layout widgets such as Column, '
                        'Row, Expanded, or Flexible to ensure your '
                        'screens adapt properly to different device '
                        'sizes without overflowing.',
                    icon: Icons.devices_outlined,
                  ),

                  const SizedBox(height: 12),

                  _instructionCard(
                    isDark,
                    number: '05',
                    title: 'Global State Management',
                    description:
                        'Integrate a state management package such '
                        'as Provider. Create a global parameter such '
                        'as a Dark/Light Theme toggle or a user profile '
                        'name on a dedicated Settings screen. Changing '
                        'this value must instantly update the UI on '
                        'the Home Dashboard across the app.',
                    icon: Icons.sync_alt_outlined,
                  ),

                  const SizedBox(height: 25),

                  // DELIVERABLES
                  _sectionTitle(
                    'DELIVERABLES',
                    isDark,
                  ),

                  const SizedBox(height: 10),

                  _contentCard(
                    isDark,
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white
                                : Colors.black,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.task_alt_outlined,
                            color: isDark
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),

                        const SizedBox(width: 15),

                        const Expanded(
                          child: Text(
                            'Submit the link to your source code '
                            'repository along with a screen recording '
                            'that demonstrates the responsive layout '
                            'and working state management toggle.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // BACK BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      icon: const Icon(
                        Icons.arrow_back,
                      ),

                      label: const Text(
                        'BACK TO HOME',
                      ),

                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 17,
                        ),

                        backgroundColor: isDark
                            ? Colors.white
                            : Colors.black,

                        foregroundColor: isDark
                            ? Colors.black
                            : Colors.white,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    bool isDark,
  ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 3,
        color: isDark
            ? Colors.white70
            : Colors.black54,
      ),
    );
  }

  Widget _contentCard(
    bool isDark, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151515)
            : Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: isDark
              ? Colors.white12
              : Colors.black12,
        ),
      ),

      child: child,
    );
  }

  Widget _instructionCard(
    bool isDark, {
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151515)
            : Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: isDark
              ? Colors.white12
              : Colors.black12,
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white
                  : Colors.black,

              borderRadius:
                  BorderRadius.circular(15),
            ),

            child: Icon(
              icon,
              color: isDark
                  ? Colors.black
                  : Colors.white,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: isDark
                            ? Colors.white38
                            : Colors.black38,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? Colors.white60
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}