import 'package:arianth/screens/chat/model/chat_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

const _sentinel = Object();

class ChatState {
  final bool isLoading;
  final bool isMoreLoading;
  final bool isLoaded;
  final String? error;
  final List<ChatModel> chats;
  final List<ChatModel> allChats;
  final int count;
  final int currentPage;
  final int lastPage;
  final bool hasMore;
  final String? nextUrl;
  final String? previousUrl;

  const ChatState({
    this.isLoading = false,
    this.isMoreLoading = false,
    this.isLoaded = false,
    this.error,
    this.chats = const [],
    this.allChats = const [],
    this.count = 0,
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasMore = false,
    this.nextUrl,
    this.previousUrl,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isMoreLoading,
    bool? isLoaded,
    dynamic error = _sentinel,
    List<ChatModel>? chats,
    List<ChatModel>? allChats,
    int? count,
    int? currentPage,
    int? lastPage,
    bool? hasMore,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error == _sentinel ? this.error : error as String?,
      chats: chats ?? this.chats,
      allChats: allChats ?? this.allChats,
      count: count ?? this.count,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      hasMore: hasMore ?? this.hasMore,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());

  /// Callback to refresh recent chats when a notification arrives
  static VoidCallback? onMessageReceivedCallback;

  Future<void> fetchChats({int page = 1, String? url, bool isRefresh = false}) async {
    // Only show full loader if we don't have chats or it's an explicit refresh
    final bool shouldShowLoader = state.chats.isEmpty || isRefresh;
    state = state.copyWith(
      isLoading: shouldShowLoader,
      error: null,
      currentPage: page,
    );

    try {
      final response = await ApiClient().get(
        endpoint: url ?? "api/common/chat/recent-chats",
        query: url == null ? {"page": page} : null,
      );

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        final actualData = response["data"];
        
        List<dynamic> rawContactList = [];
        int totalCount = 0;
        int currentPage = page;
        int lastPage = 1;
        bool hasMore = false;

        if (actualData is List) {
          rawContactList = actualData;
          totalCount = rawContactList.length;
        } else if (actualData is Map) {
          // Check for nested pagination or categorized lists
          final List<dynamic> combinedList = [];
          actualData.forEach((key, value) {
            if (value is List) {
              combinedList.addAll(value);
            }
          });
          rawContactList = combinedList;
          totalCount = rawContactList.length;
        }

        // Check root or inner pagination
        final pagination = response["pagination"] ?? (actualData is Map ? actualData["pagination"] : null);
        if (pagination is Map) {
          currentPage = pagination["current_page"] ?? page;
          lastPage = pagination["last_page"] ?? 1;
          totalCount = pagination["total"] ?? totalCount;
          hasMore = pagination["has_more"] ?? (currentPage < lastPage);
        } else {
          hasMore = false;
        }

        final newChats = rawContactList.map((item) => ChatModel.fromJson(item)).toList();

        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          chats: page == 1 ? newChats : [...state.chats, ...newChats],
          allChats: page == 1 ? newChats : [...state.allChats, ...newChats],
          count: totalCount,
          currentPage: currentPage,
          lastPage: lastPage,
          hasMore: hasMore,
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

  Future<void> loadMore() async {
    if (state.isLoading || state.isMoreLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isMoreLoading: true);

    try {
      final response = await ApiClient().get(
        endpoint: "api/common/chat/recent-chats",
        query: {"page": nextPage},
      );

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        final actualData = response["data"];
        List<dynamic> rawContactList = [];
        int totalCount = state.count;
        int currentPage = nextPage;
        int lastPage = state.lastPage;
        bool hasMore = false;

        if (actualData is List) {
          rawContactList = actualData;
        } else if (actualData is Map) {
          final List<dynamic> combinedList = [];
          actualData.forEach((key, value) {
            if (value is List) {
              combinedList.addAll(value);
            }
          });
          rawContactList = combinedList;
        }

        final pagination = response["pagination"] ?? (actualData is Map ? actualData["pagination"] : null);
        if (pagination is Map) {
          currentPage = pagination["current_page"] ?? nextPage;
          lastPage = pagination["last_page"] ?? 1;
          totalCount = pagination["total"] ?? totalCount;
          hasMore = pagination["has_more"] ?? (currentPage < lastPage);
        }

        final newChats = rawContactList.map((item) => ChatModel.fromJson(item)).toList();

        state = state.copyWith(
          isMoreLoading: false,
          chats: [...state.chats, ...newChats],
          allChats: [...state.allChats, ...newChats],
          count: totalCount,
          currentPage: currentPage,
          lastPage: lastPage,
          hasMore: hasMore,
        );
      } else {
        state = state.copyWith(isMoreLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isMoreLoading: false);
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
      final response = await ApiClient().get(endpoint: "api/common/chat/contacts", query: {"search": query});

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        final actualResponse = response["data"];
        
        List<dynamic> chatList = [];
        if (actualResponse is List) {
          chatList = actualResponse;
        } else if (actualResponse is Map) {
          final bool isSuccess = actualResponse["success"] ?? true;
          if (isSuccess) {
            dynamic rawData = actualResponse["data"] ?? actualResponse;
            if (rawData is Map) {
              if (rawData.containsKey('data') && rawData['data'] is List) {
                chatList = rawData["data"] ?? [];
              } else {
                final List<dynamic> combinedList = [];
                rawData.forEach((key, value) {
                  if (value is List) {
                    combinedList.addAll(value);
                  }
                });
                chatList = combinedList;
              }
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

  Future<bool> deleteConversation(int conversationId) async {
    try {
      final response = await ApiClient().delete(
        endpoint: "api/common/chat/conversations/$conversationId",
      );

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        // Remove locally from state
        final updatedChats = state.chats.where((c) => c.conversationId != conversationId && c.id != conversationId).toList();
        final updatedAllChats = state.allChats.where((c) => c.conversationId != conversationId && c.id != conversationId).toList();
        state = state.copyWith(
          chats: updatedChats,
          allChats: updatedAllChats,
        );
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting conversation: $e");
    }
    return false;
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
