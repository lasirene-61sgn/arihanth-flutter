import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import '../model/gobal_search_model.dart';

class GlobalSearchState {
  final bool isLoading;
  final bool isFetchingMore;
  final List<GlobalSearchModel> searchResults;
  final String? nextUrl;
  final String? error;

  GlobalSearchState({
    this.isLoading = false,
    this.isFetchingMore = false,
    this.searchResults = const [],
    this.nextUrl,
    this.error,
  });

  GlobalSearchState copyWith({
    bool? isLoading,
    bool? isFetchingMore,
    List<GlobalSearchModel>? searchResults,
    String? nextUrl,
    String? error,
  }) {
    return GlobalSearchState(
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      searchResults: searchResults ?? this.searchResults,
      nextUrl: nextUrl == '' ? null : (nextUrl ?? this.nextUrl), // Use empty string to nullify
      error: error ?? this.error,
    );
  }
}

class GlobalSearchNotifier extends StateNotifier<GlobalSearchState> {
  final ApiClient _apiClient;

  GlobalSearchNotifier(this._apiClient) : super(GlobalSearchState());

  Future<void> performTextSearch(String query, {bool isNext = false}) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: [], error: null, isLoading: false, isFetchingMore: false, nextUrl: '');
      return;
    }

    if (isNext) {
      if (state.nextUrl == null || state.isFetchingMore) return;
      state = state.copyWith(isFetchingMore: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final endpoint = isNext ? ApiClient.toRelativeUrl(state.nextUrl!) : 'api/common/global-search?search=$query';
      final response = await _apiClient.get(endpoint: endpoint);
      
      _handleResponse(response, isNext: isNext);
    } catch (e) {
      state = state.copyWith(isLoading: false, isFetchingMore: false, error: e.toString());
    }
  }

  Future<void> performImageSearch(PlatformFile image, {bool isNext = false}) async {
    if (isNext) {
      if (state.nextUrl == null || state.isFetchingMore) return;
      state = state.copyWith(isFetchingMore: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final endpoint = isNext ? ApiClient.toRelativeUrl(state.nextUrl!) : 'api/common/global-search';
      final response = await _apiClient.requestWithFiles(
        endpoint: endpoint,
        files: {'image_search': image},
        method: 'POST',
      );

      _handleResponse(response, isNext: isNext);
    } catch (e) {
      state = state.copyWith(isLoading: false, isFetchingMore: false, error: e.toString());
    }
  }

  void _handleResponse(dynamic response, {bool isNext = false}) {
    if (response != null && response['status'] == 1) {
      final actualResponse = response['data'];
      
      if (actualResponse != null && actualResponse['success'] == true) {
        final data = actualResponse['data']; 
        List<GlobalSearchModel> newResults = [];
        String? newNextUrl;
        
        if (data is Map) {
          data.forEach((typeKey, typeValue) {
            if (typeValue is Map) {
              if (typeValue['next_page_url'] != null && newNextUrl == null) {
                newNextUrl = typeValue['next_page_url'].toString();
              }
              if (typeValue['data'] is List) {
                final items = typeValue['data'] as List;
                newResults.addAll(items.map((e) => GlobalSearchModel.fromJson(e as Map<String, dynamic>, typeKey)));
              }
            } else if (typeValue is List) {
              newResults.addAll(typeValue.map((e) => GlobalSearchModel.fromJson(e as Map<String, dynamic>, typeKey)));
            }
          });
        }
        
        final finalResults = isNext ? [...state.searchResults, ...newResults] : newResults;
        
        state = state.copyWith(
          isLoading: false, 
          isFetchingMore: false,
          searchResults: finalResults, 
          nextUrl: newNextUrl ?? '', // pass empty string to clear nextUrl if it's null
          error: null
        );
      } else {
        final errMsg = actualResponse?['message']?.toString() ?? 'Search failed';
        state = state.copyWith(isLoading: false, isFetchingMore: false, error: errMsg);
      }
    } else {
      String errMsg = 'API status failure';
      if (response != null && response['message'] != null) {
        final msgData = response['message'];
        if (msgData is Map && msgData['message'] != null) {
          errMsg = msgData['message'].toString();
        } else {
          errMsg = msgData.toString();
        }
      }
      state = state.copyWith(isLoading: false, isFetchingMore: false, error: errMsg);
    }
  }

  void clearSearch() {
    state = state.copyWith(searchResults: [], error: null, isLoading: false, isFetchingMore: false, nextUrl: '');
  }
}

final globalSearchProvider = StateNotifierProvider<GlobalSearchNotifier, GlobalSearchState>((ref) {
  return GlobalSearchNotifier(ApiClient());
});
