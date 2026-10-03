import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

/// ===============================================================
/// ACTIVITY 4 - LOCAL MESH CHAT
/// ===============================================================
///
/// Core functions:
/// - Nearby device discovery
/// - Advertising + scanning
/// - P2P_CLUSTER mesh
/// - UID tie-break to avoid duplicate connection requests
/// - Authentication token during handshake
/// - JSON byte payloads
/// - Unique message IDs
/// - TTL-based multi-hop relay
/// - Duplicate-message prevention
/// - GPS location sharing
/// - Distance/proximity display
/// - Chat UI
///
/// GPS is used for proximity/distance display.
/// Nearby Connections is used for the actual offline messaging.
/// ===============================================================

enum PeerStatus {
  discovered,
  connecting,
  connected,
}

class Peer {
  Peer({
    required this.endpointId,
    required this.displayName,
    required this.uid,
  });

  final String endpointId;
  final String displayName;
  final String uid;

  PeerStatus status = PeerStatus.discovered;
}

class PeerLocation {
  PeerLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.originUid,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMine,
  });

  final String id;
  final String originUid;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMine;

  bool get isSystem => originUid == 'system';
}

// ===============================================================
// MESH CONTROLLER
// ===============================================================

class MeshChatController extends ChangeNotifier {
  MeshChatController({
    required this.userName,
  })  : uid = _randomId(),
        _nearby = Nearby();

  static const String serviceId =
      'com.example.activity4_local_mesh';

  static const Strategy strategy =
      Strategy.P2P_CLUSTER;

  static const int defaultTtl = 4;

  static const double nearbyDistanceMeters = 100.0;

  final String userName;
  final String uid;
  final Nearby _nearby;

  bool isAdvertising = false;
  bool isDiscovering = false;

  String? error;

  final Map<String, Peer> _peers = {};
  final List<ChatMessage> _messages = [];

  /// Prevents duplicate processing of messages.
  final Set<String> _seenIds = {};

  /// Authentication token shown during connection.
  final Map<String, String> _authTokens = {};

  /// GPS coordinates received from connected peers.
  final Map<String, PeerLocation> _peerLocations = {};

  Position? myPosition;

  Timer? _locationTimer;

  bool locationReady = false;

  List<Peer> get peers {
    final list = _peers.values.toList();

    list.sort(
      (a, b) => a.displayName
          .toLowerCase()
          .compareTo(
            b.displayName.toLowerCase(),
          ),
    );

    return list;
  }

  List<ChatMessage> get messages =>
      List.unmodifiable(_messages);

  Iterable<Peer> get connectedPeers =>
      _peers.values.where(
        (peer) => peer.status == PeerStatus.connected,
      );

  bool get isRunning =>
      isAdvertising || isDiscovering;

  String? authTokenFor(String endpointId) =>
      _authTokens[endpointId];

  PeerLocation? locationFor(String endpointId) =>
      _peerLocations[endpointId];

  String get wireName => '$userName|$uid';

  String get statusText {
    if (error != null) {
      return error!;
    }

    if (!isRunning) {
      return 'Offline • Mesh not started';
    }

    return '${isAdvertising ? "Visible" : "Hidden"} • '
        '${isDiscovering ? "Scanning" : "Idle"} • '
        '${connectedPeers.length} connected';
  }

  // ===============================================================
  // RANDOM UID
  // ===============================================================

  static String _randomId() {
    final random = Random.secure();

    return List.generate(
      8,
      (_) => random
          .nextInt(16)
          .toRadixString(16),
    ).join();
  }

  // ===============================================================
  // ERROR
  // ===============================================================

  void _setError(String? message) {
    error = message;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  // ===============================================================
  // PERMISSIONS
  // ===============================================================

  Future<bool> ensurePermissions() async {
    try {
      final bluetoothScan =
          await Permission.bluetoothScan.request();

      final bluetoothConnect =
          await Permission.bluetoothConnect.request();

      final bluetoothAdvertise =
          await Permission.bluetoothAdvertise.request();

      final location =
          await Permission.location.request();

      final nearbyWifi =
          await Permission.nearbyWifiDevices.request();

      final bluetoothOkay =
          bluetoothScan.isGranted &&
          bluetoothConnect.isGranted &&
          bluetoothAdvertise.isGranted;

      final locationOkay =
          location.isGranted;

      final wifiOkay =
          nearbyWifi.isGranted ||
          nearbyWifi.isLimited ||
          await _safeNearbyWifiPermissionCheck();

      if (!bluetoothOkay) {
        _setError(
          'Bluetooth permissions are required '
          'for nearby discovery.',
        );
        return false;
      }

      if (!locationOkay) {
        _setError(
          'Location permission is required '
          'for device discovery and GPS.',
        );
        return false;
      }

      if (!wifiOkay) {
        _setError(
          'Nearby Wi-Fi permission is required '
          'for local connections.',
        );
        return false;
      }

      final locationPrepared =
          await prepareLocation();

      if (!locationPrepared) {
        return false;
      }

      final bluetoothEnabled =
          await Permission.bluetooth
              .serviceStatus
              .isEnabled;

      if (!bluetoothEnabled) {
        _setError(
          'Please turn ON Bluetooth, '
          'then try again.',
        );
        return false;
      }

      return true;
    } catch (e) {
      _setError(
        'Permission error: $e',
      );
      return false;
    }
  }

  Future<bool>
      _safeNearbyWifiPermissionCheck() async {
    try {
      return await Permission
          .nearbyWifiDevices
          .isGranted;
    } catch (_) {
      return true;
    }
  }

  // ===============================================================
  // GPS
  // ===============================================================

  Future<bool> prepareLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        locationReady = false;

        _setError(
          'Location/GPS is OFF. '
          'Please turn it ON.',
        );

        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.denied) {
        locationReady = false;

        _setError(
          'Location permission was denied.',
        );

        return false;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        locationReady = false;

        _setError(
          'Location permission is permanently '
          'denied. Please enable it in Settings.',
        );

        return false;
      }

