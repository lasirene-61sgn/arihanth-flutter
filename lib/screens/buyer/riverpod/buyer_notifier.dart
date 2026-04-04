import 'dart:convert';
import 'package:arianth/screens/buyer/model/buyer_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';

import 'package:arianth/services/widget/custom_msg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';
class BuyerState {
  final bool isLoading;
  final bool isLoaded;
  final bool isSaving;

  final List<Buyer> buyers;
  final List<Buyer> allBuyers;
  final Buyer? selectedBuyer;
  final String? error;

  final String? nextUrl;
  final String? previousUrl;

  final int count;

  BuyerState({
    this.isLoading = false,
    this.isLoaded = false,
    this.isSaving = false,
    this.buyers = const [],
    this.allBuyers = const [],
    this.selectedBuyer,
    this.error,
    this.nextUrl,
    this.previousUrl,
    this.count = 0,
  });

  BuyerState copyWith({
    bool? isLoading,
    bool? isLoaded,
    bool? isSaving,
    List<Buyer>? buyers,
    List<Buyer>? allBuyers,
    Buyer? selectedBuyer,
    String? error,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
    int? count,
  }) {
    return BuyerState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      buyers: buyers ?? this.buyers,
      allBuyers: allBuyers ?? this.allBuyers,
      selectedBuyer: selectedBuyer ?? this.selectedBuyer,
      error: error,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
      count: count ?? this.count,
    );
  }
}

const _sentinel = Object();

class BuyerListNotifier extends StateNotifier<BuyerState> {
  final Ref ref;

  BuyerListNotifier(this.ref) : super(BuyerState());

  void goToNextPage() {
    if (state.nextUrl != null) {
      fetchBuyers(url: ApiClient.toRelativeUrl(state.nextUrl!));
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      fetchBuyers(url: ApiClient.toRelativeUrl(state.previousUrl!));
    }
  }
  Future<void> fetchBuyers({String? url}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {


      final response = await ApiClient().get(endpoint: url ?? "api/super-admin/buyers");



      // Correct check for success
      if (response["data"] != null && response["data"]["success"] == true) {
        final pageData = response["data"]["data"]; // <-- actual page data
        final List<dynamic> buyerList = pageData["data"];



        final buyers = buyerList.map((e) => Buyer.fromJson(e)).toList();
        final buyerCodes = buyers.map((b) => b.bpCode).toList();


        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          buyers: buyers,
          allBuyers: buyers,
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
        error: "Failed to load buyers",
      );
    }
  }
  Future<void> saveBuyer({
    String? url,
    Map<String, dynamic>? field,
    Map<String, dynamic>? files,
    String? method,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      final response = await ApiClient().requestWithFiles(
        method: method ?? "POST",
        endpoint: url ?? "api/super-admin/buyers",
        fields: field,
        files: files,
      );



      final status = response['status'];

      // ✅ SUCCESS CASE
      if (status == 1) {
        final data = response['data'];

        state = state.copyWith(isSaving: false, error: null);

        String msg = (data != null && data['message'] != null)
            ? data['message']
            : (method == "PUT"
            ? 'Buyer updated successfully'
            : 'Buyer created successfully');

        Toaster.showSuccess(msg);

        await fetchBuyers();
        Get.back();
      }

      // ❌ ERROR CASE (ONLY MESSAGE USED)
      else {
        String errorMsg = "Operation failed";

        // Case 1: message object
        if (response['message'] is Map) {
          final msgBlock = response['message'];
          if (msgBlock['message'] != null) {
            errorMsg = msgBlock['message'];
          }
        }

        // Case 2: data message fallback
        else if (response['data'] != null &&
            response['data']['message'] != null) {
          errorMsg = response['data']['message'];
        }

        // Case 3: direct message string
        else if (response['message'] is String) {
          errorMsg = response['message'];
        }

        state = state.copyWith(isSaving: false, error: errorMsg);
        Toaster.showError(errorMsg);
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      Toaster.showError("Network Error: Could not save buyer");
    }
  }
  Future<void> fetchBuyerDetail(int id) async {
    state = state.copyWith(isLoading: true, error: null, selectedBuyer: null);

    final String detailUrl = "api/super-admin/buyers/$id";


    try {
      final response = await ApiClient().get(endpoint: detailUrl);



      // Based on your previous logic, we check for status 1 or success true
      if (response["data"] != null && (response["data"]["success"] == true || response["status"] == 1)) {

        // Assuming the detailed buyer object is inside response["data"]["data"]
        final dynamic buyerData = response["data"]["data"];

        if (buyerData != null) {
          final Buyer detail = Buyer.fromJson(buyerData);



          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            selectedBuyer: detail,
          );
        } else {
          throw Exception("Buyer data is empty");
        }
      } else {

        state = state.copyWith(
          isLoading: false,
          error: response["message"] ?? "Failed to load details",
        );
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isLoading: false,
        error: "An error occurred while fetching details",
      );
      Toaster.showError("Could not load buyer profile");
    }
  }

  /// ===============================
  /// FILTER
  /// ===============================

  /// ===============================
  /// SORT
  /// ===============================
  void sortBuyers(String sortKey, {bool ascending = true}) {
    final list = List<Buyer>.from(state.buyers);

    int compare<T extends Comparable>(T? a, T? b) {
      if (a == null && b == null) return 0;
      if (a == null) return -1;
      if (b == null) return 1;
      return a.compareTo(b);
    }

    list.sort((a, b) {
      int result = 0;

      switch (sortKey) {
        case 'Buyer Code':
          result = compare(a.bpCode, b.bpCode);
          break;
        case 'Buyer Name':
          result = compare(a.name, b.name);
          break;
        case 'Mobile':
          result = compare(a.mobile, b.mobile);
          break;
      }

      return ascending ? result : -result;
    });

    state = state.copyWith(buyers: list);
  }

  /// ===============================
  /// RESET
  /// ===============================
  void resetBuyersPartners() {
    state = state.copyWith(
      buyers: state.allBuyers,
      error: null,
      isLoaded: true,
    );
  }
}
final buyerListProvider =
StateNotifierProvider<BuyerListNotifier, BuyerState>(
      (ref) => BuyerListNotifier(ref),
);