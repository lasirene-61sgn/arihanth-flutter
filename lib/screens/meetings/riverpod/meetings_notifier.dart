import 'package:arianth/screens/meetings/model/meeting_model.dart';
import 'package:arianth/screens/meetings/ui/video_call_screen.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';

const _sentinel = Object();

class MeetingsState {
  final bool isLoading;
  final bool isLoaded;
  final String? approvingMeetingId;
  final String? cancellingMeetingId;
  final bool isSaving;
  final String? joiningRoomId;
  final String? error;
  final List<MeetingModel> meetings;

  const MeetingsState({
    this.isLoading = false,
    this.isLoaded = false,
    this.approvingMeetingId,
    this.cancellingMeetingId,
    this.isSaving = false,
    this.joiningRoomId,
    this.error,
    this.meetings = const [],
  });

  MeetingsState copyWith({
    bool? isLoading,
    bool? isLoaded,
    dynamic approvingMeetingId = _sentinel,
    dynamic cancellingMeetingId = _sentinel,
    bool? isSaving,
    dynamic joiningRoomId = _sentinel,
    dynamic error = _sentinel,
    List<MeetingModel>? meetings,
  }) {
    return MeetingsState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      approvingMeetingId: approvingMeetingId == _sentinel ? this.approvingMeetingId : approvingMeetingId as String?,
      cancellingMeetingId: cancellingMeetingId == _sentinel ? this.cancellingMeetingId : cancellingMeetingId as String?,
      isSaving: isSaving ?? this.isSaving,
      joiningRoomId: joiningRoomId == _sentinel ? this.joiningRoomId : joiningRoomId as String?,
      error: error == _sentinel ? this.error : error as String?,
      meetings: meetings ?? this.meetings,
    );
  }
}

class MeetingsNotifier extends StateNotifier<MeetingsState> {
  MeetingsNotifier() : super(const MeetingsState());

  Future<void> fetchMeetings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().get(endpoint: "api/common/meetings");

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        
        List<dynamic> meetingList = [];
        if (actualResponse is List) {
          meetingList = actualResponse;
        } else if (actualResponse is Map) {
          final bool isSuccess = actualResponse["success"] ?? true;
          if (isSuccess) {
            dynamic rawData = actualResponse["data"] ?? actualResponse;
            if (rawData is List) {
              meetingList = rawData;
            }
          } else {
            state = state.copyWith(
              isLoading: false,
              error: actualResponse["message"] ?? "Failed to load meetings",
            );
            return;
          }
        }

        final meetings = meetingList.map((item) => MeetingModel.fromJson(item)).toList();

        state = state.copyWith(
          isLoading: false,
          isLoaded: true,
          meetings: meetings,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response?["message"] ?? "Failed to load meetings",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to load meetings: ${e.toString()}",
      );
    }
  }

  Future<void> saveMeeting(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/meetings",
        body: data,
      );

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        final bool isSuccess = actualResponse["success"] ?? true;
        
        if (isSuccess) {
          Toaster.showSuccess('Meeting scheduled successfully');
          state = state.copyWith(isSaving: false);
          await fetchMeetings(); // Refresh the list
          Get.back();
        } else {
          final errorMsg = actualResponse["message"] ?? "Failed to create meeting";
          Toaster.showError(errorMsg);
          state = state.copyWith(
            isSaving: false,
            error: errorMsg,
          );
        }
      } else {
        final errorMsg = response?["message"] ?? "Failed to create meeting";
        Toaster.showError(errorMsg);
        state = state.copyWith(
          isSaving: false,
          error: errorMsg,
        );
      }
    } catch (e) {
      final errorMsg = "Failed to create meeting: ${e.toString()}";
      Toaster.showError(errorMsg);
      state = state.copyWith(
        isSaving: false,
        error: errorMsg,
      );
    }
  }

  Future<void> approveMeeting(int id) async {
    state = state.copyWith(approvingMeetingId: id.toString());
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/meetings/$id/approve",
        body: {},
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Meeting approved successfully");
        await fetchMeetings();
      } else {
        Toaster.showError(response?["message"] ?? "Failed to approve meeting");
      }
    } catch (e) {
      Toaster.showError("Error: ${e.toString()}");
    } finally {
      state = state.copyWith(approvingMeetingId: null);
    }
  }

  Future<void> rejectMeeting(int id) async {
    state = state.copyWith(cancellingMeetingId: id.toString());
    try {
      final response = await ApiClient().post(
        endpoint: "api/common/meetings/$id/cancel",
        body: {},
      );

      if (response != null && response["status"] == 1) {
        Toaster.showSuccess("Meeting cancelled successfully");
        await fetchMeetings();
      } else {
        Toaster.showError(response?["message"] ?? "Failed to cancel meeting");
      }
    } catch (e) {
      Toaster.showError("Error: ${e.toString()}");
    } finally {
      state = state.copyWith(cancellingMeetingId: null);
    }
  }
  Future<void> joinMeeting(String roomId) async {
    state = state.copyWith(joiningRoomId: roomId);
    debugPrint("Attempting to join meeting: $roomId");
    try {
      final response = await ApiClient().get(
        endpoint: "api/common/meetings/$roomId/token",
      );

      debugPrint("Join meeting response: $response");

      if (response != null && response["status"] == 1) {
        final actualResponse = response["data"];
        debugPrint("Actual join data: $actualResponse");
        if (actualResponse != null && actualResponse["success"] == true) {
          final agoraData = actualResponse["data"];
          if (agoraData != null) {
            debugPrint("Agora Data extracted: $agoraData");
            
            // --- Permission Check ---
            final cameraStatus = await Permission.camera.request();
            final micStatus = await Permission.microphone.request();

            if (cameraStatus.isGranted && micStatus.isGranted) {
              Get.to(() => VideoCallScreen(
                appId: agoraData["app_id"],
                channelName: agoraData["channel_name"],
                token: agoraData["token"],
                uid: agoraData["uid"] is int ? agoraData["uid"] : int.tryParse(agoraData["uid"].toString()) ?? 0,
              ));
            } else {
              Toaster.showError("Camera and Microphone permissions are required to join the meeting. Please enable them in Settings.");
            }
          } else {
            debugPrint("Error: Agora data is null");
            Toaster.showError("Failed to retrieve Agora credentials");
          }
        } else {
          final errorMsg = actualResponse?["message"] ?? "Failed to join meeting";
          debugPrint("Error joining meeting: $errorMsg");
          Toaster.showError(errorMsg);
        }
      } else {
        final errorMsg = response?["message"] ?? "Failed to fetch meeting token";
        debugPrint("API Error: $errorMsg");
        Toaster.showError(errorMsg);
      }
    } catch (e, stackTrace) {
      debugPrint("Exception in joinMeeting: $e");
      debugPrint("Stacktrace: $stackTrace");
      Toaster.showError("Error: ${e.toString()}");
    } finally {
      state = state.copyWith(joiningRoomId: null);
    }
  }
}

final meetingsProvider = StateNotifierProvider<MeetingsNotifier, MeetingsState>((ref) {
  return MeetingsNotifier();
});
