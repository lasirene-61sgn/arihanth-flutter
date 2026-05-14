import 'package:arianth/screens/chat/model/chat_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

const _sentinel = Object();

class ChatState {
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  final List<ChatModel> chats;
  final List<ChatModel> allChats;
  final int count;
  final String? nextUrl;
  final String? previousUrl;

  const ChatState({
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
    this.chats = const [],
    this.allChats = const [],
    this.count = 0,
    this.nextUrl,
    this.previousUrl,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isLoaded,
    dynamic error = _sentinel,
    List<ChatModel>? chats,
    List<ChatModel>? allChats,
    int? count,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error == _sentinel ? this.error : error as String?,
      chats: chats ?? this.chats,
      allChats: allChats ?? this.allChats,
      count: count ?? this.count,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());

  Future<void> fetchChats({String? url}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().get(endpoint: url ?? "api/common/chat/search");

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        
        List<dynamic> chatList = [];
        int newCount = 0;
        String? newNext;
        String? newPrevious;

        if (actualResponse is List) {
          chatList = actualResponse;
          newCount = chatList.length;
        } else if (actualResponse is Map) {
          final bool isSuccess = actualResponse["success"] ?? true;
          if (isSuccess) {
            dynamic rawData = actualResponse["data"] ?? actualResponse;
            if (rawData is Map && rawData.containsKey('data')) {
              chatList = rawData["data"] ?? [];
              newCount = rawData["total"] ?? chatList.length;
              newNext = rawData["next_page_url"];
              newPrevious = rawData["prev_page_url"];
            } else if (rawData is List) {
              chatList = rawData;
              newCount = chatList.length;
            } else {
              chatList = [];
            }
          } else {
            state = state.copyWith(
              isLoading: false,
              error: actualResponse["message"] ?? "Failed to load chats",
            );
            return;
          }
        }

        final chats = chatList.map((item) => ChatModel.fromJson(item)).toList();

        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          chats: chats,
          allChats: chats,
          count: newCount,
          nextUrl: newNext,
          previousUrl: newPrevious,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response?["message"] ?? "Failed to load chats",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to load chats: ${e.toString()}",
      );
    }
  }

  void searchChats(String query) {
    if (query.isEmpty) {
      state = state.copyWith(chats: state.allChats);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filteredList = state.allChats.where((chat) {
      return (chat.name ?? '').toLowerCase().contains(lowerQuery) ||
             (chat.bpCode ?? '').toLowerCase().contains(lowerQuery) ||
             (chat.mobile ?? '').toLowerCase().contains(lowerQuery);
    }).toList();

    state = state.copyWith(chats: filteredList);
  }

  void goToNextPage() {
    if (state.nextUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.nextUrl!);
      fetchChats(url: relativeUrl);
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.previousUrl!);
      fetchChats(url: relativeUrl);
    }
  }

  Future<void> searchChatsFromServer(String query) async {
    if (query.isEmpty) {
      await fetchChats();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().get(endpoint: "api/common/chat/search", query: {"query": query});

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        
        List<dynamic> chatList = [];
        if (actualResponse is List) {
          chatList = actualResponse;
        } else if (actualResponse is Map) {
          final bool isSuccess = actualResponse["success"] ?? true;
          if (isSuccess) {
            dynamic rawData = actualResponse["data"] ?? actualResponse;
            if (rawData is Map && rawData.containsKey('data')) {
              chatList = rawData["data"] ?? [];
            } else if (rawData is List) {
              chatList = rawData;
            }
          } else {
            state = state.copyWith(isLoading: false, error: actualResponse["message"]);
            return;
          }
        }

        final chats = chatList.map((item) => ChatModel.fromJson(item)).toList();

        state = state.copyWith(
          isLoading: false,
          chats: chats,
        );
      } else {
        state = state.copyWith(isLoading: false, error: response?["message"]);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