      locationReady = true;

      return true;
    } catch (e) {
      locationReady = false;

      _setError(
        'Unable to prepare GPS: $e',
      );

      return false;
    }
  }

  Future<void> updateMyLocation() async {
    if (!locationReady) {
      return;
    }

    try {
      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      myPosition = position;

      await sendMyLocationToPeers();

      notifyListeners();
    } catch (_) {
      // GPS can temporarily fail.
      // Keep the mesh running.
    }
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();

    _locationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) async {
        await updateMyLocation();
      },
    );
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  // ===============================================================
  // START MESH
  // ===============================================================

  Future<void> start() async {
    if (isRunning) {
      return;
    }

    final permissionsOkay =
        await ensurePermissions();

    if (!permissionsOkay) {
      return;
    }

    error = null;

    try {
      await updateMyLocation();

      isAdvertising =
          await _nearby.startAdvertising(
        wireName,
        strategy,
        serviceId: serviceId,
        onConnectionInitiated:
            _onConnectionInitiated,
        onConnectionResult:
            _onConnectionResult,
        onDisconnected:
            _onDisconnected,
      );

      isDiscovering =
          await _nearby.startDiscovery(
        wireName,
        strategy,
        serviceId: serviceId,
        onEndpointFound:
            _onEndpointFound,
        onEndpointLost:
            _onEndpointLost,
      );

      _startLocationUpdates();

      notifyListeners();
    } catch (e) {
      isAdvertising = false;
      isDiscovering = false;

      _setError(
        'Could not start mesh: $e',
      );
    }
  }

  // ===============================================================
  // STOP MESH
  // ===============================================================

  Future<void> stop() async {
    try {
      await _nearby.stopAdvertising();
      await _nearby.stopDiscovery();
      await _nearby.stopAllEndpoints();
    } catch (_) {}

    _stopLocationUpdates();

    isAdvertising = false;
    isDiscovering = false;

    _peers.clear();
    _authTokens.clear();
    _peerLocations.clear();

    notifyListeners();
  }

  // ===============================================================
  // DISCOVERY
  // ===============================================================

  void _onEndpointFound(
    String endpointId,
    String endpointName,
    String foundServiceId,
  ) {
    final parts =
        endpointName.split('|');

    final displayName =
        parts.isNotEmpty &&
                parts.first.trim().isNotEmpty
            ? parts.first.trim()
            : 'Unknown device';

    final peerUid =
        parts.length > 1 &&
                parts[1].trim().isNotEmpty
            ? parts[1].trim()
            : endpointId;

    if (!_peers.containsKey(endpointId)) {
      _peers[endpointId] = Peer(
        endpointId: endpointId,
        displayName: displayName,
        uid: peerUid,
      );
    }

    notifyListeners();

    // Only the device with the smaller UID
    // automatically initiates the connection.
    if (uid.compareTo(peerUid) < 0) {
      unawaited(
        connectTo(endpointId),
      );
    }
  }

  void _onEndpointLost(
    String? endpointId,
  ) {
    if (endpointId == null) {
      return;
    }

    final peer = _peers[endpointId];

    if (peer != null &&
        peer.status !=
            PeerStatus.connected) {
      _peers.remove(endpointId);
      _peerLocations.remove(endpointId);

      notifyListeners();
    }
  }

  // ===============================================================
  // MANUAL CONNECTION
  // ===============================================================

  Future<void> connectTo(
    String endpointId,
  ) async {
    final peer = _peers[endpointId];

    if (peer == null) {
      return;
    }

    if (peer.status !=
        PeerStatus.discovered) {
      return;
    }

    peer.status =
        PeerStatus.connecting;

    error = null;

    notifyListeners();

    try {
      await _nearby.requestConnection(
        wireName,
        endpointId,
        onConnectionInitiated:
            _onConnectionInitiated,
        onConnectionResult:
            _onConnectionResult,
        onDisconnected:
            _onDisconnected,
      );
    } catch (e) {
      peer.status =
          PeerStatus.discovered;

      _setError(
        'Connection request failed: $e',
      );
    }
  }

  // ===============================================================
  // CONNECTION HANDSHAKE
  // ===============================================================

  void _onConnectionInitiated(
    String endpointId,
    ConnectionInfo info,
  ) {
    final parts =
        info.endpointName.split('|');

    final displayName =
        parts.isNotEmpty &&
                parts.first.trim().isNotEmpty
            ? parts.first.trim()
            : 'Unknown device';

    final peerUid =
        parts.length > 1 &&
                parts[1].trim().isNotEmpty
            ? parts[1].trim()
            : endpointId;

    _peers.putIfAbsent(
      endpointId,
      () => Peer(
        endpointId: endpointId,
        displayName: displayName,
        uid: peerUid,
      ),
    );

    _peers[endpointId]!.status =
        PeerStatus.connecting;

    // Correct property for the installed
    // nearby_connections API.
    _authTokens[endpointId] =
        info.authenticationToken;

    notifyListeners();

    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved:
          _onPayloadReceived,
      onPayloadTransferUpdate:
          (
        String endpointId,
        PayloadTransferUpdate update,
      ) {},
    );
  }

  // ===============================================================
  // CONNECTION RESULT
  // ===============================================================

  void _onConnectionResult(
    String endpointId,
    Status status,
  ) {
    final peer = _peers[endpointId];

    if (peer == null) {
      return;
    }

    if (status == Status.CONNECTED) {
      peer.status =
          PeerStatus.connected;

      _authTokens.remove(endpointId);

      _addSystem(
        '${peer.displayName} joined the mesh.',
      );

      notifyListeners();

      unawaited(
        _sendMyLocationToPeer(
          endpointId,
        ),
      );

      Future.delayed(
        const Duration(
          milliseconds: 800,
        ),
        () {
          unawaited(
            _sendMyLocationToPeer(
              endpointId,
            ),
          );
        },
      );
    } else {
      peer.status =
          PeerStatus.discovered;

      _authTokens.remove(endpointId);

      if (status == Status.REJECTED ||
          status == Status.ERROR) {
        _setError(
          'Connection with '
          '${peer.displayName} failed.',
        );

        return;
      }

      notifyListeners();
    }
  }

  // ===============================================================
  // DISCONNECTED
  // ===============================================================

  void _onDisconnected(
    String endpointId,
  ) {
    final peer =
        _peers.remove(endpointId);

    _authTokens.remove(endpointId);
    _peerLocations.remove(endpointId);

    if (peer != null) {
      _addSystem(
        '${peer.displayName} left the mesh.',
      );
    }

    notifyListeners();
  }

  // ===============================================================
  // GPS PAYLOAD
  // ===============================================================

  Future<void>
      _sendMyLocationToPeer(
    String endpointId,
  ) async {
    final position = myPosition;

    if (position == null) {
      return;
    }

    final envelope = <String, dynamic>{
      'type': 'location',
      'sender': uid,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'time':
          DateTime.now().toIso8601String(),
    };

    final bytes =
        Uint8List.fromList(
      utf8.encode(
        jsonEncode(envelope),
      ),
    );

    try {
      await _nearby.sendBytesPayload(
        endpointId,
        bytes,
      );
    } catch (_) {}
  }

  Future<void>
      sendMyLocationToPeers() async {
    if (myPosition == null) {
      return;
    }

    final peers =
        connectedPeers.toList();

    for (final peer in peers) {
      await _sendMyLocationToPeer(
        peer.endpointId,
      );
    }
  }

  // ===============================================================
  // DISTANCE
  // ===============================================================

  double? getDistanceToPeer(
    String endpointId,
  ) {
    final currentPosition =
        myPosition;

    final peerPosition =
        _peerLocations[endpointId];

    if (currentPosition == null ||
        peerPosition == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      peerPosition.latitude,
      peerPosition.longitude,
    );
  }

  bool isPeerNearby(
    String endpointId,
  ) {
    final distance =
        getDistanceToPeer(
      endpointId,
    );

    if (distance == null) {
      return false;
    }

    return distance <=
        nearbyDistanceMeters;
  }

  String distanceText(
    String endpointId,
  ) {
    final distance =
        getDistanceToPeer(
      endpointId,
    );

    if (distance == null) {
      return 'Distance unavailable';
    }

    if (distance < 1000) {
      return '${distance.toStringAsFixed(1)} m';
    }

    return '${(distance / 1000).toStringAsFixed(2)} km';
  }

  // ===============================================================
  // SEND CHAT MESSAGE
  // ===============================================================

  Future<void> sendMessage(
    String text,
  ) async {
    final trimmed =
        text.trim();

    if (trimmed.isEmpty) {
      return;
    }

    if (connectedPeers.isEmpty) {
      _setError(
        'Connect to at least one device '
        'before sending a message.',
      );

      return;
    }

    final messageId =
        '$uid-${DateTime.now().microsecondsSinceEpoch}';

    _seenIds.add(messageId);

    final now =
        DateTime.now();

    _messages.add(
      ChatMessage(
        id: messageId,
        originUid: uid,
        senderName: userName,
        text: trimmed,
        timestamp: now,
        isMine: true,
      ),
    );

    notifyListeners();

    await _broadcast(
      <String, dynamic>{
        'type': 'chat',
        'id': messageId,
        'origin': uid,
        'name': userName,
        'text': trimmed,
        'ttl': defaultTtl,
      },
    );
  }

  // ===============================================================
  // BROADCAST
  // ===============================================================

  Future<void> _broadcast(
    Map<String, dynamic> envelope, {
    String? exceptId,
  }) async {
    final bytes =
        Uint8List.fromList(
      utf8.encode(
        jsonEncode(envelope),
      ),
    );

    final peers =
        connectedPeers.toList();

    for (final peer in peers) {
      if (peer.endpointId ==
          exceptId) {
        continue;
      }

      try {
        await _nearby.sendBytesPayload(
          peer.endpointId,
          bytes,
        );
      } catch (_) {
        _setError(
          'Send to ${peer.displayName} failed.',
        );
      }
    }
  }

  // ===============================================================
  // RECEIVE PAYLOAD
  // ===============================================================

  void _onPayloadReceived(
    String fromId,
    Payload payload,
  ) {
    if (payload.type !=
        PayloadType.BYTES) {
      return;
    }

    final data =
        payload.bytes;

    if (data == null) {
      return;
    }

    try {
      final decoded =
          jsonDecode(
        utf8.decode(data),
      ) as Map<String, dynamic>;

      final type =
          decoded['type'];

      // -----------------------------------------------------------
      // LOCATION
      // -----------------------------------------------------------

      if (type == 'location') {
        final latitude =
            (decoded['latitude']
                    as num?)
                ?.toDouble();

        final longitude =
            (decoded['longitude']
                    as num?)
                ?.toDouble();

        if (latitude == null ||
            longitude == null) {
          return;
        }

        _peerLocations[fromId] =
            PeerLocation(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
        );

        notifyListeners();

        return;
      }

      // -----------------------------------------------------------
      // CHAT
      // -----------------------------------------------------------

      if (type == 'chat' ||
          type == null) {
        final id =
            decoded['id'] as String?;

        if (id == null ||
            id.isEmpty) {
          return;
        }

        // Ignore duplicates.
        if (!_seenIds.add(id)) {
          return;
        }

        final origin =
            decoded['origin']
                    as String? ??
                '';

        final senderName =
            decoded['name']
                    as String? ??
                'Unknown';

        final message =
            decoded['text']
                    as String? ??
                '';

        final ttl =
            (decoded['ttl']
                        as num?)
                    ?.toInt() ??
                0;

        if (message.isEmpty) {
          return;
        }

        _messages.add(
          ChatMessage(
            id: id,
            originUid: origin,
            senderName: senderName,
            text: message,
            timestamp:
                DateTime.now(),
            isMine: false,
          ),
        );

        notifyListeners();

        // ---------------------------------------------------------
        // MULTI-HOP RELAY
        //
        // Example:
        //
        // A → B → C
        //
        // B receives A's message and
        // forwards it to C.
        // ---------------------------------------------------------

        if (ttl > 0) {
          decoded['ttl'] =
              ttl - 1;

          unawaited(
            _broadcast(
              decoded,
              exceptId: fromId,
            ),
          );
        }
      }
    } catch (_) {
      // Ignore malformed payloads.
    }
  }

  // ===============================================================
  // SYSTEM MESSAGE
  // ===============================================================

  void _addSystem(
    String text,
  ) {
    _messages.add(
      ChatMessage(
        id:
            'system-${DateTime.now().microsecondsSinceEpoch}',
        originUid: 'system',
        senderName: 'system',
        text: text,
        timestamp: DateTime.now(),
        isMine: false,
      ),
    );

    notifyListeners();
  }

  // ===============================================================
  // DISPOSE
  // ===============================================================

  @override
  void dispose() {
    _stopLocationUpdates();

    unawaited(
      _nearby.stopAdvertising(),
    );

    unawaited(
      _nearby.stopDiscovery(),
    );

    unawaited(
      _nearby.stopAllEndpoints(),
    );

    super.dispose();
  }
}

