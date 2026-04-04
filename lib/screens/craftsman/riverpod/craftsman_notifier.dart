import 'dart:convert';
import 'package:arianth/screens/craftsman/model/craftsman_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';

import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';

class CraftsmanState {
  final bool isLoading;
  final bool isLoaded;
  final bool isSaving;
  final List<Craftsman> craftsmen;
  final List<Craftsman> allCraftsmen;
  final Craftsman? selectedCraftsman; // <--- Add this
  final String? error;
  final String? nextUrl;
  final String? previousUrl;
  final int count;

  CraftsmanState({
    this.isLoading = false,
    this.isLoaded = false,
    this.isSaving = false,
    this.craftsmen = const [],
    this.allCraftsmen = const [],
    this.selectedCraftsman, // <--- Add this
    this.error,
    this.nextUrl,
    this.previousUrl,
    this.count = 0,
  });

  CraftsmanState copyWith({
    bool? isLoading,
    bool? isLoaded,
    bool? isSaving,
    List<Craftsman>? craftsmen,
    List<Craftsman>? allCraftsmen,
    Craftsman? selectedCraftsman,
    String? error,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
    int? count,
  }) {
    return CraftsmanState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      craftsmen: craftsmen ?? this.craftsmen,
      allCraftsmen: allCraftsmen ?? this.allCraftsmen,
      selectedCraftsman: selectedCraftsman ?? this.selectedCraftsman,
      error: error,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
      count: count ?? this.count,
    );
  }
}

const _sentinel = Object();

class CraftsmanListNotifier extends StateNotifier<CraftsmanState> {
  final Ref ref;

  CraftsmanListNotifier(this.ref) : super(CraftsmanState());

  void goToNextPage() {
    if (state.nextUrl != null) {
      fetchCraftsmen(url: ApiClient.toRelativeUrl(state.nextUrl!));
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      fetchCraftsmen(url: ApiClient.toRelativeUrl(state.previousUrl!));
    }
  }

  Future<void> fetchCraftsmen({String? url}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {


      final response = await ApiClient().get(endpoint: url ?? "api/super-admin/craftsmen");



      if (response["data"] != null && response["data"]["success"] == true) {
        final pageData = response["data"]["data"];
        final List<dynamic> craftsmenList = pageData["data"];



        final craftsmen = craftsmenList.map((e) => Craftsman.fromJson(e)).toList();
        final codes = craftsmen.map((c) => c.craftmanCode).toList();


        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          craftsmen: craftsmen,
          allCraftsmen: craftsmen,
          nextUrl: pageData["next_page_url"],
          previousUrl: pageData["prev_page_url"],
          count: pageData["total"],
        );


      } else {

        state = state.copyWith(
          isLoading: false,
          error: "Invalid response",
        );
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isLoading: false,
        error: "Failed to load craftsmen",
      );
    }
  }

  /// ===============================
  /// NEXT PAGE
  /// ===============================
  /// ===============================
  /// FILTER
  /// ===============================
  void filterCraftsmen(String filterKey, String query) {
    if (query.isEmpty) {
      state = state.copyWith(craftsmen: state.allCraftsmen);
      return;
    }

    final lowerQuery = query.toLowerCase();

    final filteredList = state.allCraftsmen.where((c) {
      switch (filterKey) {
        case 'Craftsman Code':
          return (c.craftmanCode ?? '').toLowerCase().contains(lowerQuery);
        case 'Craftsman Name':
          return (c.name ?? '').toLowerCase().contains(lowerQuery);
        case 'Mobile':
          return (c.mobile ?? '').toLowerCase().contains(lowerQuery);
        case 'Email':
          return (c.email ?? '').toLowerCase().contains(lowerQuery);
        case 'Status':
          return (c.kycStatus ?? '').toLowerCase().contains(lowerQuery);
        default:
          return false;
      }
    }).toList();

    state = state.copyWith(craftsmen: filteredList);
  }

  /// ===============================
  /// FETCH DETAILS
  /// ===============================
  Future<void> fetchCraftsmanDetail(int id) async {
    state = state.copyWith(isLoading: true, error: null, selectedCraftsman: null);

    final String detailUrl = "api/super-admin/craftsmen/$id";
    try {
      final response = await ApiClient().get(endpoint: detailUrl);

      // Check for status 1 and deep-dive into the "data" -> "data" object
      if (response["status"] == 1 && response["data"] != null) {

        // IMPORTANT: Based on your log, the object is inside response["data"]["data"]
        final dynamic craftsmanData = response["data"]["data"];

        if (craftsmanData != null) {
          final Craftsman detail = Craftsman.fromJson(craftsmanData);



          state = state.copyWith(
            isLoading: false,
            selectedCraftsman: detail,
          );
        } else {
          _handleError("Craftsman data nested object not found");
        }
      } else {
        _handleError(response["message"] ?? "Failed to load details");
      }
    } catch (e) {

      state = state.copyWith(isLoading: false, error: "Failed to load details");
    }
  }
  void _handleError(String message) {

    state = state.copyWith(
      isLoading: false,
      isSaving: false,
      error: message,
    );
  }

  /// ===============================
  /// SAVE CRAFTSMAN (Standardized)
  /// ===============================
  Future<void> saveCraftsman({
    String? url,
    Map<String, dynamic>? field,
    Map<String, dynamic>? files,
    String? method,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      final response = await ApiClient().requestWithFiles(
        method: method ?? "POST",
        endpoint: url ?? "api/super-admin/craftsmen",
        fields: field,
        files: files,
      );



      final status = response['status'];
      final responseData = response['data'];

      // ✅ SUCCESS CASE
      if (status == 1 && responseData != null && responseData['success'] == true) {
        state = state.copyWith(isSaving: false, error: null);

        String msg = responseData['message'] ??
            (method == "PUT"
                ? 'Craftsman updated successfully'
                : 'Craftsman created successfully');

        Toaster.showSuccess(msg);

        await fetchCraftsmen();
        Get.back();
      }

      // ❌ ERROR CASE (ONLY MESSAGE USED)
      else {
        String errorMsg = "Failed to save Craftsman";

        // Case 1: message object
        if (response['message'] is Map) {
          final msgBlock = response['message'];
          if (msgBlock['message'] != null) {
            errorMsg = msgBlock['message'];
          }
        }

        // Case 2: data message fallback
        else if (responseData != null && responseData['message'] != null) {
          errorMsg = responseData['message'];
        }

        // Case 3: direct message string
        else if (response['message'] is String) {
          errorMsg = response['message'];
        }

        state = state.copyWith(isSaving: false, error: errorMsg);
        Toaster.showError(errorMsg);
      }
    } catch (e, stackTrace) {
      state = state.copyWith(isSaving: false, error: e.toString());
      Toaster.showError("An unexpected error occurred");
    }
  }
  /// ===============================
  /// SORT
  /// ===============================


  /// ===============================
  /// RESET
  /// ===============================
  void resetCraftsmen() {
    state = state.copyWith(
      craftsmen: state.allCraftsmen,
      error: null,
      isLoaded: true,
    );
  }
}

final craftsmanListProvider = StateNotifierProvider<CraftsmanListNotifier, CraftsmanState>(
      (ref) => CraftsmanListNotifier(ref),
);