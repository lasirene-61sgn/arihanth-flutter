import 'dart:convert';
import 'dart:io';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';


import '../../../services/widget/custom_msg.dart';
import '../model/user_model.dart';

class UserListState {
  final bool isLoading; // For fetch operations
  final bool isSaving; // For create/update operations
  final bool isLoaded;
  final String? error;
  final List<User> users;
  final User? userDetail;
  final String? nextUrl;
  final String? previousUrl;
  final int count;

  const UserListState({
    this.isLoading = false,
    this.isSaving = false,
    this.isLoaded = false,
    this.error,
    this.users = const [],
    this.userDetail,
    this.nextUrl,
    this.previousUrl,
    this.count = 0,
  });

  UserListState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isLoaded,
    String? error,
    List<User>? users,
    User? userDetail,
    dynamic nextUrl = _sentinel,
    dynamic previousUrl = _sentinel,
    int? count,
  }) {
    return UserListState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      users: users ?? this.users,
      userDetail: userDetail ?? this.userDetail,
      nextUrl: nextUrl == _sentinel ? this.nextUrl : nextUrl as String?,
      previousUrl: previousUrl == _sentinel ? this.previousUrl : previousUrl as String?,
      count: count ?? this.count,
    );
  }
}

const _sentinel = Object();

class UserListNotifier extends StateNotifier<UserListState> {
  UserListNotifier() : super(const UserListState());

  void goToNextPage() {
    if (state.nextUrl != null && !state.isLoading) {
      fetchUsers(urls: ApiClient.toRelativeUrl(state.nextUrl!));
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null && !state.isLoading) {
      fetchUsers(urls: ApiClient.toRelativeUrl(state.previousUrl!));
    }
  }

  /// Fetch the list of users from API
  Future<void> fetchUsers({String? urls}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final String endpoint = urls ?? "api/common/users";
      final response = await ApiClient().get(endpoint: endpoint);

      // Accessing outer data layer
      final outerData = response["data"];
      if (outerData != null && outerData["success"] == true) {
        final paginationData = outerData["data"];
        if (paginationData != null) {
          final List<dynamic>? userListArray = paginationData["data"];
          final users = userListArray?.map((item) => User.fromJson(item)).toList() ?? [];

          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            users: users,
            nextUrl: paginationData["next_page_url"],
            previousUrl: paginationData["prev_page_url"],
            count: paginationData["total"] as int? ?? 0,
            error: null,
          );
        } else {
          _handleError("User data nested object not found");
        }
      } else {
        _handleError(outerData?["message"] ?? "Failed to fetch users");
      }
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        error: "Connection error: ${e.toString()}",
      );
    }
  }
  /// Updated Save User following your AdminNotifier pattern
  Future<void> saveUser(
      Map<String, dynamic> map, {
        String? url,
        String? method,
      }) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      // 1. Execute request based on method passed from UI
      final response = method == "POST"
          ? await ApiClient().post(endpoint: url ?? "api/common/users", body: map)
          : await ApiClient().put(endpoint: url ?? "api/common/users", body: map);



      // 2. Handle standard success format (status: 1)
      if (response["status"] == 1) {
        await fetchUsers(); // Refresh the list
        Get.back(); // Navigate back
        Toaster.showSuccess("User saved successfully");

        state = state.copyWith(isSaving: false, error: null);
      } else {
        // 3. Extract specific validation messages if status is 0
        String errorMsg = "Save failed";

        if (response["message"] != null) {
          final msgData = response["message"];
          // If it contains a nested errors object (like the 422 password error)
          if (msgData is Map && msgData["errors"] != null) {
            var errors = msgData["errors"] as Map<String, dynamic>;
            errorMsg = errors.values.map((e) => (e as List).join(", ")).join("\n");
          } else {
            errorMsg = msgData.toString();
          }
        }

        Toaster.showError(errorMsg);
        state = state.copyWith(isSaving: false, error: errorMsg);
      }
    } catch (e, stackTrace) {


      String displayError = "Network or Validation Error: Check your input.";
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      Toaster.showError(displayError);
    }
  }

  /// Fetch details of a single User
  Future<void> userDetails(String id) async {
    state = state.copyWith(isLoading: true, error: null); // Using isLoading for detail fetch

    try {
      final response = await ApiClient().get(endpoint: "api/common/users/$id");
      final outerData = response["data"];

      if (outerData != null && outerData['data'] != null) {
        final userDetail = User.fromJson(outerData['data']);
        state = state.copyWith(
          isLoading: false,
          userDetail: userDetail,
          error: null,
        );

      } else {
        _handleError("User details not found in response.");
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isLoading: false,
        error: "Failed to load details: ${e.toString()}",
      );
    }
  }

  /// Helper to handle non-critical logic errors
  void _handleError(String message) {

    state = state.copyWith(
      isLoading: false,
      isSaving: false,
      isLoaded: false,
      error: message,
    );
  }
}

/// Riverpod provider
final userProvider =
StateNotifierProvider<UserListNotifier, UserListState>(
      (ref) => UserListNotifier(),
);
