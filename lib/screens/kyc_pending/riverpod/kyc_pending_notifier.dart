import 'dart:convert';
import 'dart:io';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart';


import '../model/kyc_pending.dart';

class KycPendingState {
  final bool isLoading;
  final bool isLoaded;
  final String? error;

  final List<KycBuyer> pendingBuyers;
  final List<KycCraftsman> pendingCraftsmen;

  const KycPendingState({
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
    this.pendingBuyers = const [],
    this.pendingCraftsmen = const [],
  });

  KycPendingState copyWith({
    bool? isLoading,
    bool? isLoaded,
    String? error,
    List<KycBuyer>? pendingBuyers,
    List<KycCraftsman>? pendingCraftsmen,
  }) {
    return KycPendingState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      pendingBuyers: pendingBuyers ?? this.pendingBuyers,
      pendingCraftsmen: pendingCraftsmen ?? this.pendingCraftsmen,
    );
  }
}
class KycPendingNotifier extends StateNotifier<KycPendingState> {
  KycPendingNotifier() : super(const KycPendingState());

  Future<void> fetchKycPending() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().get(endpoint: "api/super-admin/kyc-pending");



      // ✅ Extract the inner 'data' first
      final innerData = response["data"]?["data"];
      final bool success = response["data"]?["success"] == true;


      if (success && innerData != null) {
        // Parse buyers
        final buyers = (innerData["pending_buyers"] as List? ?? [])
            .map((e) => KycBuyer.fromJson(e))
            .toList();

        // Parse craftsmen
        final craftsmen = (innerData["pending_craftsmen"] as List? ?? [])
            .map((e) => KycCraftsman.fromJson(e))
            .toList();

        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          pendingBuyers: buyers,
          pendingCraftsmen: craftsmen,
        );


      } else {
        final msg = response["data"]?["message"] ?? "Failed to fetch KYC pending data";

        _handleError(msg);
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isLoading: false,
        isLoaded: false,
        error: e.toString(),
      );
    }
  }

  void _handleError(String message) {
    state = state.copyWith(
      isLoading: false,
      isLoaded: false,
      error: message,
    );
  }
}
final kycPendingProvider =
StateNotifierProvider<KycPendingNotifier, KycPendingState>(
      (ref) => KycPendingNotifier(),
);