import 'package:arianth/services/websocket/websocket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final webSocketMessagesProvider = StreamProvider<dynamic>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.messages;
});
