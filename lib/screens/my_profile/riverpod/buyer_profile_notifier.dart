import 'package:arianth/screens/my_profile/model/buyer_profile_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';

import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class BuyerProfileState {
  final bool isLoading;
  final bool isSaving;
  final BuyerProfileModel? profile;
  final String? error;

  BuyerProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.profile,
    this.error,
  });

  BuyerProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    BuyerProfileModel? profile,
    String? error,
  }) {
    return BuyerProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

class BuyerProfileNotifier extends StateNotifier<BuyerProfileState> {
  final Ref ref;

  BuyerProfileNotifier(this.ref) : super(BuyerProfileState());

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().get(endpoint: "api/common/buyer/profile");


      if (response["status"] == 1 || (response["data"] != null && response["data"]["success"] == true)) {
        final dynamic data = response["data"]?["data"] ?? response["data"];
        
        dynamic profileData = data is Map ? (data["buyer"] ?? data) : data;

        if (profileData != null) {
          final profile = BuyerProfileModel.fromJson(profileData);
          state = state.copyWith(isLoading: false, profile: profile);
        } else {
          state = state.copyWith(isLoading: false, error: "Buyer Profile data not found");
        }
      } else {
        state = state.copyWith(isLoading: false, error: response["message"] ?? "Failed to load buyer profile");
      }
    } catch (e, stackTrace) {

      state = state.copyWith(isLoading: false, error: "Failed to load buyer profile");
    }
  }

  Future<bool> updateProfile({
    required Map<String, dynamic> fields,
    required Map<String, dynamic> files,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      final response = await ApiClient().requestWithFiles(
        method: "POST",
        endpoint: "api/common/buyer/profile",
        fields: fields,
        files: files,
      );


      final responseData = response['data'] ?? response;

      if (response['status'] == 1 || responseData['success'] == true) {
        state = state.copyWith(isSaving: false);
        Toaster.showSuccess(responseData['message'] ?? "Buyer profile updated successfully");
        await fetchProfile();
        return true;
      } else {
        String errorMsg = responseData['message'] ?? "Update failed";
        state = state.copyWith(isSaving: false, error: errorMsg);
        Toaster.showError(errorMsg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      Toaster.showError("Network Error: Could not update buyer profile");
      return false;
    }
  }
}

final buyerProfileNotifierProvider = StateNotifierProvider<BuyerProfileNotifier, BuyerProfileState>(
  (ref) => BuyerProfileNotifier(ref),
);
