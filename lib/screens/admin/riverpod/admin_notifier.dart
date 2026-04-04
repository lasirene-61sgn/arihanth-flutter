import 'dart:convert';
import 'dart:io';
import 'package:arianth/screens/admin/model/admin_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';

import '../../../services/widget/custom_msg.dart';

class AdminListState {
  final bool isLoading; // For fetch operations
  final bool isSaving; // For create/update operations
  final bool isLoaded;
  final String? error;
  final List<Admin> admins;
  final  Admin? adminDetail;

  const AdminListState({
    this.isLoading = false,
    this.isSaving = false,
    this.isLoaded = false,
    this.error,
    this.admins = const [],
    this.adminDetail,
  });

  AdminListState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isLoaded,
    String? error,
    List<Admin>? admins,
    Admin? adminDetail,
  }) {
    return AdminListState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      admins: admins ?? this.admins,
      adminDetail: adminDetail ?? this.adminDetail,
    );
  }
}

class AdminListNotifier extends StateNotifier<AdminListState> {
  AdminListNotifier() : super( AdminListState());

  /// Fetch the list of admins from API
  Future<void> fetchAdmins({String? url}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response =
      await ApiClient().get(endpoint: url ?? "api/super-admin/admins");

      print("++++ Admin API Response: $response");

      if (response["status"] == 1) {
        final List<dynamic>? adminList =
        response["data"]?["data"] as List<dynamic>?;

        if (adminList != null) {
          final admins =
          adminList.map((item) => Admin.fromJson(item)).toList();

          print("++++ Parsed Admins: $admins");

          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            admins: admins,
          );
        } else {
          throw Exception('Admin list not found');
        }
      } else {
        throw Exception('Invalid response status');
      }
    } catch (e, stackTrace) {
      print("Admin fetch error: $e");
      print(stackTrace);

      state = state.copyWith(
        isLoading: false,
        isLoaded: false,
        error: "Failed to load data: ${e.toString()}",
      );
    }
  }

  Future<void> saveAdmin(Map<String, dynamic> map, {String? url, String? method}) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final response = await ApiClient().post(endpoint: url ?? "api/super-admin/admins", body: map);

      // Handle standard success format
      if (response["status"] == 1) {
        await fetchAdmins();
        state = state.copyWith(isSaving: false);
        Get.back();
        Toaster.showSuccess("Admin saved successfully");
      } else {
        // Extract specific validation messages if status is 0
        String errorMsg = "Save failed";
        if (response["message"] != null && response["message"]["errors"] != null) {
          var errors = response["message"]["errors"] as Map<String, dynamic>;
          // Join all error messages into one string
          errorMsg = errors.values.map((e) => (e as List).join(", ")).join("\n");
        }
        Toaster.showError(errorMsg);
        state = state.copyWith(isSaving: false, error: errorMsg);
      }
    } catch (e) {
      // This handles Dio 422 errors specifically if your ApiClient doesn't catch them
      Toaster.showError("Network or Validation Error: Check your input.");
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }
  Future<void> adminDetails(String id) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      final response = await ApiClient().get(endpoint: "api/super-admin/admins/$id");
      print("++++ details Response: $response");
      final responseData = response["data"];
      if (responseData["data"] != null) {
        final adminDetail = Admin.fromJson(responseData["data"]);
        print("++++ details Response: $adminDetail");

        state = state.copyWith(
          isSaving: false,
          error: null,
          adminDetail: adminDetail,
        );
      } else {

        throw Exception('Invalid response from details API');
      }
    } catch (e, stackTrace) {
      print("Stack trace: $stackTrace");
      state = state.copyWith(
        isSaving: false,
        error: "Failed to load buyer details: ${e.toString()}",
      );
    }
  }

}

/// Riverpod provider
final adminProvider =
StateNotifierProvider<AdminListNotifier, AdminListState>(
      (ref) => AdminListNotifier(),
);
