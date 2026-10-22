import 'dart:async';
import 'dart:convert';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<dynamic> _messageController = StreamController<dynamic>.broadcast();
  bool _isConnected = false;
  String? _url;
  Timer? _reconnectTimer;
  String? _socketId;
  final Set<String> _subscribedChannels = {};

  Stream<dynamic> get messages => _messageController.stream;
  bool get isConnected => _isConnected;
  String? get socketId => _socketId;

  static const String defaultWsUrl =
      "wss://arihanthjewellers.in/app/lffoipjc57ebkzslnfcc?protocol=7&client=js&version=8.4.0&flash=false";

  int _retryCount = 0;
  static const int _maxRetries = 5;

  void connect([String? url]) {
    _reconnectTimer?.cancel();
    _url = url ?? defaultWsUrl;
    _retryCount = 0;
    _establishConnection();
  }

  void _establishConnection() {
    if (_url == null || _retryCount >= _maxRetries) {
      if (_retryCount >= _maxRetries) {
        debugPrint('WebSocket: Max connection retries reached.');
      }
      return;
    }

    try {
      final channel = WebSocketChannel.connect(Uri.parse(_url!));
      _channel = channel;
      debugPrint('WebSocket Connecting to $_url (attempt ${_retryCount + 1})');

      channel.stream.listen(
        (message) {
          _isConnected = true;
          _retryCount = 0;
          _handleIncomingMessage(message);
        },
        onDone: () {
          _isConnected = false;
          _socketId = null;
          debugPrint('WebSocket Disconnected');
          _scheduleReconnect();
        },
        onError: (error) {
          _isConnected = false;
          _socketId = null;
          debugPrint('WebSocket Stream Error: $error');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      channel.ready.then((_) {
        _isConnected = true;
        _retryCount = 0;
        debugPrint('WebSocket connection successfully opened.');
      }).catchError((error) {
        _isConnected = false;
        _socketId = null;
        debugPrint('WebSocket Connection failed: $error');
        _scheduleReconnect();
      });
    } catch (e) {
      _isConnected = false;
      _socketId = null;
      debugPrint('WebSocket Connection Error: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (_retryCount >= _maxRetries) return;

    _retryCount++;
    final delaySeconds = (_retryCount * 5).clamp(5, 30);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      debugPrint('WebSocket Reconnecting attempt $_retryCount...');
      _establishConnection();
    });
  }

  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      final decoded = rawMessage is String ? jsonDecode(rawMessage) : rawMessage;
      if (decoded is Map) {
        final event = decoded['event'];
        // Handle Pusher / Reverb connection established event
        if (event == 'pusher:connection_established') {
          final data = decoded['data'] is String ? jsonDecode(decoded['data']) : decoded['data'];
          _socketId = data['socket_id'];
          debugPrint('WebSocket connection established with socket_id: $_socketId');

          // Resubscribe to channels
          for (final channelName in _subscribedChannels.toList()) {
            _subscribeToChannel(channelName);
          }
        } else if (event == 'pusher:error') {
          debugPrint('⚠️ Pusher/WebSocket Error Event: ${decoded['data']}');
        } else if (event == 'pusher:subscription_error') {
          debugPrint('⚠️ Pusher Subscription Error for channel ${decoded['channel']}: ${decoded['data']}');
        } else if (event == 'pusher:ping') {
          sendMessage(jsonEncode({'event': 'pusher:pong', 'data': {}}));
        }
      }
      _messageController.add(decoded);
    } catch (e) {
      _messageController.add(rawMessage);
    }
  }

  Future<void> subscribe(String channelName) async {
    _subscribedChannels.add(channelName);
    if (_isConnected && _socketId != null) {
      await _subscribeToChannel(channelName);
    }
  }

  Future<void> _subscribeToChannel(String channelName) async {
    try {
      String? auth;
      if (channelName.startsWith('private-') || channelName.startsWith('presence-')) {
        auth = await _authenticateChannel(channelName);
        if (auth == null) {
          debugPrint('⚠️ Cannot subscribe to $channelName: Broadcast auth failed / token null');
          return;
        }
      }

      final payload = {
        'event': 'pusher:subscribe',
        'data': {
          'channel': channelName,
          if (auth != null) 'auth': auth,
        },
      };
      sendMessage(jsonEncode(payload));
      debugPrint('Subscribed to channel: $channelName');
    } catch (e) {
      debugPrint('Failed to subscribe to $channelName: $e');
    }
  }

  Future<String?> _authenticateChannel(String channelName) async {
    if (_socketId == null) {
      debugPrint("Broadcasting auth skipped: _socketId is null");
      return null;
    }
    
    // Try primary endpoint: api/broadcasting/auth
    try {
      debugPrint("Broadcasting authenticating for $channelName with socket_id: $_socketId");
      final response = await ApiClient().post(
        endpoint: "api/broadcasting/auth",
        body: {
          "socket_id": _socketId,
          "channel_name": channelName,
        },
      );
      debugPrint("Broadcasting auth response (api/broadcasting/auth): $response");

      if (response != null && response["auth"] != null) {
        return response["auth"];
      } else if (response != null && response["data"] != null && response["data"]["auth"] != null) {
        return response["data"]["auth"];
      }
    } catch (e) {
      debugPrint("api/broadcasting/auth error for $channelName: $e. Trying fallback endpoint broadcasting/auth...");
      
      // Fallback endpoint: broadcasting/auth (standard Laravel route)
      try {
        final fallbackResponse = await ApiClient().post(
          endpoint: "broadcasting/auth",
          body: {
            "socket_id": _socketId,
            "channel_name": channelName,
          },
        );
        debugPrint("Broadcasting auth response (broadcasting/auth): $fallbackResponse");
        if (fallbackResponse != null && fallbackResponse["auth"] != null) {
          return fallbackResponse["auth"];
        } else if (fallbackResponse != null && fallbackResponse["data"] != null && fallbackResponse["data"]["auth"] != null) {
          return fallbackResponse["data"]["auth"];
        }
      } catch (fallbackError) {
        debugPrint("Fallback broadcasting/auth error: $fallbackError");
      }
    }
    return null;
  }

  void unsubscribe(String channelName) {
    _subscribedChannels.remove(channelName);
    if (_isConnected) {
      final payload = {
        'event': 'pusher:unsubscribe',
        'data': {
          'channel': channelName,
        },
      };
      sendMessage(jsonEncode(payload));
    }
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
    _socketId = null;
  }

  void dispose() {
    disconnect();
    _subscribedChannels.clear();
    _messageController.close();
  }
}
