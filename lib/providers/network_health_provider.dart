import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum NetworkHealth {
  excellent,
  fair,
  poor,
  degraded,
  testing,
  unknown,
}

class NetworkHealthProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  NetworkHealth _health = NetworkHealth.unknown;

  double _idlePing = 0;
  double _downloadSpeed = 0;
  double _downloadPing = 0;
  double _uploadSpeed = 0;
  double _uploadPing = 0;

  bool _isTesting = false;

  String _currentNetwork = 'Unknown';

  Timer? _periodicTimer;

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  NetworkHealth get health => _health;

  double get idlePing => _idlePing;

  double get downloadSpeed => _downloadSpeed;

  double get downloadPing => _downloadPing;

  double get uploadSpeed => _uploadSpeed;

  double get uploadPing => _uploadPing;

  bool get isTesting => _isTesting;

  String get currentNetwork => _currentNetwork;

  String get healthLabel {
    switch (_health) {
      case NetworkHealth.excellent:
        return 'EXCELLENT';

      case NetworkHealth.fair:
        return 'FAIR';

      case NetworkHealth.poor:
        return 'POOR';

      case NetworkHealth.degraded:
        return 'DEGRADED';

      case NetworkHealth.testing:
        return 'TESTING';

      case NetworkHealth.unknown:
        return 'UNKNOWN';
    }
  }

  NetworkHealthProvider() {
    _listenToConnectivity();
    _checkCurrentConnectivity();
  }

  void _listenToConnectivity() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
      (results) {
        _currentNetwork = _networkName(results);
        notifyListeners();
      },
    );
  }

  Future<void> _checkCurrentConnectivity() async {
    try {
      final results =
          await _connectivity.checkConnectivity();

      _currentNetwork = _networkName(results);

      notifyListeners();
    } catch (_) {
      _currentNetwork = 'Unknown';

      notifyListeners();
    }
  }

  String _networkName(
    List<ConnectivityResult> results,
  ) {
    if (results.contains(ConnectivityResult.wifi)) {
      return 'WI-FI';
    }

    if (results.contains(ConnectivityResult.mobile)) {
      return 'CELLULAR';
    }

    if (results.contains(ConnectivityResult.ethernet)) {
      return 'ETHERNET';
    }

    if (results.contains(ConnectivityResult.none)) {
      return 'OFFLINE';
    }

    return 'OTHER';
  }

  void startAutomaticTesting() {
    if (_periodicTimer != null) {
      return;
    }

    runDiagnostic();

    _periodicTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        runDiagnostic();
      },
    );
  }

  void stopAutomaticTesting() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  Future<void> runDiagnostic() async {
    if (_isTesting) {
      return;
    }

    _isTesting = true;
    _health = NetworkHealth.testing;

    notifyListeners();

    try {
      // STEP 1: IDLE PING
      _idlePing = await _measureIdlePing();

      notifyListeners();

      // STEP 2: DOWNLOAD + PING
      final downloadResult =
          await _measureDownloadWithPing();

      _downloadSpeed =
          downloadResult.speedMbps;

      _downloadPing =
          downloadResult.pingMs;

      notifyListeners();

      // STEP 3: UPLOAD + PING
      final uploadResult =
          await _measureUploadWithPing();

      _uploadSpeed =
          uploadResult.speedMbps;

      _uploadPing =
          uploadResult.pingMs;

      notifyListeners();

      // STEP 4: CLASSIFY NETWORK HEALTH
      _health = _categorizeHealth(
        downloadSpeed: _downloadSpeed,
        uploadSpeed: _uploadSpeed,
        idlePing: _idlePing,
        downloadPing: _downloadPing,
        uploadPing: _uploadPing,
      );
    } catch (_) {
      _health = NetworkHealth.degraded;
    }

    _isTesting = false;

    notifyListeners();
  }

  Future<double> _measureIdlePing() async {
    const int samples = 2;

    final values = <double>[];

    for (int i = 0; i < samples; i++) {
      final stopwatch = Stopwatch()..start();

      try {
        final response = await http.get(
          Uri.parse(
            'https://www.cloudflare.com/cdn-cgi/trace',
          ),
        );

        stopwatch.stop();

        if (response.statusCode == 200) {
          values.add(
            stopwatch.elapsedMicroseconds / 1000,
          );
        }
      } catch (_) {
        stopwatch.stop();
      }

      await Future.delayed(
        const Duration(milliseconds: 250),
      );
    }

    if (values.isEmpty) {
      throw Exception('Ping test failed');
    }

    return values.reduce((a, b) => a + b) /
        values.length;
  }

  Future<_PhaseResult>
      _measureDownloadWithPing() async {
    final pingSamples = <double>[];

    final pingTask =
        _collectConcurrentPings(
      pingSamples,
    );

    final stopwatch = Stopwatch()..start();

    final response = await http.get(
      Uri.parse(
        'https://speed.cloudflare.com/__down?bytes=1000000',
      ),
    );

    stopwatch.stop();

    if (response.statusCode != 200) {
      throw Exception(
        'Download test failed',
      );
    }

    final bytes =
        response.bodyBytes.length;

    final seconds =
        stopwatch.elapsedMicroseconds /
            1000000;

    if (seconds <= 0) {
      throw Exception(
        'Invalid download time',
      );
    }

    final speedMbps =
        (bytes * 8) /
            seconds /
            1000000;

    await pingTask;

    final ping =
        _averagePing(pingSamples);

    return _PhaseResult(
      speedMbps: speedMbps,
      pingMs: ping,
    );
  }

  Future<_PhaseResult>
      _measureUploadWithPing() async {
    final pingSamples = <double>[];

    final pingTask =
        _collectConcurrentPings(
      pingSamples,
    );

    const int uploadBytes = 500000;

    // List<int> is enough for the HTTP upload body.
    final data = List<int>.filled(
      uploadBytes,
      0,
    );

    final stopwatch = Stopwatch()..start();

    final response = await http.post(
      Uri.parse(
        'https://speed.cloudflare.com/__up',
      ),
      headers: {
        'Content-Type':
            'application/octet-stream',
      },
      body: data,
    );

    stopwatch.stop();

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Upload test failed',
      );
    }

    final seconds =
        stopwatch.elapsedMicroseconds /
            1000000;

    if (seconds <= 0) {
      throw Exception(
        'Invalid upload time',
      );
    }

    final speedMbps =
        (uploadBytes * 8) /
            seconds /
            1000000;

    await pingTask;

    final ping =
        _averagePing(pingSamples);

    return _PhaseResult(
      speedMbps: speedMbps,
      pingMs: ping,
    );
  }

  Future<void>
      _collectConcurrentPings(
    List<double> values,
  ) async {
    for (int i = 0; i < 5; i++) {
      final stopwatch = Stopwatch()..start();

      try {
        final response = await http.get(
          Uri.parse(
            'https://www.cloudflare.com/cdn-cgi/trace',
          ),
        );

        stopwatch.stop();

        if (response.statusCode == 200) {
          values.add(
            stopwatch.elapsedMicroseconds /
                1000,
          );
        }
      } catch (_) {
        stopwatch.stop();
      }

      await Future.delayed(
        const Duration(milliseconds: 300),
      );
    }
  }

  double _averagePing(
    List<double> values,
  ) {
    if (values.isEmpty) {
      return 0;
    }

    return values.reduce((a, b) => a + b) /
        values.length;
  }

  NetworkHealth _categorizeHealth({
    required double downloadSpeed,
    required double uploadSpeed,
    required double idlePing,
    required double downloadPing,
    required double uploadPing,
  }) {
    final averageSpeed =
        (downloadSpeed + uploadSpeed) / 2;

    final averagePing =
        (idlePing +
                downloadPing +
                uploadPing) /
            3;

    // Degraded: extremely high latency
    // or no usable speed.
    if (averagePing >= 500 ||
        averageSpeed <= 0) {
      return NetworkHealth.degraded;
    }

    // Excellent: above 10 Mbps.
    if (averageSpeed > 10) {
      return NetworkHealth.excellent;
    }

    // Fair: 2 to 10 Mbps.
    if (averageSpeed >= 2 &&
        averageSpeed <= 10) {
      return NetworkHealth.fair;
    }

    // Poor: below 2 Mbps.
    return NetworkHealth.poor;
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();

    _connectivitySubscription?.cancel();

    super.dispose();
  }
}

class _PhaseResult {
  final double speedMbps;

  final double pingMs;

  const _PhaseResult({
    required this.speedMbps,
    required this.pingMs,
  });
}