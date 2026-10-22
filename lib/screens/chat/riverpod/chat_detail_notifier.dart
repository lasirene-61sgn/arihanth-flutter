import 'package:arianth/screens/chat/model/message_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

const _sentinel = Object();

class ChatDetailState {
  final bool isLoading;
  final bool isSending;
  final String? error;
  final List<MessageModel> messages;
  final int? conversationId;
  final String? partnerCode;
  final String? partnerName;
  final bool isGroup;

  const ChatDetailState({
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.messages = const [],
    this.conversationId,
    this.partnerCode,
    this.partnerName,
    this.isGroup = false,
  });

  ChatDetailState copyWith({
    bool? isLoading,
    bool? isSending,
    dynamic error = _sentinel,
    List<MessageModel>? messages,
    int? conversationId,
    dynamic partnerCode = _sentinel,
    dynamic partnerName = _sentinel,
    bool? isGroup,
  }) {
    return ChatDetailState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error == _sentinel ? this.error : error as String?,
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      partnerCode: partnerCode == _sentinel ? this.partnerCode : partnerCode as String?,
      partnerName: partnerName == _sentinel ? this.partnerName : partnerName as String?,
      isGroup: isGroup ?? this.isGroup,
    );
  }
}

class ChatDetailNotifier extends StateNotifier<ChatDetailState> {
  ChatDetailNotifier() : super(const ChatDetailState());

  /// The conversation ID currently open on screen (if any)
  static int? activeConversationId;

  /// Callback to notify an active ChatDetailScreen to refresh when a message arrives
  static VoidCallback? onActiveMessageReceived;

