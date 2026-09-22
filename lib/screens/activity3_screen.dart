import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/network_health_provider.dart';

class Activity3Screen extends StatefulWidget {
  const Activity3Screen({super.key});

  @override
  State<Activity3Screen> createState() =>
      _Activity3ScreenState();
}

class _Activity3ScreenState
    extends State<Activity3Screen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) return;

      context
          .read<NetworkHealthProvider>()
          .startAutomaticTesting();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<NetworkHealthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ACTIVITY 3',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // HEADER
              const Text(
                '100 POINTS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'HANDS-ON ACTIVITY #3',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Dynamic Performance Throttle App',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Due Tomorrow, 23:59',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // OBJECTIVE
              const Text(
                'OBJECTIVE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Build a Flutter app containing a diagnostic tool '
                'regularly computing network speed and latency '
                '(ping) to dynamically adapt the UI from '
                'high-res multimedia to lightweight placeholders '
                'based on real-time connection health.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 30),

              // INSTRUCTIONS
              const Text(
                'INSTRUCTIONS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 15),

              _instruction(
                '1.',
                'Activity Integration',
                'Add a new "Network Diagnostic Dashboard" '
                    'screen to the existing Flutter app.',
              ),

              _instruction(
                '2.',
                'Diagnostic Tool Implementation',
                'The diagnostic tool regularly tests the network '
                    'using a multi-step sequence: baseline idle '
                    'ping, download bandwidth while concurrently '
                    'measuring ping, and upload bandwidth while '
                    'simultaneously tracking upload ping.',
              ),

              _instruction(
                '3.',
                'Threshold Logic',
                'Group network health into Excellent (>10 Mbps), '
                    'Fair (2–10 Mbps), Poor (<2 Mbps), or '
                    'Degraded when heavy packet loss or extreme '
                    'latency is detected.',
              ),

              _instruction(
                '4.',
                'Global State Injection',
                'Use Provider or Riverpod to inject categorized '
                    'network health into global app state.',
              ),

              _instruction(
                '5.',
                'Dynamic Interface',
                'Display the current network health, speed, '
                    'latency, and active connection in real time.',
              ),

              const SizedBox(height: 30),

              // DELIVERABLES
              const Text(
                'DELIVERABLES',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                '• Updated source repository link\n'
                '• Screen recording demonstrating the '
                'diagnostic tool running idle, download, '
                'and upload tests',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 35),

              // LIVE DIAGNOSTIC
              const Text(
                'LIVE DIAGNOSTIC',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'NETWORK HEALTH',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 20),

              // HEALTH CARD
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),

                  child: Column(
                    children: [

                      Icon(
                        Icons.network_check,
                        size: 60,
                      ),

                      const SizedBox(height: 15),

                      Text(
                        provider.healthLabel,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        provider.isTesting
                            ? 'Running diagnostic...'
                            : 'Current Network: '
                                '${provider.currentNetwork}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // METRICS
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,

                children: [

                  _metricCard(
                    'IDLE PING',
                    '${provider.idlePing.toStringAsFixed(1)} ms',
                    Icons.timer_outlined,
                  ),

                  _metricCard(
                    'DOWNLOAD',
                    '${provider.downloadSpeed.toStringAsFixed(2)} Mbps',
                    Icons.download,
                  ),

                  _metricCard(
                    'DOWNLOAD PING',
                    '${provider.downloadPing.toStringAsFixed(1)} ms',
                    Icons.speed,
                  ),

                  _metricCard(
                    'UPLOAD',
                    '${provider.uploadSpeed.toStringAsFixed(2)} Mbps',
                    Icons.upload,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // LATENCY DETAILS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'LATENCY DETAILS',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 15),

                      _detailRow(
                        'Idle Ping',
                        '${provider.idlePing.toStringAsFixed(1)} ms',
                      ),

                      _detailRow(
                        'Download Ping',
                        '${provider.downloadPing.toStringAsFixed(1)} ms',
                      ),

                      _detailRow(
                        'Upload Ping',
                        '${provider.uploadPing.toStringAsFixed(1)} ms',
                      ),

                      _detailRow(
                        'Active Network',
                        provider.currentNetwork,
                      ),

                      _detailRow(
                        'Upload Speed',
                        '${provider.uploadSpeed.toStringAsFixed(2)} Mbps',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // RUN DIAGNOSTIC
              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: provider.isTesting
                      ? null
                      : () {
                          provider.runDiagnostic();
                        },

                  icon: const Icon(
                    Icons.play_arrow,
                  ),

                  label: Text(
                    provider.isTesting
                        ? 'TESTING...'
                        : 'RUN DIAGNOSTIC NOW',
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // BACK
              SizedBox(
                width: double.infinity,

                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    'BACK TO HOME',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instruction(
    String number,
    String title,
    String description,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 18),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Text(
            number,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              size: 28,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [

          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}