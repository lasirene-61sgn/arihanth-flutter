import 'package:arianth/screens/chat/model/message_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

const _sentinel = Object();

class ChatDetailState {
  final bool isLoading;
  final bool isSending;
  final String? error;
  final List<MessageModel> messages;
  final int? conversationId;

  const ChatDetailState({
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.messages = const [],
    this.conversationId,
  });

  ChatDetailState copyWith({
    bool? isLoading,
    bool? isSending,
    dynamic error = _sentinel,
    List<MessageModel>? messages,
    int? conversationId,
  }) {
    return ChatDetailState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error == _sentinel ? this.error : error as String?,
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}

class ChatDetailNotifier extends StateNotifier<ChatDetailState> {
  ChatDetailNotifier() : super(const ChatDetailState());

  Future<void> fetchMessages(int conversationId) async {
    state = state.copyWith(isLoading: true, error: null, conversationId: conversationId);
    try {
      final response = await ApiClient().get(endpoint: "api/common/chat/$conversationId");

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        if (actualResponse["success"] == true) {
          final List<dynamic> messageList = actualResponse["data"] ?? [];
          final currentUserId = SharedPreferencesHelper().getInt("userId");
          
          final messages = messageList.map((item) => MessageModel.fromJson(item, currentUserId: currentUserId)).toList();

          state = state.copyWith(
            isLoading: false,
            messages: messages.reversed.toList(), // Assuming the API returns newest first, or we want to show newest at bottom
          );
        } else {
          state = state.copyWith(isLoading: false, error: actualResponse["message"]);
        }
      } else {
        state = state.copyWith(isLoading: false, error: response?["message"]);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String content, {String? type, String? attachmentUrl}) async {
    if (state.conversationId == null) return;
    
    state = state.copyWith(isSending: true, error: null);
    try {
      final payload = {
        "conversation_id": state.conversationId,
        "content": content,
        "type": type ?? "text",
        if (attachmentUrl != null) "attachment_url": attachmentUrl,
      };

      final response = await ApiClient().post(endpoint: "api/common/chat/message", body: payload);

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        if (actualResponse["success"] == true) {
          final currentUserId = SharedPreferencesHelper().getInt("userId");
          final newMessage = MessageModel.fromJson(actualResponse["data"], currentUserId: currentUserId);
          
          state = state.copyWith(
            isSending: false,
            messages: [newMessage, ...state.messages],
          );
        } else {
          state = state.copyWith(isSending: false, error: actualResponse["message"]);
        }
      } else {
        state = state.copyWith(isSending: false, error: response?["message"]);
      }
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  Future<int?> startConversation(int otherUserId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/chat/start",
        body: {"user_id": otherUserId},
      );

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        if (actualResponse["success"] == true) {
          final convId = actualResponse["data"]["id"];
          state = state.copyWith(isLoading: false, conversationId: convId);
          await fetchMessages(convId);
          return convId;
        } else {
          state = state.copyWith(isLoading: false, error: actualResponse["message"]);
        }
      } else {
        state = state.copyWith(isLoading: false, error: response?["message"]);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
    return null;
  }
  
  void addReceivedMessage(MessageModel message) {
    state = state.copyWith(
      messages: [message, ...state.messages],
    );
  }
}

final chatDetailProvider = StateNotifierProvider<ChatDetailNotifier, ChatDetailState>((ref) {
  return ChatDetailNotifier();
});
