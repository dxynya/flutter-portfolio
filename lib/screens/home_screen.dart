import 'package:flutter/material.dart';
import '../widgets/activity_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PORTFOLIO',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/settings',
              );
            },

            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide =
                constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(
                horizontal:
                    isWide ? 50 : 20,
                vertical: 20,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 1100,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      // HERO
                      Container(
                        width:
                            double.infinity,

                        padding:
                            EdgeInsets.all(
                          isWide ? 40 : 25,
                        ),

                        decoration:
                            BoxDecoration(
                          color: isDark
                              ? Colors.white
                              : Colors.black,

                          borderRadius:
                              BorderRadius.circular(
                            30,
                          ),
                        ),

                        child: isWide
                            ? Row(
                                children: [
                                  _profileIcon(
                                    isDark,
                                  ),

                                  const SizedBox(
                                    width: 30,
                                  ),

                                  Expanded(
                                    child:
                                        _heroText(
                                      isDark,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  _profileIcon(
                                    isDark,
                                  ),

                                  const SizedBox(
                                    height: 25,
                                  ),

                                  _heroText(
                                    isDark,
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(
                        height: 35,
                      ),

                      const Text(
                        'MASTER COMPILATION',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        'Laboratory Activities',
                        style: TextStyle(
                          fontSize:
                              isWide ? 30 : 25,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ACTIVITY CARDS
                      if (isWide)
                        Column(
                          children: [

                            // ROW 1
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                Expanded(
                                  child:
                                      ActivityCard(
                                    number: '01',
                                    title:
                                        'Flutter Basics',
                                    description:
                                        'Flutter Portfolio & State Management',
                                    icon:
                                        Icons.code,
                                    onTap: () {
                                      Navigator
                                          .pushNamed(
                                        context,
                                        '/activity1',
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(
                                  width: 15,
                                ),

                                Expanded(
                                  child:
                                      ActivityCard(
                                    number: '02',
                                    title:
                                        'Network Monitor',
                                    description:
                                        'Active Network Monitor & Handover Handling',
                                    icon:
                                        Icons
                                            .wifi_tethering,
                                    onTap: () {
                                      Navigator
                                          .pushNamed(
                                        context,
                                        '/activity2',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            // ROW 2
                            Row(
                              children: [

                                Expanded(
                                  child:
                                      ActivityCard(
                                    number: '03',
                                    title:
                                        'Network Diagnostic',
                                    description:
                                        'Speed, latency & connection health',
                                    icon:
                                        Icons
                                            .speed_outlined,
                                    onTap: () {
                                      Navigator
                                          .pushNamed(
                                        context,
                                        '/activity3',
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(
                                  width: 15,
                                ),

                                Expanded(
                                  child:
                                      Container(
                                    height: 180,

                                    decoration:
                                        BoxDecoration(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [

                            // ACTIVITY 1
                            ActivityCard(
                              number: '01',
                              title:
                                  'Flutter Basics',
                              description:
                                  'Flutter Portfolio & State Management',
                              icon:
                                  Icons.code,
                              onTap: () {
                                Navigator
                                    .pushNamed(
                                  context,
                                  '/activity1',
                                );
                              },
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            // ACTIVITY 2
                            ActivityCard(
                              number: '02',
                              title:
                                  'Network Monitor',
                              description:
                                  'Active Network Monitor & Handover Handling',
                              icon:
                                  Icons
                                      .wifi_tethering,
                              onTap: () {
                                Navigator
                                    .pushNamed(
                                  context,
                                  '/activity2',
                                );
                              },
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            // ACTIVITY 3
                            ActivityCard(
                              number: '03',
                              title:
                                  'Network Diagnostic',
                              description:
                                  'Speed, latency & connection health',
                              icon:
                                  Icons
                                      .speed_outlined,
                              onTap: () {
                                Navigator
                                    .pushNamed(
                                  context,
                                  '/activity3',
                                );
                              },
                            ),
                          ],
                        ),

                      const SizedBox(
                        height: 25,
                      ),

                      // RESPONSIVE INDICATOR
                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets.all(
                          18,
                        ),

                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),

                          border:
                              Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.black12,
                          ),
                        ),

                        child: Row(
                          children: [

                            Icon(
                              isWide
                                  ? Icons
                                      .desktop_windows_outlined
                                  : Icons
                                      .smartphone_outlined,
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Text(
                                isWide
                                    ? 'Responsive wide-screen layout'
                                    : 'Responsive mobile layout',

                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _profileIcon(
    bool isDark,
  ) {
    return Container(
      width: 75,
      height: 75,

      decoration:
          BoxDecoration(
        color: isDark
            ? Colors.black
            : Colors.white,

        shape: BoxShape.circle,
      ),

      child: Icon(
        Icons.person_outline,
        size: 40,

        color: isDark
            ? Colors.white
            : Colors.black,
      ),
    );
  }

  Widget _heroText(
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(
          'HELLO, WE\'RE',

          style: TextStyle(
            color: isDark
                ? Colors.black54
                : Colors.white70,

            fontSize: 12,

            fontWeight:
                FontWeight.bold,

            letterSpacing: 3,
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          'DAYANA & CAER',

          style: TextStyle(
            color: isDark
                ? Colors.black
                : Colors.white,

            fontSize: 38,

            fontWeight:
                FontWeight.w900,

            letterSpacing: 2,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          'Student at NEMSU-LC',

          style: TextStyle(
            color: isDark
                ? Colors.black54
                : Colors.white70,

            fontSize: 15,
          ),
        ),
      ],
    );
  }
}