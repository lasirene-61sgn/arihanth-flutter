import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallState {
  final int? remoteUid;
  final bool localUserJoined;
  final bool isMuted;
  final bool isVideoOff;
  final bool isFrontCamera;
  final bool isInitialized;
  final String? error;

  VideoCallState({
    this.remoteUid,
    this.localUserJoined = false,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isFrontCamera = true,
    this.isInitialized = false,
    this.error,
  });

  VideoCallState copyWith({
    int? remoteUid,
    bool? localUserJoined,
    bool? isMuted,
    bool? isVideoOff,
    bool? isFrontCamera,
    bool? isInitialized,
    String? error,
    bool clearRemoteUid = false,
  }) {
    return VideoCallState(
      remoteUid: clearRemoteUid ? null : (remoteUid ?? this.remoteUid),
      localUserJoined: localUserJoined ?? this.localUserJoined,
      isMuted: isMuted ?? this.isMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }
}

class VideoCallNotifier extends StateNotifier<VideoCallState> {
  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  VideoCallNotifier() : super(VideoCallState());

  Future<void> initAgora({
    required String appId,
    required String channelName,
    required String token,
    required int uid,
  }) async {
    try {
      final status = await [Permission.microphone, Permission.camera].request();
      
      final micGranted = status[Permission.microphone] == PermissionStatus.granted;
      // We are lenient with camera for simulators, but ideally both should be granted
      if (!micGranted) {
        state = state.copyWith(error: "Microphone permission is required");
        return;
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) state = state.copyWith(localUserJoined: true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted) state = state.copyWith(remoteUid: remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (mounted) state = state.copyWith(clearRemoteUid: true);
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint("Agora Error: $err, $msg");
          },
        ),
      );

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableVideo();
      await _engine!.startPreview();

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(),
      );
      
      if (mounted) state = state.copyWith(isInitialized: true);
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }

  void toggleMute() {
    final newState = !state.isMuted;
    _engine?.muteLocalAudioStream(newState);
    state = state.copyWith(isMuted: newState);
  }

  void toggleVideo() {
    final newState = !state.isVideoOff;
    _engine?.muteLocalVideoStream(newState);
    state = state.copyWith(isVideoOff: newState);
  }

  void switchCamera() {
    _engine?.switchCamera();
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }

  Future<void> leaveChannel() async {
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      await engine.leaveChannel();
      await engine.release();
    }
    if (mounted) state = VideoCallState();
  }

  @override
  void dispose() {
    leaveChannel();
    super.dispose();
  }
}

final videoCallProvider = StateNotifierProvider.autoDispose<VideoCallNotifier, VideoCallState>((ref) {
  return VideoCallNotifier();
});