// ===============================================================
// ACTIVITY 4 SCREEN
// ===============================================================

class Activity4Screen
    extends StatefulWidget {
  const Activity4Screen({
    super.key,
  });

  @override
  State<Activity4Screen>
      createState() =>
          _Activity4ScreenState();
}

class _Activity4ScreenState
    extends State<Activity4Screen> {
  final TextEditingController
      _nameController =
      TextEditingController();

  final TextEditingController
      _messageController =
      TextEditingController();

  final ScrollController
      _chatScrollController =
      ScrollController();

  MeshChatController? _controller;

  bool _nameLocked = false;

  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();

    _nameController.text =
        'My Device';
  }

  @override
  void dispose() {
    _controller?.dispose();

    _nameController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();

    super.dispose();
  }

  // ===============================================================
  // CREATE CONTROLLER
  // ===============================================================

  void _createController() {
    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        'Please enter your device name first.',
      );
      return;
    }

    final safeName =
        name.replaceAll('|', '');

    if (_controller != null) {
      return;
    }

    final controller =
        MeshChatController(
      userName: safeName,
    );

    controller.addListener(
      _controllerChanged,
    );

    setState(() {
      _controller =
          controller;
      _nameLocked = true;
    });
  }

  void _controllerChanged() {
    final controller =
        _controller;

    if (controller == null) {
      return;
    }

    if (controller.messages.length !=
        _lastMessageCount) {
      _lastMessageCount =
          controller.messages.length;

      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          if (!_chatScrollController
              .hasClients) {
            return;
          }

          _chatScrollController
              .animateTo(
            _chatScrollController
                .position
                .maxScrollExtent,
            duration:
                const Duration(
              milliseconds: 220,
            ),
            curve:
                Curves.easeOut,
          );
        },
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ===============================================================
  // START
  // ===============================================================

  Future<void> _startMesh() async {
    if (_controller == null) {
      _createController();
    }

    final controller =
        _controller;

    if (controller == null) {
      return;
    }

    await controller.start();

    if (mounted) {
      setState(() {});
    }
  }

  // ===============================================================
  // STOP
  // ===============================================================

  Future<void> _stopMesh() async {
    final controller =
        _controller;

    if (controller == null) {
      return;
    }

    await controller.stop();

    if (mounted) {
      setState(() {});
    }
  }

  // ===============================================================
  // SEND
  // ===============================================================

  Future<void> _sendMessage() async {
    final controller =
        _controller;

    if (controller == null) {
      return;
    }

    final text =
        _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    await controller.sendMessage(
      text,
    );

    _messageController.clear();

    if (mounted) {
      setState(() {});
    }
  }

  // ===============================================================
  // MESSAGE
  // ===============================================================

  void _showMessage(
    String text,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }

  // ===============================================================
  // THEME HELPERS
  // ===============================================================

  Color _surface(
    BuildContext context,
  ) {
    return Theme.of(context)
        .colorScheme
        .surface;
  }

  Color _surfaceContainer(
    BuildContext context,
  ) {
    return Theme.of(context)
        .colorScheme
        .surfaceContainerHighest;
  }

  Color _alpha(
    Color color,
    double alpha,
  ) {
    return color.withValues(
      alpha: alpha,
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    final controller =
        _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Local Mesh Chat',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (controller != null)
            IconButton(
              tooltip:
                  controller.isRunning
                      ? 'Stop mesh'
                      : 'Start mesh',
              onPressed:
                  controller.isRunning
                      ? _stopMesh
                      : _startMesh,
              icon: Icon(
                controller.isRunning
                    ? Icons
                        .wifi_tethering_off_rounded
                    : Icons
                        .wifi_tethering_rounded,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildActivityHeader(
              context,
            ),
            Expanded(
              child: controller ==
                      null
                  ? _buildSetupSection(
                      context,
                    )
                  : _buildMeshSection(
                      context,
                      controller,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // HEADER
  // ===============================================================

  Widget _buildActivityHeader(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    return Container(
      width:
          double.infinity,
      margin:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        gradient:
            LinearGradient(
          colors: [
            _alpha(
              scheme.primary,
              0.22,
            ),
            _alpha(
              scheme.secondary,
              0.12,
            ),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        border: Border.all(
          color: _alpha(
            scheme.primary,
            0.22,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color: _alpha(
                    scheme.primary,
                    0.18,
                  ),
                ),
                child: Icon(
                  Icons
                      .hub_rounded,
                  color:
                      scheme.primary,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Hands-on Activity 4',
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            'Serverless Local Chat App',
            style: theme
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            'Discover nearby Android devices, '
            'connect locally, share GPS proximity, '
            'and exchange chat messages without '
            'internet or a central server.',
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
              color: _alpha(
                theme
                    .textTheme
                    .bodyMedium
                    ?.color ??
                    Colors.white,
                0.72,
              ),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SETUP
  // ===============================================================

  Widget _buildSetupSection(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        28,
      ),
      child: Column(
        children: [
          _buildInstructionCard(
            context,
            icon:
                Icons.phone_android_rounded,
            title:
                'Two Android phones',
            text:
                'Install the same APK on both phones. '
                'Each phone should use a different device name.',
          ),
          const SizedBox(
            height: 12,
          ),
          _buildInstructionCard(
            context,
            icon:
                Icons.location_on_rounded,
            title:
                'Turn on GPS',
            text:
                'Location services are used to calculate '
                'the distance between connected devices.',
          ),
          const SizedBox(
            height: 12,
          ),
          _buildInstructionCard(
            context,
            icon:
                Icons.wifi_tethering_rounded,
            title:
                'Start the mesh',
            text:
                'Both phones advertise themselves and scan '
                'for nearby peers using the local connection.',
          ),
          const SizedBox(
            height: 20,
          ),
          Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              'DEVICE NAME',
              style: theme
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                letterSpacing: 1.2,
                fontWeight:
                    FontWeight.w800,
                color:
                    scheme.primary,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          TextField(
            controller:
                _nameController,
            enabled:
                !_nameLocked,
            maxLength: 20,
            textInputAction:
                TextInputAction.done,
            decoration:
                InputDecoration(
              hintText:
                  'Enter your device name',
              prefixIcon:
                  const Icon(
                Icons
                    .person_outline_rounded,
              ),
              suffixIcon:
                  _nameLocked
                      ? const Icon(
                          Icons
                              .lock_outline_rounded,
                        )
                      : null,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          SizedBox(
            width:
                double.infinity,
            height: 54,
            child:
                FilledButton.icon(
              onPressed:
                  _startMesh,
              icon:
                  const Icon(
                Icons
                    .wifi_tethering_rounded,
              ),
              label:
                  const Text(
                'START LOCAL MESH',
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
              16,
            ),
            decoration:
                BoxDecoration(
              color:
                  _surface(
                context,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border:
                  Border.all(
                color: _alpha(
                  scheme.outline,
                  0.18,
                ),
              ),
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons
                          .info_outline_rounded,
                      color:
                          scheme.secondary,
                    ),
                    const SizedBox(
                      width: 9,
                    ),
                    Text(
                      'Expected demo',
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'Phone A → discover Phone B → '
                  'connect → handshake → GPS distance → '
                  'send a chat message.',
                  style: theme
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // MESH SECTION
  // ===============================================================

  Widget _buildMeshSection(
    BuildContext context,
    MeshChatController controller,
  ) {
    return Column(
      children: [
        _buildStatusBanner(
          context,
          controller,
        ),
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16,
            ),
            children: [
              _buildMyDeviceCard(
                context,
                controller,
              ),
              const SizedBox(
                height: 12,
              ),
              _buildNearbyCard(
                context,
                controller,
              ),
              if (controller
                  .connectedPeers
                  .isNotEmpty)
                const SizedBox(
                  height: 12,
                ),
              if (controller
                  .connectedPeers
                  .isNotEmpty)
                _buildConnectedCard(
                  context,
                  controller,
                ),
              const SizedBox(
                height: 12,
              ),
              _buildChatCard(
                context,
                controller,
              ),
            ],
          ),
        ),
        _buildComposer(
          context,
          controller,
        ),
      ],
    );
  }

  // ===============================================================
  // STATUS BANNER
  // ===============================================================

  Widget _buildStatusBanner(
    BuildContext context,
    MeshChatController controller,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    final hasError =
        controller.error != null;

    final dotColor =
        hasError
            ? scheme.error
            : controller.isRunning
                ? Colors.greenAccent
                : scheme.outline;

    return Container(
      width:
          double.infinity,
      margin:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        0,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color:
            hasError
                ? _alpha(
                    scheme.error,
                    0.10,
                  )
                : _surface(
                    context,
                  ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              hasError
                  ? _alpha(
                      scheme.error,
                      0.25,
                    )
                  : _alpha(
                      scheme.outline,
                      0.15,
                    ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(
              color:
                  dotColor,
              shape:
                  BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      _alpha(
                    dotColor,
                    0.45,
                  ),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              controller.statusText,
              style: theme
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color:
                    hasError
                        ? scheme.error
                        : null,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
          if (hasError)
            IconButton(
              onPressed:
                  controller.clearError,
              icon:
                  Icon(
                Icons.close_rounded,
                size: 18,
                color:
                    scheme.error,
              ),
              visualDensity:
                  VisualDensity
                      .compact,
            ),
        ],
      ),
    );
  }

  // ===============================================================
  // MY DEVICE
  // ===============================================================

  Widget _buildMyDeviceCard(
    BuildContext context,
    MeshChatController controller,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    final position =
        controller.myPosition;

    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            _surface(context),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color: _alpha(
            scheme.primary,
            0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    _alpha(
                  scheme.primary,
                  0.15,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color:
                      scheme.primary,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.userName,
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    Text(
                      controller.isRunning
                          ? 'Broadcasting presence'
                          : 'Mesh stopped',
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color:
                            _alpha(
                          theme
                                  .textTheme
                                  .bodySmall
                                  ?.color ??
                              Colors.white,
                          0.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                controller.isRunning
                    ? Icons
                        .public_rounded
                    : Icons
                        .public_off_rounded,
                color:
                    controller.isRunning
                        ? Colors.greenAccent
                        : scheme.outline,
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
              12,
            ),
            decoration:
                BoxDecoration(
              color:
                  _alpha(
                _surfaceContainer(
                  context,
                ),
                0.45,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child:
                Row(
              children: [
                Icon(
                  Icons
                      .location_on_rounded,
                  size: 20,
                  color:
                      controller
                              .locationReady
                          ? Colors
                              .greenAccent
                          : scheme
                              .error,
                ),
                const SizedBox(
                  width: 9,
                ),
                Expanded(
                  child: Text(
                    controller
                            .locationReady
                        ? position == null
                            ? 'GPS ready • '
                                'waiting for position'
                            : 'GPS ready • '
                                '${position.latitude.toStringAsFixed(5)}, '
                                '${position.longitude.toStringAsFixed(5)}'
                        : 'GPS unavailable',
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // NEARBY DEVICES
  // ===============================================================

  Widget _buildNearbyCard(
    BuildContext context,
    MeshChatController controller,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    final peers =
        controller.peers;

    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            _surface(context),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color: _alpha(
            scheme.outline,
            0.15,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons
                    .radar_rounded,
                color:
                    scheme.secondary,
              ),
              const SizedBox(
                width: 9,
              ),
              Expanded(
                child: Text(
                  'Nearby Devices',
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color: _alpha(
                    scheme.primary,
                    0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child:
                    Text(
                  '${peers.length}',
                  style: theme
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                    color:
                        scheme.primary,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          if (peers.isEmpty)
            _buildEmptyPeerState(
              context,
              controller,
            )
          else
            ...peers.map(
              (peer) =>
                  _buildPeerTile(
                context,
                controller,
                peer,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPeerState(
    BuildContext context,
    MeshChatController controller,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: 16,
      ),
      child:
          Column(
        children: [
          Icon(
            controller.isRunning
                ? Icons
                    .radar_rounded
                : Icons
                    .devices_other_rounded,
            size: 48,
            color: _alpha(
              scheme.primary,
              0.55,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            controller.isRunning
                ? 'Scanning for nearby devices...'
                : 'Start the mesh to discover devices.',
            textAlign:
                TextAlign.center,
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // PEER TILE
  // ===============================================================

  Widget _buildPeerTile(
    BuildContext context,
    MeshChatController controller,
    Peer peer,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    final isConnected =
        peer.status ==
            PeerStatus.connected;

    final isConnecting =
        peer.status ==
            PeerStatus.connecting;

    final nearby =
        controller.isPeerNearby(
      peer.endpointId,
    );

    late final Color statusColor;
    late final IconData icon;

    if (isConnected) {
      statusColor =
          Colors.greenAccent;
      icon =
          Icons.check_circle_rounded;
    } else if (isConnecting) {
      statusColor =
          scheme.secondary;
      icon =
          Icons.sync_rounded;
    } else {
      statusColor =
          scheme.primary;
      icon =
          Icons.radar_rounded;
    }

    final authToken =
        controller.authTokenFor(
      peer.endpointId,
    );

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 9,
      ),
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color: _alpha(
          _surfaceContainer(
            context,
          ),
          0.45,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color: _alpha(
            statusColor,
            0.18,
          ),
        ),
      ),
      child:
          Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    _alpha(
                  statusColor,
                  0.12,
                ),
                child: Icon(
                  icon,
                  color:
                      statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      peer.displayName,
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      _peerStatusText(
                        peer,
                        controller,
                      ),
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color:
                            statusColor,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isConnected &&
                  !isConnecting)
                FilledButton.tonal(
                  onPressed: () {
                    controller
                        .connectTo(
                      peer.endpointId,
                    );
                  },
                  child:
                      const Text(
                    'CONNECT',
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Icon(
                Icons
                    .location_on_outlined,
                size: 17,
                color:
                    scheme.secondary,
              ),
              const SizedBox(
                width: 6,
              ),
              Expanded(
                child: Text(
                  controller.distanceText(
                    peer.endpointId,
                  ),
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              if (isConnected)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        nearby
                            ? _alpha(
                                Colors.greenAccent,
                                0.10,
                              )
                            : _alpha(
                                scheme.outline,
                                0.08,
                              ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child:
                      Text(
                    nearby
                        ? 'GPS STATUS: NEARBY'
                        : 'GPS STATUS: OUTSIDE RANGE',
                    style: theme
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                      color:
                          nearby
                              ? Colors.greenAccent
                              : scheme.outline,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          if (isConnecting &&
              authToken != null) ...[
            const SizedBox(
              height: 10,
            ),
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                11,
              ),
              decoration:
                  BoxDecoration(
                color: _alpha(
                  scheme.secondary,
                  0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                border:
                    Border.all(
                  color: _alpha(
                    scheme.secondary,
                    0.18,
                  ),
                ),
              ),
              child:
                  Row(
                children: [
                  Icon(
                    Icons
                        .verified_user_rounded,
                    size: 19,
                    color:
                        scheme.secondary,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child:
                        Text(
                      'PAIRING TOKEN: $authToken',
                      style: theme
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                        color:
                            scheme.secondary,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing:
                            0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _peerStatusText(
    Peer peer,
    MeshChatController controller,
  ) {
    switch (peer.status) {
      case PeerStatus.discovered:
        return 'DISCOVERED';

      case PeerStatus.connecting:
        return 'CONNECTING...';

      case PeerStatus.connected:
        return 'CONNECTED • '
            '${controller.distanceText(peer.endpointId)}';
    }
  }

  // ===============================================================
  // CONNECTED CARD
  // ===============================================================

  Widget _buildConnectedCard(
    BuildContext context,
    MeshChatController controller,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    final connected =
        controller
            .connectedPeers
            .toList();

    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            _surface(context),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color: _alpha(
            Colors.greenAccent,
            0.16,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hub_rounded,
                color:
                    Colors.greenAccent,
              ),
              const SizedBox(
                width: 9,
              ),
              Expanded(
                child: Text(
                  'Connected Mesh Peers',
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${connected.length}',
                style: theme
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  color:
                      scheme.primary,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          ...connected.map(
            (peer) =>
                Padding(
              padding:
                  const EdgeInsets
                      .only(
                bottom: 7,
              ),
              child:
                  Row(
                children: [
                  const Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                        Colors.greenAccent,
                    size: 18,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      peer.displayName,
                      style: theme
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    controller
                        .distanceText(
                      peer.endpointId,
                    ),
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color:
                          scheme.secondary,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // CHAT CARD
  // ===============================================================

  Widget _buildChatCard(
    BuildContext context,
    MeshChatController controller,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            _surface(context),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color: _alpha(
            scheme.outline,
            0.15,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons
                    .forum_outlined,
                color:
                    scheme.primary,
              ),
              const SizedBox(
                width: 9,
              ),
              Expanded(
                child: Text(
                  'Mesh Chat',
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              if (controller
                  .connectedPeers
                  .isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color: _alpha(
                      Colors.greenAccent,
                      0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child:
                      Text(
                    'ONLINE',
                    style: theme
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                      color:
                          Colors.greenAccent,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          if (controller
              .messages
              .isEmpty)
            _buildEmptyChat(
              context,
              controller,
            )
          else
            SizedBox(
              height: 300,
              child:
                  ListView.builder(
                controller:
                    _chatScrollController,
                padding:
                    const EdgeInsets
                        .only(
                  bottom: 6,
                ),
                itemCount: controller
                    .messages
                    .length,
                itemBuilder:
                    (
                  context,
                  index,
                ) {
                  return _buildMessageBubble(
                    context,
                    controller
                        .messages[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(
    BuildContext context,
    MeshChatController controller,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    return SizedBox(
      height: 220,
      child:
          Center(
        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            Icon(
              controller
                      .connectedPeers
                      .isEmpty
                  ? Icons
                      .chat_bubble_outline_rounded
                  : Icons
                      .mark_unread_chat_alt_outlined,
              size: 54,
              color: _alpha(
                scheme.primary,
                0.50,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              controller
                      .connectedPeers
                      .isEmpty
                  ? 'Connect to a peer to start chatting.'
                  : 'Connected! Send the first message.',
              textAlign:
                  TextAlign.center,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // MESSAGE BUBBLE
  // ===============================================================

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage message,
  ) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    if (message.isSystem) {
      return Padding(
        padding:
            const EdgeInsets
                .symmetric(
          vertical: 7,
        ),
        child:
            Center(
          child:
              Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration:
                BoxDecoration(
              color: _alpha(
                scheme.outline,
                0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child:
                Text(
              message.text,
              style: theme
                  .textTheme
                  .labelSmall
                  ?.copyWith(
                color: _alpha(
                  theme
                          .textTheme
                          .labelSmall
                          ?.color ??
                      Colors.white,
                  0.70,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isMine =
        message.isMine;

    final time =
        TimeOfDay.fromDateTime(
      message.timestamp,
    ).format(context);

    return Align(
      alignment:
          isMine
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child:
          Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.sizeOf(
                    context,
                  ).width *
                  0.78,
        ),
        margin:
            const EdgeInsets
                .symmetric(
          vertical: 4,
        ),
        padding:
            const EdgeInsets.fromLTRB(
          14,
          10,
          14,
          8,
        ),
        decoration:
            BoxDecoration(
          gradient:
              isMine
                  ? LinearGradient(
                      colors: [
                        scheme.primary,
                        _alpha(
                          scheme.secondary,
                          0.82,
                        ),
                      ],
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                    )
                  : null,
          color:
              isMine
                  ? null
                  : _surfaceContainer(
                      context,
                    ),
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(
              18,
            ),
            topRight:
                const Radius.circular(
              18,
            ),
            bottomLeft:
                Radius.circular(
              isMine
                  ? 18
                  : 5,
            ),
            bottomRight:
                Radius.circular(
              isMine
                  ? 5
                  : 18,
            ),
          ),
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding:
                    const EdgeInsets
                        .only(
                  bottom: 3,
                ),
                child:
                    Text(
                  message.senderName,
                  style: theme
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                    color:
                        scheme.secondary,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            Text(
              message.text,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color:
                    isMine
                        ? Colors.white
                        : null,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Align(
              alignment:
                  Alignment.bottomRight,
              child:
                  Text(
                time,
                style: theme
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                  color:
                      isMine
                          ? Colors.white70
                          : _alpha(
                              theme
                                      .textTheme
                                      .labelSmall
                                      ?.color ??
                                  Colors.white,
                              0.55,
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // COMPOSER
  // ===============================================================

  Widget _buildComposer(
    BuildContext context,
    MeshChatController controller,
  ) {
    final scheme =
        Theme.of(context)
            .colorScheme;

    final enabled =
        controller
            .connectedPeers
            .isNotEmpty;

    return Container(
      decoration:
          BoxDecoration(
        color:
            _surface(context),
        border:
            Border(
          top:
              BorderSide(
            color: _alpha(
              scheme.outline,
              0.14,
            ),
          ),
        ),
      ),
      child:
          SafeArea(
        top: false,
        child:
            Padding(
          padding:
              const EdgeInsets
                  .fromLTRB(
            12,
            9,
            12,
            9,
          ),
          child:
              Row(
            children: [
              Expanded(
                child:
                    TextField(
                  controller:
                      _messageController,
                  enabled:
                      enabled,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction:
                      TextInputAction
                          .send,
                  onSubmitted:
                      (_) {
                    _sendMessage();
                  },
                  decoration:
                      InputDecoration(
                    hintText:
                        enabled
                            ? 'Message the mesh...'
                            : 'Waiting for a connected peer...',
                    prefixIcon:
                        const Icon(
                      Icons
                          .chat_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              SizedBox(
                height: 52,
                width: 52,
                child:
                    IconButton.filled(
                  onPressed:
                      enabled
                          ? _sendMessage
                          : null,
                  icon:
                      const Icon(
                    Icons
                        .send_rounded,
                  ),
                  tooltip:
                      'Send',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // INSTRUCTION CARD
  // ===============================================================

  Widget _buildInstructionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
  }) {
    final theme =
        Theme.of(context);

    final scheme =
        theme.colorScheme;

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        15,
      ),
      decoration:
          BoxDecoration(
        color:
            _surface(context),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color: _alpha(
            scheme.outline,
            0.14,
          ),
        ),
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color: _alpha(
                scheme.primary,
                0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  scheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  text,
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    height: 1.4,
                    color: _alpha(
                      theme
                              .textTheme
                              .bodySmall
                              ?.color ??
                          Colors.white,
                      0.68,
                    ),
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