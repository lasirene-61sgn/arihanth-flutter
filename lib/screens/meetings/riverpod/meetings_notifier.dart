import 'package:arianth/screens/meetings/model/meeting_model.dart';
import 'package:arianth/screens/meetings/model/meeting_participant_model.dart';
import 'package:arianth/screens/meetings/ui/video_call_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';
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
  final List<String> categories;
  final List<MeetingParticipantModel> participants;
  final bool isLoadingCategories;
  final bool isLoadingParticipants;

  const MeetingsState({
    this.isLoading = false,
    this.isLoaded = false,
    this.approvingMeetingId,
    this.cancellingMeetingId,
    this.isSaving = false,
    this.joiningRoomId,
    this.error,
    this.meetings = const [],
    this.categories = const [],
    this.participants = const [],
    this.isLoadingCategories = false,
    this.isLoadingParticipants = false,
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
    List<String>? categories,
    List<MeetingParticipantModel>? participants,
    bool? isLoadingCategories,
    bool? isLoadingParticipants,
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
      categories: categories ?? this.categories,
      participants: participants ?? this.participants,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLoadingParticipants: isLoadingParticipants ?? this.isLoadingParticipants,
    );
  }
}

class MeetingsNotifier extends StateNotifier<MeetingsState> {
  MeetingsNotifier() : super(const MeetingsState());

  Future<void> fetchCategories() async {
    state = state.copyWith(isLoadingCategories: true, error: null);
    try {
      final response = await ApiClient().get(endpoint: "api/common/meetings/participants");
      print("category$response");
      if (response != null && response["status"] == 1 && response["data"] != null && response["data"]["success"] == true) {
        final categoriesList = response["data"]["allowed_categories"];
        if (categoriesList is List) {
          state = state.copyWith(
            categories: List<String>.from(categoriesList),
            isLoadingCategories: false,
          );
        } else {
          state = state.copyWith(isLoadingCategories: false);
        }
      } else {
        state = state.copyWith(isLoadingCategories: false, error: response?["message"] ?? "Failed to load categories");
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingCategories: false,
        error: "Failed to load categories: ${e.toString()}",
      );
    }
  }

  Future<void> fetchParticipants(String category) async {
    state = state.copyWith(isLoadingParticipants: true, error: null, participants: []);
    try {
      final response = await ApiClient().get(endpoint: "api/common/meetings/participants?category=$category");
      print("response------- $response");
      if (response != null && response["status"] == 1 && response["data"] != null && response["data"]["success"] == true) {
        final data = response["data"]["data"];
        if (data is List) {
          final participants = data.map((item) => MeetingParticipantModel.fromJson(item)).toList();
          state = state.copyWith(
            participants: participants,
            isLoadingParticipants: false,
          );
        } else {
          state = state.copyWith(isLoadingParticipants: false);
        }
      } else {
        state = state.copyWith(isLoadingParticipants: false, error: response?["message"] ?? "Failed to load participants");
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingParticipants: false,
        error: "Failed to load participants: ${e.toString()}",
      );
    }
  }

  Future<void> fetchParticipantsForRoles(List<String> roles) async {
    if (roles.isEmpty) {
      state = state.copyWith(participants: []);
      return;
    }
    state = state.copyWith(isLoadingParticipants: true, error: null, participants: []);
    try {
      final List<MeetingParticipantModel> allParticipants = [];
      for (final role in roles) {
        final response = await ApiClient().get(endpoint: "api/common/meetings/participants?category=$role");
        print("============$response");
        if (response != null && response['status'] == 1 && response["data"] != null && response["data"]["success"] == true) {
          final data = response["data"]['data'];
          if (data is List) {
            final participants = data.map((item) => MeetingParticipantModel.fromJson(item)).toList();
            allParticipants.addAll(participants);
          }
        }
      }
      state = state.copyWith(
        participants: allParticipants,
        isLoadingParticipants: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingParticipants: false,
        error: "Failed to load participants: ${e.toString()}",
      );
    }
  }

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
      print(response);

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
  Future<void> joinMeeting(String roomId, {String? opponentName, int? meetingId}) async {
    state = state.copyWith(joiningRoomId: roomId);
    debugPrint("Attempting to join meeting: $roomId");
    try {
      if (opponentName != null && opponentName.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('caller_name_$roomId', opponentName);
        } catch (e) {
          debugPrint("Error saving opponent name: $e");
        }
      }
      if (meetingId != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('meeting_id_$roomId', meetingId);
        } catch (e) {
          debugPrint("Error saving meeting ID: $e");
        }
      }
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
              // Trigger CallKit outgoing call registration to add it to system call logs
              final uuid = const Uuid().v4();
              final callKitParams = CallKitParams(
                id: uuid,
                nameCaller: opponentName ?? 'Meeting Invitation',
                appName: 'Arihanth',
                handle: roomId,
                type: 0, // 0: Audio, 1: Video
                duration: 30000,
                extra: <String, dynamic>{'room_id': roomId},
                android: const AndroidParams(
                  isCustomNotification: true,
                  isShowLogo: true,
                  ringtonePath: 'system_ringtone_default',
                  backgroundColor: '#A57C52',
                  actionColor: '#4CAF50',
                ),
                ios: const IOSParams(
                  iconName: 'AppIcon',
                  handleType: 'generic',
                  supportsVideo: true,
                ),
              );
              await FlutterCallkitIncoming.startCall(callKitParams);

              Get.to(() => VideoCallScreen(
                appId: agoraData["app_id"],
                channelName: agoraData["channel_name"],
                token: agoraData["token"],
                uid: agoraData["uid"] is int ? agoraData["uid"] : int.tryParse(agoraData["uid"].toString()) ?? 0,
                opponentName: opponentName,
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