  Future<void> fetchMessages(int conversationId, {int page = 1, int perPage = 30, bool isSilent = false}) async {
    final bool isDifferentConv = state.conversationId != conversationId;
    if (isDifferentConv) {
      // Clear previous conversation messages to prevent data bleed between users
      state = state.copyWith(
        isLoading: true,
        error: null,
        conversationId: conversationId,
        messages: const [],
        partnerCode: null,
        partnerName: null,
        isGroup: false,
      );
    } else if (!isSilent) {
      state = state.copyWith(isLoading: true, error: null, conversationId: conversationId);
    } else {
      state = state.copyWith(conversationId: conversationId);
    }
    try {
      final response = await ApiClient().get(
        endpoint: "api/common/chat/conversations/$conversationId/messages",
        query: {
          "page": page,
          "per_page": perPage,
        },
      );
      if (kDebugMode) {
        print("this response of chat $response");
      }

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        // If the user has already left or navigated to another conversation, discard this response
        if (state.conversationId != null && state.conversationId != conversationId) {
          return;
        }

        final dynamic rawData = response["data"] ?? response;
        
        if (rawData is Map) {
          final bool isSuccess = rawData["success"] ?? true;
          if (!isSuccess) {
            state = state.copyWith(isLoading: false, error: rawData["message"]?.toString());
            return;
          }

          dynamic rawList = rawData["messages"] ?? rawData["data"] ?? response["messages"];
          // If rawList is null or not a list, check if rawData itself has messages or list
          if (rawList is! List) {
            if (rawList is Map && (rawList["data"] is List || rawList["messages"] is List)) {
              rawList = rawList["data"] ?? rawList["messages"];
            } else {
              rawList = [];
            }
          }

          // Extract conversation type and group/partner information
          final bool isGroupConv = (rawData["is_group"] == true ||
              response["is_group"] == true ||
              rawData["chat_type"] == "group" ||
              response["chat_type"] == "group");

          String? extractedPartnerCode;
          String? extractedPartnerName;
          final partnerObj = response["partner"] ?? rawData["partner"];
          final groupObj = response["group"] ?? rawData["group"];

          if (partnerObj is Map) {
            extractedPartnerCode = partnerObj["code"]?.toString();
            extractedPartnerName = partnerObj["name"]?.toString() ?? partnerObj["label"]?.toString();
          } else if (groupObj is Map) {
            extractedPartnerName = groupObj["name"]?.toString() ?? groupObj["title"]?.toString();
          }

          if (extractedPartnerName == null || extractedPartnerName.isEmpty) {
            extractedPartnerName = rawData["name"]?.toString() ?? response["name"]?.toString();
          }

          final effectivePartnerCode = extractedPartnerCode ?? state.partnerCode;

          final List<dynamic> messageList = rawList as List<dynamic>;
          final currentUserId = SharedPreferencesHelper().getInt("userId");
          final currentUserCode = SharedPreferencesHelper().getString("user_code");
          
          final fetchedMessages = messageList
              .map((item) => MessageModel.fromJson(
                    item,
                    currentUserId: currentUserId,
                    currentUserCode: currentUserCode,
                    partnerCode: isGroupConv ? null : effectivePartnerCode,
                  ))
              .toList();

          // On page 1, replace messages completely so different conversations don't bleed into each other
          final combined = page == 1
              ? fetchedMessages.reversed.toList()
              : _mergeAndDeduplicate(fetchedMessages.reversed.toList(), state.messages);

          state = state.copyWith(
            isLoading: false,
            messages: combined,
            partnerCode: extractedPartnerCode ?? state.partnerCode,
            partnerName: extractedPartnerName ?? state.partnerName,
            isGroup: isGroupConv,
          );
        } else if (rawData is List) {
          final partnerObj = response["partner"];
          String? extractedPartnerCode;
          String? extractedPartnerName;
          if (partnerObj is Map) {
            extractedPartnerCode = partnerObj["code"]?.toString();
            extractedPartnerName = partnerObj["name"]?.toString() ?? partnerObj["label"]?.toString();
          }
          final effectivePartnerCode = extractedPartnerCode ?? state.partnerCode;

          final currentUserId = SharedPreferencesHelper().getInt("userId");
          final currentUserCode = SharedPreferencesHelper().getString("user_code");
          final fetchedMessages = rawData
              .map((item) => MessageModel.fromJson(
                    item,
                    currentUserId: currentUserId,
                    currentUserCode: currentUserCode,
                    partnerCode: effectivePartnerCode,
                  ))
              .toList();

          final combined = page == 1
              ? fetchedMessages.reversed.toList()
              : _mergeAndDeduplicate(fetchedMessages.reversed.toList(), state.messages);

          state = state.copyWith(
            isLoading: false,
            messages: combined,
            partnerCode: extractedPartnerCode ?? state.partnerCode,
            partnerName: extractedPartnerName ?? state.partnerName,
          );
        } else {
          state = state.copyWith(isLoading: false, messages: []);
        }
      } else {
        if (!isSilent) {
          final cleanError = _formatUserFriendlyError(response?["message"]?.toString() ?? "Failed to load messages.");
          state = state.copyWith(isLoading: false, error: cleanError);
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching messages: $e\n$stackTrace");
      if (!isSilent) {
        final cleanError = _formatUserFriendlyError(e.toString());
        state = state.copyWith(isLoading: false, error: cleanError);
      }
    }
  }

  Future<bool> sendMessage(String content, {String? type, String? attachmentUrl}) async {
    if (state.conversationId == null) return false;
    
    state = state.copyWith(isSending: true, error: null);
    try {
      final payload = {
        "body": content,
      };

      final response = await ApiClient().post(
        endpoint: "api/common/chat/conversations/${state.conversationId}/messages", 
        body: payload,
      );

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        final dynamic rawData = response["data"] ?? response;
        if (rawData is Map) {
          final bool isSuccess = rawData["success"] ?? true;
          if (isSuccess) {
            final dynamic messageJson = rawData["data"] ?? rawData["message"] ?? rawData;
            final currentUserId = SharedPreferencesHelper().getInt("userId");
            final currentUserCode = SharedPreferencesHelper().getString("user_code");
            MessageModel newMessage = MessageModel.fromJson(
              messageJson, 
              currentUserId: currentUserId,
              currentUserCode: currentUserCode,
            );
            // Since this message was sent from this device, ensure isMe is true
            if (!newMessage.isMe) {
              newMessage = MessageModel(
                id: newMessage.id,
                conversationId: newMessage.conversationId ?? state.conversationId,
                senderId: newMessage.senderId ?? currentUserId,
                senderName: newMessage.senderName ?? 'Me',
                content: newMessage.content ?? content,
                type: newMessage.type,
                attachmentUrl: newMessage.attachmentUrl,
                createdAt: newMessage.createdAt ?? DateTime.now().toIso8601String(),
                isMe: true,
              );
            }
            
            // Check if newMessage already exists to avoid duplicate
            final exists = state.messages.any((m) => m.id != null && m.id == newMessage.id);
            state = state.copyWith(
              isSending: false,
              messages: exists ? state.messages : [newMessage, ...state.messages],
            );

            // Re-fetch message history from server silently
            if (state.conversationId != null) {
              fetchMessages(state.conversationId!, isSilent: true);
            }
            return true;
          } else {
            final rawError = rawData["message"]?.toString() ?? "Failed to send message";
            final cleanError = _formatUserFriendlyError(rawError);
            Toaster.showError(cleanError);
            state = state.copyWith(isSending: false, error: cleanError);
            return false;
          }
        } else {
          state = state.copyWith(isSending: false);
          if (state.conversationId != null) {
            fetchMessages(state.conversationId!, isSilent: true);
          }
          return true;
        }
      } else {
        final rawError = response?["message"]?.toString() ?? "Failed to send message. Please try again.";
        final cleanError = _formatUserFriendlyError(rawError);
        Toaster.showError(cleanError);
        state = state.copyWith(isSending: false, error: cleanError);
        return false;
      }
    } catch (e) {
      final cleanError = _formatUserFriendlyError(e.toString());
      Toaster.showError(cleanError);
      state = state.copyWith(isSending: false, error: cleanError);
      return false;
    }
  }

