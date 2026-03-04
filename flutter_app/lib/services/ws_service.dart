import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dating_app/config/app_config.dart';
import 'package:dating_app/models/message.dart';
import 'package:dating_app/services/storage_service.dart';

class WsService {
  final StorageService _storage;
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;

  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  WsService({required StorageService storage}) : _storage = storage;

  void connect() {
    final token = _storage.getToken();
    if (token == null) {
      print('WsService: No token available, cannot connect');
      return;
    }

    _shouldReconnect = true;
    _doConnect(token);
  }

  void _doConnect(String token) {
    try {
      final wsUrl = '${AppConfig.wsBaseUrl}?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      _connectionController.add(true);
      _startHeartbeat();
      print('WsService: Connected');
    } catch (e) {
      print('WsService: Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onData(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;

      // Handle heartbeat pong
      if (json['type'] == 'pong') return;

      final message = Message.fromJson(json);
      _messageController.add(message);
    } catch (e) {
      print('WsService: Failed to parse message: $e');
    }
  }

  void _onError(dynamic error) {
    print('WsService: Error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _onDone() {
    print('WsService: Connection closed');
    _isConnected = false;
    _connectionController.add(false);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void sendMessage(Message message) {
    if (!_isConnected || _channel == null) {
      print('WsService: Not connected, cannot send message');
      return;
    }
    final json = jsonEncode(message.toJson());
    _channel!.sink.add(json);
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      AppConfig.heartbeatInterval,
      (_) {
        if (_isConnected && _channel != null) {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        }
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      AppConfig.wsReconnectDelay,
      () {
        final token = _storage.getToken();
        if (token != null && _shouldReconnect) {
          print('WsService: Attempting reconnect...');
          _doConnect(token);
        }
      },
    );
  }

  void disconnect() {
    _shouldReconnect = false;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
