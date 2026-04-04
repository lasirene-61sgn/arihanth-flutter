import 'dart:convert';
import 'dart:io';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';


import '../../../services/widget/custom_msg.dart';
import '../model/key_user_model.dart';

class KeyUserListState {
  final bool isLoading;
  final bool isSaving;
  final bool isLoaded;
  final String? error;
  final List<KeyUser> keyUsers;
  final List<KeyUser> allKeyUsers;
  final int count;
  final String? nextUrl;
  final String? previousUrl;
  final KeyUser? keyUserDetail;

  const KeyUserListState({
    this.isLoading = false,
    this.isSaving = false,
    this.isLoaded = false,
    this.error,
    this.keyUsers = const [],
    this.allKeyUsers = const [],
    this.count = 0,
    this.nextUrl,
    this.previousUrl,
    this.keyUserDetail,
  });

  KeyUserListState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isLoaded,
    String? error,
    List<KeyUser>? keyUsers,
    List<KeyUser>? allKeyUsers,
    int? count,
    String? nextUrl,
    String? previousUrl,
    KeyUser? keyUserDetail,
    bool clearDetail = false, // ADD THIS FLAG
  }) {
    return KeyUserListState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isLoaded: isLoaded ?? this.isLoaded,
      error: error,
      keyUsers: keyUsers ?? this.keyUsers,
      allKeyUsers: allKeyUsers ?? this.allKeyUsers,
      count: count ?? this.count,
      nextUrl: nextUrl,
      previousUrl: previousUrl,
      // If clearDetail is true, force it to null. Otherwise, behave normally.
      keyUserDetail: clearDetail ? null : (keyUserDetail ?? this.keyUserDetail),
    );
  }
}

class KeyUserListNotifier extends StateNotifier<KeyUserListState> {
  KeyUserListNotifier() : super(KeyUserListState());
  void goToNextPage() {
    if (state.nextUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.nextUrl!);
      print("final next ->$relativeUrl");
      state = state.copyWith(keyUsers: []);
      fetchKeyUsers(url: relativeUrl);
    }
  }

  void goToPreviousPage() {
    if (state.previousUrl != null) {
      final relativeUrl = ApiClient.toRelativeUrl(state.previousUrl!);
      state = state.copyWith(keyUsers: []);
      fetchKeyUsers(url: relativeUrl);
    }
  }
  Future<void> fetchKeyUsers({String? url}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final effectiveEndpoint = url ?? "api/common/key-users";
      final response = await ApiClient().get(endpoint: effectiveEndpoint);



      // 1. Access the first 'data' level
      final outerData = response["data"];

      // 2. Check success inside the 'data' object based on your log
      final bool isSuccess = outerData != null && outerData["success"] == true;

      if (isSuccess) {
        // 3. The actual pagination/user data is in outerData["data"]
        final paginationData = outerData["data"];
        final List<dynamic>? userListArray = paginationData["data"];

        if (userListArray != null) {
          final keyUsers = userListArray.map((item) => KeyUser.fromJson(item)).toList();

          state = state.copyWith(
            isLoading: false,
            isLoaded: true,
            keyUsers: keyUsers,
            allKeyUsers: keyUsers,
            count: paginationData["total"] ?? 0,
            nextUrl: paginationData["next_page_url"],
            previousUrl: paginationData["prev_page_url"],
            error: null,
          );

        } else {
          _handleError("User array is missing in pagination data.");
        }
      } else {
        // Handle logic failure from server message
        String errorMsg = outerData?["message"] ?? "Server returned success: false";
        _handleError(errorMsg);
      }
    } catch (e, stackTrace) {

      state = state.copyWith(
        isLoading: false,
        isLoaded: false,
        error: "Connection error: ${e.toString()}",
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
  /// Save a KeyUser (create if id is null, update if id is present)
  /// Save a KeyUser (create if id is null, update if id is present)
  Future<void> saveKeyUser(
      String method,
      Map<String, dynamic>? files,
      Map<String, dynamic> map, {
        String? id,
        String? url,
      }) async {
    // 1. Set saving state and clear any previous errors
    state = state.copyWith(isSaving: true, error: null);

    try {
      final endpoint = url ?? "api/common/key-users${id ?? ""}";


      // 2. Make the API request
      final response = await ApiClient().requestWithFiles(
        method: method,
        endpoint: endpoint,
        fields: map,
        files: files,
      );



      // Extract the results payload (API often puts it in 'data' on success and 'message' on failure)
      final resPayload = response['data'] is Map 
          ? response['data'] 
          : (response['message'] is Map ? response['message'] : null);

      // Determine success: Check top-level status and inner success flag
      final bool isSuccess = (response["status"] == 1 || response["success"] == true) && 
                             (resPayload == null || resPayload["success"] != false);

      if (isSuccess) {
        final successMsg = resPayload?['message']?.toString() ?? "Saved successfully";
        Toaster.showSuccess(successMsg);

        state = state.copyWith(isSaving: false, error: null);
        await fetchKeyUsers();
        Get.back();
      } else {
        // Extract detailed error message (checking both top-level and nested maps)
        String errorMsg = "Failed to save Key User";
        
        // Use the resPayload if it exists, otherwise fall back to response
        final mapForError = resPayload ?? response;

        if (mapForError['errors'] is Map) {
          final errors = mapForError['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMsg = firstError.first.toString();
            } else {
              errorMsg = firstError.toString();
            }
          }
        } else if (mapForError['message'] != null) {
          errorMsg = mapForError['message'].toString();
        }

        Toaster.showError(errorMsg);

        state = state.copyWith(
          isSaving: false,
          error: errorMsg,
        );

      }
    } catch (e, stackTrace) {
      // 7. Handle network or parsing exceptions


      state = state.copyWith(
        isSaving: false,
        error: "Failed to save key user: ${e.toString()}",
      );
    }
  }
  /// Fetch details of a single KeyUser
  Future<void> keyUserDetails(String id) async {
    // 1. INITIAL STATE: Show loader, clear old errors, and wipe previous user details
    state = state.copyWith(
      isLoading: true,
      error: null,
      clearDetail: true,
    );

    try {
      // 2. FETCH DATA
      final response = await ApiClient().get(endpoint: "api/common/key-users/$id");
      final responseData = response["data"]; // The outer wrapper containing 'success' and 'data'



      // 3. VALIDATE RESPONSE
      if (responseData != null && responseData["success"] == true) {
        final actualUserData = responseData["data"];

        // Defensive check: Ensure the inner data actually exists before parsing
        if (actualUserData != null) {
          final keyUserDetail = KeyUser.fromJson(actualUserData);

          // 4. SUCCESS STATE: Stop loader, inject new data
          state = state.copyWith(
            isLoading: false,
            error: null,
            keyUserDetail: keyUserDetail,
          );

          return; // Exit function early on success
        }
      }

      // 5. API LOGIC ERROR STATE (e.g., success is false, or data was null)
      String errorMsg = responseData?["message"] ?? "Key User details not found";

      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
        clearDetail: true, // Ensure UI stays clean if it fails
      );


    } catch (e, stackTrace) {
      // 6. EXCEPTION STATE (Network failure, JSON parsing error, etc.)


      state = state.copyWith(
        isLoading: false,
        error: "Failed to load key user details: ${e.toString()}",
        clearDetail: true,
      );
    }
  }
}

final keyUserProvider =
StateNotifierProvider<KeyUserListNotifier, KeyUserListState>(
      (ref) => KeyUserListNotifier(),
);