  String _formatUserFriendlyError(String rawError) {
    if (rawError.contains("404") ||
        rawError.toLowerCase().contains("not found") ||
        rawError.toLowerCase().contains("no query results")) {
      return "Conversation not found or has been removed.";
    }
    if (rawError.contains("403") || rawError.toLowerCase().contains("unauthorized")) {
      return "You do not have permission to view this conversation.";
    }
    if (rawError.contains("SQLSTATE") ||
        rawError.contains("Column not found") ||
        rawError.contains("insert into") ||
        rawError.contains("syntax error") ||
        rawError.contains("500") ||
        rawError.contains("Server Error")) {
      return "Service temporarily unavailable. Please try again later.";
    }
    if (rawError.contains("SocketException") ||
        rawError.contains("connection error") ||
        rawError.contains("connection timeout") ||
        rawError.contains("Network")) {
      return "Network connection error. Please check your internet connection.";
    }
    return rawError;
  }

  Future<void> sendAttachment({required String filePath, String? fileName, String? caption}) async {
    if (state.conversationId == null) return;

    state = state.copyWith(isSending: true, error: null);
    try {
      final String name = fileName ?? filePath.split('/').last;
      final String textContent = (caption != null && caption.trim().isNotEmpty) ? caption.trim() : name;
      final String lowerName = name.toLowerCase();

      // Determine field type based on file extension
      final bool isImg = lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.png') || lowerName.endsWith('.webp') || lowerName.endsWith('.gif');
      final bool isVid = lowerName.endsWith('.mp4') || lowerName.endsWith('.mov') || lowerName.endsWith('.avi') || lowerName.endsWith('.mkv') || lowerName.endsWith('.webm');
      final bool isAud = lowerName.endsWith('.m4a') || lowerName.endsWith('.mp3') || lowerName.endsWith('.wav') || lowerName.endsWith('.aac') || lowerName.endsWith('.ogg');

      // Build a MultipartFile from the local path
      MultipartFile _makeFile() => MultipartFile.fromFileSync(filePath, filename: name);

      final Map<String, dynamic> fields = {
        // General text fields (backend accepts any of these aliases)
        "body": textContent,
        "content": textContent,
        "message": textContent,
        "text": textContent,
      };

      // General attachments field
      fields["attachments[]"] = [_makeFile()];

      // Media-specific fields per backend validation rules
      if (isImg) {
        fields["image"] = _makeFile();
        fields["images[]"] = [_makeFile()];
      } else if (isVid) {
        fields["video"] = _makeFile();
        fields["videos[]"] = [_makeFile()];
      } else if (isAud) {
        fields["audio"] = _makeFile();
        fields["audios[]"] = [_makeFile()];
        fields["voice"] = _makeFile();
        fields["voice_note"] = _makeFile();
      } else {
        fields["file"] = _makeFile();
        fields["files[]"] = [_makeFile()];
      }

      final formData = FormData.fromMap(fields);

      final response = await ApiClient().postMultipart(
        endpoint: "api/common/chat/conversations/${state.conversationId}/messages",
        formData: formData,
      );

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        final dynamic rawData = response["data"] ?? response;
        if (rawData is Map) {
          final dynamic messageJson = rawData["data"] ?? rawData["message"] ?? rawData;
          final currentUserId = SharedPreferencesHelper().getInt("userId");
          final currentUserCode = SharedPreferencesHelper().getString("user_code");
          MessageModel newMessage = MessageModel.fromJson(
            messageJson,
            currentUserId: currentUserId,
            currentUserCode: currentUserCode,
          );
          if (!newMessage.isMe) {
            newMessage = MessageModel(
              id: newMessage.id,
              conversationId: newMessage.conversationId ?? state.conversationId,
              senderId: newMessage.senderId ?? currentUserId,
              senderName: newMessage.senderName ?? 'Me',
              content: newMessage.content ?? (caption?.isNotEmpty == true ? caption : name),
              type: newMessage.type ?? 'file',
              attachmentUrl: newMessage.attachmentUrl ?? filePath,
              createdAt: newMessage.createdAt ?? DateTime.now().toIso8601String(),
              isMe: true,
            );
          }
          final exists = state.messages.any((m) =>
              (newMessage.id != null && m.id == newMessage.id) ||
              (newMessage.attachmentUrl != null && m.attachmentUrl == newMessage.attachmentUrl));
          state = state.copyWith(
            isSending: false,
            messages: exists ? state.messages : [newMessage, ...state.messages],
          );

          // Re-fetch message history from server to synchronize with backend state
          if (state.conversationId != null) {
            fetchMessages(state.conversationId!, isSilent: true);
          }
        } else {
          state = state.copyWith(isSending: false);
          if (state.conversationId != null) {
            fetchMessages(state.conversationId!, isSilent: true);
          }
        }
      } else {
        final rawError = response?["message"]?.toString() ?? "Failed to upload attachment. Please try again.";
        final cleanError = _formatUserFriendlyError(rawError);
        Toaster.showError(cleanError);
        state = state.copyWith(isSending: false, error: cleanError);
      }
    } catch (e) {
      final cleanError = _formatUserFriendlyError(e.toString());
      Toaster.showError(cleanError);
      state = state.copyWith(isSending: false, error: cleanError);
    }
  }

  Future<int?> startConversation(int recipientId, {String? recipientType}) async {
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/chat/conversations",
        body: {
          "recipient_id": recipientId,
          if (recipientType != null) "recipient_type": recipientType,
        },
      );

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        final actualResponse = response["data"] ?? response;
        final bool isSuccess = actualResponse is Map ? (actualResponse["success"] ?? true) : true;
        if (isSuccess) {
          final data = actualResponse is Map && actualResponse.containsKey("data") ? actualResponse["data"] : actualResponse;
          int? convId;
          if (data is Map) {
            convId = data["id"] ?? data["conversation_id"] ?? (data["conversation"] is Map ? data["conversation"]["id"] : null);
          } else if (data is int) {
            convId = data;
          }
          if (convId != null) {
            return convId;
          }
        }
      }
    } catch (e) {
      debugPrint("Error starting conversation: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> createGroup({
    required String name,
    required List<String> bpCodes,
    List<Map<String, dynamic>>? participants,
    String? description,
  }) async {
    try {
      final body = {
        "name": name,
        "participants": participants ?? bpCodes.map((code) => {"id": code, "type": "buyer"}).toList(),
        "bpcodes": bpCodes,
        "bp_codes": bpCodes,
        if (description != null && description.isNotEmpty) "description": description,
      };

      final response = await ApiClient().post(
        endpoint: "api/common/chat/groups",
        body: body,
      );

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        final actual = response["data"] ?? response;
        if (actual is Map) {
          int? convId = actual["conversation_id"] ??
              actual["id"] ??
              (actual["conversation"] is Map ? actual["conversation"]["id"] : null) ??
              (actual["chat_group"] is Map ? actual["chat_group"]["conversation_id"] ?? actual["chat_group"]["id"] : null);
          return {
            "conversation_id": convId,
            "data": actual,
          };
        }
        return {"data": actual};
      } else {
        final msg = response?["message"]?.toString() ?? "Failed to create group";
        Toaster.showError(_formatUserFriendlyError(msg));
      }
    } catch (e) {
      debugPrint("Error creating group: $e");
      Toaster.showError(_formatUserFriendlyError(e.toString()));
    }
    return null;
  }

  Future<bool> deleteConversation(int conversationId) async {
    try {
      final response = await ApiClient().delete(
        endpoint: "api/common/chat/conversations/$conversationId",
      );

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        state = const ChatDetailState();
        return true;
      } else {
        final msg = response?["message"]?.toString() ?? "Failed to delete conversation";
        Toaster.showError(_formatUserFriendlyError(msg));
      }
    } catch (e) {
      debugPrint("Error deleting conversation: $e");
      Toaster.showError(_formatUserFriendlyError(e.toString()));
    }
    return false;
  }

  void addReceivedMessage(MessageModel message) {
    // Avoid duplicate message if it already exists by ID or attachment/content match
    final alreadyExists = state.messages.any((m) =>
        (message.id != null && m.id == message.id) ||
        (message.attachmentUrl != null &&
            message.attachmentUrl!.isNotEmpty &&
            m.attachmentUrl == message.attachmentUrl));
    if (alreadyExists) return;

    state = state.copyWith(
      messages: [message, ...state.messages],
    );
  }

  /// Deduplicates messages keeping unique IDs and preserving order
  List<MessageModel> _mergeAndDeduplicate(List<MessageModel> primary, List<MessageModel> existing) {
    final seenIds = <int>{};
    final seenUrls = <String>{};
    final List<MessageModel> result = [];

    for (final m in [...primary, ...existing]) {
      if (m.id != null) {
        if (seenIds.contains(m.id)) continue;
        seenIds.add(m.id!);
      }
      if (m.attachmentUrl != null && m.attachmentUrl!.isNotEmpty) {
        if (seenUrls.contains(m.attachmentUrl)) continue;
        seenUrls.add(m.attachmentUrl!);
      }
      result.add(m);
    }
    return result;
  }

  void clearMessages() {
    state = const ChatDetailState();
  }
}

final chatDetailProvider = StateNotifierProvider<ChatDetailNotifier, ChatDetailState>((ref) {
  return ChatDetailNotifier();
});
