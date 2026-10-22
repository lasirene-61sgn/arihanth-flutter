import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/chat/model/chat_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:flutter_riverpod/legacy.dart';

class ContactsState {
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final List<ChatModel> contacts;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  const ContactsState({
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.contacts = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasMore = false,
  });

  ContactsState copyWith({
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    List<ChatModel>? contacts,
    int? currentPage,
    int? lastPage,
    bool? hasMore,
  }) {
    return ContactsState(
      isLoading: isLoading ?? this.isLoading,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      error: error,
      contacts: contacts ?? this.contacts,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  ContactsNotifier() : super(const ContactsState());

  Future<void> fetchContacts({int page = 1, String? search}) async {
    final isFirst = page == 1;
    state = state.copyWith(
      isLoading: isFirst,
      isMoreLoading: !isFirst,
      error: null,
      currentPage: page,
    );

    try {
      final query = <String, dynamic>{"page": page};
      if (search != null && search.trim().isNotEmpty) {
        query["search"] = search.trim();
      }

      final response = await ApiClient().get(
        endpoint: "api/common/chat/contacts",
        query: query,
      );

      if (response != null && (response["status"] == 1 || response["success"] == true)) {
        final actualData = response["data"];
        List<dynamic> rawList = [];
        int currentPage = page;
        int lastPage = 1;
        bool hasMore = false;

        if (actualData is List) {
          rawList = actualData;
        } else if (actualData is Map) {
          if (actualData.containsKey('data') && actualData['data'] is List) {
            rawList = actualData['data'];
          } else {
            actualData.forEach((key, value) {
              if (value is List) {
                rawList.addAll(value);
              }
            });
          }
        }

        final pagination = response["pagination"] ?? (actualData is Map ? actualData["pagination"] : null);
        if (pagination is Map) {
          currentPage = pagination["current_page"] ?? page;
          lastPage = pagination["last_page"] ?? 1;
          hasMore = pagination["has_more"] ?? (currentPage < lastPage);
        }

        final newContacts = rawList.map((item) => ChatModel.fromJson(item)).toList();

        state = state.copyWith(
          isLoading: false,
          isMoreLoading: false,
          contacts: isFirst ? newContacts : [...state.contacts, ...newContacts],
          currentPage: currentPage,
          lastPage: lastPage,
          hasMore: hasMore,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isMoreLoading: false,
          error: response?["message"]?.toString() ?? "Failed to load contacts",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isMoreLoading: false,
        error: e.toString(),
      );
    }
  }

  void searchContacts(String query) {
    fetchContacts(page: 1, search: query);
  }

  void loadMore({String? search}) {
    if (state.isLoading || state.isMoreLoading || !state.hasMore) return;
    fetchContacts(page: state.currentPage + 1, search: search);
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  return ContactsNotifier();
});
