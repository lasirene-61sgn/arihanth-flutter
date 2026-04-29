import 'package:arianth/screens/designs/model/designs_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class FavoriteListState {
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  final List<Design> favorites;
  final List<Design> allFavorites;
  final int count;
  final String? nextUrl;
  final String? previousUrl;

  const FavoriteListState({
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
    this.favorites = const [],
    this.allFavorites = const [],
    this.count = 0,
    this.nextUrl,
    this.previousUrl,
  });

  FavoriteListState copyWith({
    bool? isLoading,
    bool? isLoaded,
    String? error,
    List<Design>? favorites,
    List<Design>? allFavorites,
    int? count,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
  }) {
    return FavoriteListState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      favorites: favorites ?? this.favorites,
      allFavorites: allFavorites ?? this.allFavorites,
      count: count ?? this.count,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
    );
  }
}

const _sentinel = Object();

class FavoriteListNotifier extends StateNotifier<FavoriteListState> {
  FavoriteListNotifier() : super(const FavoriteListState());

  void goToNextPage() {
    if (state.nextUrl != null) {
      fetchFavorites(url: ApiClient.toRelativeUrl(state.nextUrl!));
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      fetchFavorites(url: ApiClient.toRelativeUrl(state.previousUrl!));
    }
  }

  Future<void> fetchFavorites({String? url}) async {
    state = state.copyWith(isLoading: true, error: null);

    final String endpoint = url ?? "api/common/favorites";

    try {
      final response = await ApiClient().get(endpoint: endpoint);
      print("++++ Favorites API Response: $response");
      final outerData = response["data"];
      final bool isSuccess = outerData != null && outerData["success"] == true;

      if (isSuccess) {
        final paginationData = outerData["data"];
        final dynamic rawList = paginationData?["data"];

        if (rawList != null && rawList is List) {
          // The API returns a list of objects where each object has a 'product' field
          final favorites = rawList
              .where((item) => item["product"] != null)
              .map((item) => Design.fromJson(item["product"] as Map<String, dynamic>))
              .toList();

          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            favorites: favorites,
            allFavorites: favorites,
            count: paginationData?["total"] ?? favorites.length,
            nextUrl: paginationData?["next_page_url"]?.toString(),
            previousUrl: paginationData?["prev_page_url"]?.toString(),
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            favorites: [],
            allFavorites: [],
          );
        }
      } else {
        final errorMsg = outerData?["message"]?.toString() ?? "Server returned success: false";
        state = state.copyWith(isLoading: false, isLoaded: false, error: errorMsg, favorites: []);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoaded: false, error: e.toString(), favorites: []);
    }
  }

  Future<void> toggleFavorite(int productId) async {
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/designs/$productId/favourite",
        body: {},
      );
      print("++++ Toggle Favorite API Response: $response");
      if (response["status"] == 1) {
        Toaster.showSuccess(response["data"]?["message"] ?? "Success");
        // Refresh the list
        await fetchFavorites();
      } else {
        Toaster.showError(response["data"]?["message"] ?? "Failed to update favorite");
      }
    } catch (e) {
      Toaster.showError("Error: $e");
    }
  }

  void filterFavorites(String query) {
    if (query.isEmpty) {
      state = state.copyWith(favorites: state.allFavorites);
      return;
    }
    final lowerQuery = query.toLowerCase();
    final filtered = state.allFavorites.where((d) {
      return (d.designCode ?? '').toLowerCase().contains(lowerQuery) ||
          (d.productName ?? '').toLowerCase().contains(lowerQuery);
    }).toList();
    state = state.copyWith(favorites: filtered);
  }
}

final favoritesProvider = StateNotifierProvider<FavoriteListNotifier, FavoriteListState>(
  (ref) => FavoriteListNotifier(),
);
