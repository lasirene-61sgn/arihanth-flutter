import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<dynamic> _messageController = StreamController<dynamic>.broadcast();
  bool _isConnected = false;
  String? _url;
  Timer? _reconnectTimer;

  Stream<dynamic> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  void connect(String url) {
    _url = url;
    _establishConnection();
  }

  void _establishConnection() {
    if (_url == null) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url!));
      _isConnected = true;
      debugPrint('WebSocket Connected to $_url');

      _channel!.stream.listen(
        (message) {
          _messageController.add(message);
        },
        onDone: () {
          _isConnected = false;
          debugPrint('WebSocket Disconnected');
          _reconnect();
        },
        onError: (error) {
          _isConnected = false;
          debugPrint('WebSocket Error: $error');
          _reconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      debugPrint('WebSocket Connection Error: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('WebSocket Reconnecting...');
      _establishConnection();
    });
  }

  void sendMessage(dynamic message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(message);
    } else {
      debugPrint('WebSocket not connected. Message not sent.');
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
