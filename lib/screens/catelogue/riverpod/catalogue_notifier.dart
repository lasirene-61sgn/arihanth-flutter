import 'package:arianth/screens/catelogue/model/catalogue_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';


const _sentinel = Object();

class CatalogueHistory {
  final String? nextUrl;
  final String? previousUrl;
  final int addedCount;

  CatalogueHistory({
    this.nextUrl,
    this.previousUrl,
    required this.addedCount,
  });
}


class CatalogueState {
  final bool isLoading;
  final bool isLoaded;
  final bool isFetchingDetail;
  final String? error;
  final List<Catalogue> catalogues;
  final List<Catalogue> allCatalogues;
  final Catalogue? catalogueDetail;
  final int count;
  final String? nextUrl;
  final String? previousUrl;
  final List<CatalogueHistory> history;

  const CatalogueState({
    this.isLoading = false,
    this.isLoaded = false,
    this.isFetchingDetail = false,
    this.error,
    this.catalogues = const [],
    this.allCatalogues = const [],
    this.catalogueDetail,
    this.count = 0,
    this.nextUrl,
    this.previousUrl,
    this.history = const [],
  });

  CatalogueState copyWith({
    bool? isLoading,
    bool? isLoaded,
    bool? isFetchingDetail,
    dynamic error = _sentinel,
    List<Catalogue>? catalogues,
    List<Catalogue>? allCatalogues,
    dynamic catalogueDetail = _sentinel,
    int? count,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
    List<CatalogueHistory>? history,
  }) {
    return CatalogueState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      isFetchingDetail: isFetchingDetail ?? this.isFetchingDetail,
      error: error == _sentinel ? this.error : error as String?,
      catalogues: catalogues ?? this.catalogues,
      allCatalogues: allCatalogues ?? this.allCatalogues,
      catalogueDetail: catalogueDetail == _sentinel ? this.catalogueDetail : catalogueDetail as Catalogue?,
      count: count ?? this.count,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
      history: history ?? this.history,
    );
  }
}

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────
class CatalogueNotifier extends StateNotifier<CatalogueState> {
  final Ref ref;
  CatalogueNotifier(this.ref) : super(const CatalogueState());

  void goToNextPage() {
    if (state.nextUrl != null) fetchCatalogues(url: ApiClient.toRelativeUrl(state.nextUrl!), isNext: true);
  }

  void goToPreviousPage() {
    if (state.history.isNotEmpty) {
      final lastHistory = state.history.last;
      final newHistory = List<CatalogueHistory>.from(state.history)..removeLast();

      state = state.copyWith(
        catalogues: state.catalogues.sublist(0, state.catalogues.length - lastHistory.addedCount),
        allCatalogues: state.allCatalogues.sublist(0, state.allCatalogues.length - lastHistory.addedCount),
        nextUrl: lastHistory.nextUrl,
        previousUrl: lastHistory.previousUrl,
        history: newHistory,
      );
    }
  }

  /// Fetch catalogue list.
  /// Response shape:
  ///   response["data"] → { success: true, data: { current_page, data: [...], ... } }
  Future<void> fetchCatalogues({String? url, bool isNext = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    final String endpoint = url ?? 'api/common/catalogue';


    try {
      final response = await ApiClient().get(endpoint: endpoint);
      final outerData = response['data'];

      final bool success = outerData != null && outerData['success'] == true;

      if (success) {
        final pagination = outerData['data'];
        final dynamic rawList = pagination?['data'];

        if (rawList != null && rawList is List) {
          final catalogues = rawList
              .map((item) => Catalogue.fromJson(item as Map<String, dynamic>))
              .toList();

          final List<CatalogueHistory> newHistory = isNext
              ? [...state.history, CatalogueHistory(nextUrl: state.nextUrl, previousUrl: state.previousUrl, addedCount: catalogues.length)]
              : [];

          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            catalogues: isNext ? [...state.catalogues, ...catalogues] : catalogues,
            allCatalogues: isNext ? [...state.allCatalogues, ...catalogues] : catalogues,
            count: pagination?['total'] ?? (isNext ? state.catalogues.length + catalogues.length : catalogues.length),
            nextUrl: pagination?['next_page_url']?.toString(),
            previousUrl: pagination?['prev_page_url']?.toString(),
            history: newHistory,
          );
        } else {

          state = state.copyWith(isLoading: false, isLoaded: true, catalogues: [], allCatalogues: []);
        }
      } else {
        final msg = outerData?['message']?.toString() ?? 'Server returned failure';

        state = state.copyWith(isLoading: false, isLoaded: false, error: msg, catalogues: []);
      }
    } catch (e, st) {

      state = state.copyWith(
        isLoading: false,
        isLoaded: false,
        error: 'Failed to load: ${e.toString()}',
        catalogues: [],
      );
    }
  }

  /// Fetch single catalogue detail.
  Future<void> catalogueDetail(String id) async {
    state = state.copyWith(isFetchingDetail: true, error: null);
    try {
      final response = await ApiClient().get(endpoint: 'api/common/catalogue/$id');
      final outerData = response['data'];

      if (outerData != null && outerData['success'] == true && outerData['data'] != null) {
        final catalogue = Catalogue.fromJson(outerData['data']);
        state = state.copyWith(isFetchingDetail: false, catalogueDetail: catalogue);
      } else {
        final msg = outerData?['message']?.toString() ?? 'Catalogue not found';
        state = state.copyWith(isFetchingDetail: false, error: msg);
      }
    } catch (e, st) {

      state = state.copyWith(
        isFetchingDetail: false,
        error: 'Failed to load details: ${e.toString()}',
      );
    }
  }

  /// Filter by query across code, name, bp code.
  void filterCatalogues(String query) {
    if (query.isEmpty) {
      state = state.copyWith(catalogues: state.allCatalogues);
      return;
    }
    final q = query.toLowerCase();
    final filtered = state.allCatalogues.where((c) {
      return (c.productCode ?? '').toLowerCase().contains(q) ||
          (c.designCode ?? '').toLowerCase().contains(q) ||
          (c.bpCode ?? '').toLowerCase().contains(q) ||
          (c.productName ?? '').toLowerCase().contains(q);
    }).toList();
    state = state.copyWith(catalogues: filtered);
  }

  void resetCatalogues() {
    state = state.copyWith(catalogues: state.allCatalogues, error: null, isLoaded: true);
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────
final catalogueProvider = StateNotifierProvider<CatalogueNotifier, CatalogueState>(
  (ref) => CatalogueNotifier(ref),
);
