import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class Activity2Screen extends StatefulWidget {
  const Activity2Screen({super.key});

  @override
  State<Activity2Screen> createState() => _Activity2ScreenState();
}

class _Activity2ScreenState extends State<Activity2Screen> {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  List<ConnectivityResult> _connectionTypes = [
    ConnectivityResult.none,
  ];

  final List<String> _eventLog = [];

  bool _requestRunning = false;
  bool _requestQueued = false;

  int _progress = 0;

  Timer? _requestTimer;

  @override
  void initState() {
    super.initState();

    _initializeConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  Future<void> _initializeConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();

      if (!mounted) return;

      _handleConnectivityChange(result);
    } catch (e) {
      _addLog('Unable to read network status.');
    }
  }

  void _handleConnectivityChange(
    List<ConnectivityResult> result,
  ) {
    if (!mounted) return;

    setState(() {
      _connectionTypes = result;
    });

    final network = _networkName(result);

    _addLog('Network changed: $network');

    if (_hasConnection(result)) {
      if (_requestQueued && !_requestRunning) {
        _addLog(
          'Connection restored. Resuming queued request...',
        );

        _startRequest();
      }
    } else {
      if (_requestRunning) {
        _queueCurrentRequest();
      }
    }
  }

  bool _hasConnection(
    List<ConnectivityResult> result,
  ) {
    return result.any(
      (type) => type != ConnectivityResult.none,
    );
  }

  String _networkName(
    List<ConnectivityResult> result,
  ) {
    if (result.contains(ConnectivityResult.wifi)) {
      return 'WI-FI';
    }

    if (result.contains(ConnectivityResult.mobile)) {
      return 'CELLULAR';
    }

    if (result.contains(ConnectivityResult.ethernet)) {
      return 'ETHERNET';
    }

    if (result.contains(ConnectivityResult.vpn)) {
      return 'VPN';
    }

    if (result.contains(ConnectivityResult.none)) {
      return 'OFFLINE';
    }

    return 'OTHER';
  }

  IconData _networkIcon(
    List<ConnectivityResult> result,
  ) {
    if (result.contains(ConnectivityResult.wifi)) {
      return Icons.wifi;
    }

    if (result.contains(ConnectivityResult.mobile)) {
      return Icons.signal_cellular_alt;
    }

    if (result.contains(ConnectivityResult.none)) {
      return Icons.wifi_off;
    }

    return Icons.device_hub;
  }

  void _addLog(String message) {
    if (!mounted) return;

    setState(() {
      _eventLog.insert(
        0,
        '${TimeOfDay.now().format(context)}  •  $message',
      );

      if (_eventLog.length > 8) {
        _eventLog.removeLast();
      }
    });
  }

  void _startRequest() {
    if (_requestRunning) return;

    if (!_hasConnection(_connectionTypes)) {
      setState(() {
        _requestQueued = true;
      });

      _addLog(
        'No connection. Request placed in queue.',
      );

      return;
    }

    setState(() {
      _requestRunning = true;
      _requestQueued = false;
      _progress = 0;
    });

    _addLog('Large dataset request started.');

    _requestTimer?.cancel();

    _requestTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!_hasConnection(_connectionTypes)) {
          _queueCurrentRequest();
          timer.cancel();
          return;
        }

        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _progress += 10;
        });

        _addLog(
          'Downloading dataset... $_progress%',
        );

        if (_progress >= 100) {
          timer.cancel();

          setState(() {
            _requestRunning = false;
            _requestQueued = false;
          });

          _addLog(
            'Request completed successfully.',
          );
        }
      },
    );
  }

  void _queueCurrentRequest() {
    if (!_requestRunning && !_requestQueued) {
      return;
    }

    _requestTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _requestRunning = false;
      _requestQueued = true;
    });

    _addLog(
      'Connection lost. Request queued safely.',
    );
  }

  void _clearLog() {
    setState(() {
      _eventLog.clear();
    });
  }

  @override
  void dispose() {
    _requestTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final networkName = _networkName(_connectionTypes);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ACTIVITY 02',
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
                  // =========================
                  // ACTIVITY INFORMATION
                  // =========================

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
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'HANDS-ON ACTIVITY #2',
                          style: TextStyle(
                            color: isDark
                                ? Colors.black
                                : Colors.white,
                            fontSize: 28,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Active Network Monitor & Handover Handling',
                          style: TextStyle(
                            color: isDark
                                ? Colors.black87
                                : Colors.white70,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
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
                              'Due 18 Sept, 23:59',
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

                  _sectionTitle(
                    'OBJECTIVE',
                    isDark,
                  ),

                  const SizedBox(height: 10),

                  _contentCard(
                    isDark,
                    child: const Text(
                      'Build an application that monitors network '
                      'states in real-time and gracefully handles '
                      'handovers between Wi-Fi and Cellular networks '
                      'without dropping pending data requests.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  _sectionTitle(
                    'INSTRUCTIONS',
                    isDark,
                  ),

                  const SizedBox(height: 10),

                  _instructionCard(
                    isDark,
                    number: '01',
                    title: 'Activity Integration',
                    description:
                        'Add a new "Network Monitor" screen to your '
                        'existing master compilation app.',
                    icon: Icons.add_to_photos_outlined,
                  ),

                  const SizedBox(height: 12),

                  _instructionCard(
                    isDark,
                    number: '02',
                    title: 'Network Stream Listener',
                    description:
                        'Integrate a networking package such as '
                        'connectivity_plus to subscribe to real-time '
                        'network state changes.',
                    icon: Icons.sync_outlined,
                  ),

                  const SizedBox(height: 12),

                  _instructionCard(
                    isDark,
                    number: '03',
                    title: 'Real-time UI',
                    description:
                        'Design a dashboard that dynamically updates '
                        'to display the current active network interface '
                        '(Wi-Fi, Cellular, or Offline) using stream listeners.',
                    icon: Icons.dashboard_outlined,
                  ),

                  const SizedBox(height: 12),

                  _instructionCard(
                    isDark,
                    number: '04',
                    title: 'Request Queuing System',
                    description:
                        'Write logic to simulate a continuous or long-running '
                        'network request, such as fetching a large dataset. '
                        'If the connection drops during an IP migration or '
                        'handover, catch the error and queue the request instead '
                        'of crashing.',
                    icon: Icons.queue_play_next_outlined,
                  ),

                  const SizedBox(height: 12),

                  _instructionCard(
                    isDark,
                    number: '05',
                    title: 'Graceful Recovery',
                    description:
                        'Utilize connection callback streams to automatically '
                        'resume or retry queued network requests as soon as a '
                        'stable Cellular or Wi-Fi connection is re-established.',
                    icon: Icons.replay_outlined,
                  ),

                  const SizedBox(height: 25),

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
                            Icons.video_camera_back_outlined,
                            color: isDark
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),

                        const SizedBox(width: 15),

                        const Expanded(
                          child: Text(
                            'Submit the link to your updated source code '
                            'repository along with a screen recording demonstrating '
                            'the real-time UI changing during a network handover '
                            '(for example, toggling Wi-Fi off to force a switch to '
                            'Cellular) and the successful recovery of a queued request.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  // =========================
                  // LIVE NETWORK MONITOR
                  // =========================

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
                          'LIVE DEMONSTRATION',
                          style: TextStyle(
                            color: isDark
                                ? Colors.black54
                                : Colors.white70,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'NETWORK MONITOR',
                          style: TextStyle(
                            color: isDark
                                ? Colors.black
                                : Colors.white,
                            fontSize: 27,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CURRENT NETWORK
                  _monitorCard(
                    isDark,

                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,

                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white
                                : Colors.black,
                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            _networkIcon(
                              _connectionTypes,
                            ),
                            color: isDark
                                ? Colors.black
                                : Colors.white,
                            size: 42,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'CURRENT ACTIVE NETWORK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          networkName,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _hasConnection(
                            _connectionTypes,
                          )
                              ? 'Connection available'
                              : 'No active connection',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // REQUEST QUEUE
                  _monitorCard(
                    isDark,

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REQUEST QUEUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _requestRunning
                              ? 'DOWNLOADING'
                              : (_requestQueued
                                  ? 'QUEUED'
                                  : 'IDLE'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 15),

                        if (_requestRunning ||
                            _requestQueued) ...[
                          LinearProgressIndicator(
                            value:
                                _progress / 100,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Progress: $_progress%',
                          ),

                          const SizedBox(height: 15),
                        ],

                        SizedBox(
                          width: double.infinity,

                          child:
                              ElevatedButton.icon(
                            onPressed:
                                _requestRunning
                                    ? null
                                    : _startRequest,
                            icon: const Icon(
                              Icons.cloud_download_outlined,
                            ),
                            label: Text(
                              _requestQueued
                                  ? 'WAITING FOR CONNECTION'
                                  : 'START LARGE REQUEST',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // EVENT LOG
                  _monitorCard(
                    isDark,

                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'EVENT LOG',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.bold,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed: _clearLog,
                              icon: const Icon(
                                Icons.delete_outline,
                              ),
                            ),
                          ],
                        ),

                        const Divider(),

                        if (_eventLog.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.all(20),
                            child: Text(
                              'No events yet.',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                              ),
                            ),
                          )
                        else
                          ..._eventLog.map(
                            (event) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 7,
                              ),
                              child: Align(
                                alignment:
                                    Alignment.centerLeft,
                                child: Text(
                                  event,
                                  style:
                                      const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

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

  // =============================
  // REUSABLE UI COMPONENTS
  // =============================

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

        borderRadius:
            BorderRadius.circular(20),

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

        borderRadius:
            BorderRadius.circular(20),

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
                        fontWeight:
                            FontWeight.bold,
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
                          fontWeight:
                              FontWeight.bold,
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

  Widget _monitorCard(
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

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color: isDark
              ? Colors.white12
              : Colors.black12,
        ),
      ),

      child: child,
    );
  }
}