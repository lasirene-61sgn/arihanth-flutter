import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/meetings/riverpod/video_call_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String appId;
  final String channelName;
  final String token;
  final int uid;

  const VideoCallScreen({
    super.key,
    required this.appId,
    required this.channelName,
    required this.token,
    required this.uid,
  });

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(videoCallProvider.notifier).initAgora(
            appId: widget.appId,
            channelName: widget.channelName,
            token: widget.token,
            uid: widget.uid,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(videoCallProvider);
    final notifier = ref.read(videoCallProvider.notifier);

    // Handle errors from state
    if (callState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Toaster.showError(callState.error!);
        Navigator.pop(context);
      });
    }

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: !callState.isInitialized
            ? _buildLoadingState()
            : Stack(
                children: [
                  // Remote Video (Full Screen)
                  _buildRemoteVideo(callState, notifier),
                  
                  // Local Video (Small Overlay)
                  _buildLocalVideo(callState, notifier),

                  // Call Info Overlay
                  _buildCallInfo(),

                  // Bottom Toolbar
                  _buildToolbar(callState, notifier),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColor.primary),
          const SizedBox(height: 24),
          Text(
            'Initializing Secure Connection...',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCallInfo() {
    return Positioned(
      top: 50,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LIVE | ${widget.channelName.substring(0, 8)}...',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteVideo(VideoCallState state, VideoCallNotifier notifier) {
    if (state.remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: notifier.engine!,
          canvas: VideoCanvas(uid: state.remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 100, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              'Waiting for participant...',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLocalVideo(VideoCallState state, VideoCallNotifier notifier) {
    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        width: 110,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: state.localUserJoined && !state.isVideoOff
              ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: notifier.engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
              : Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.videocam_off, color: Colors.white30),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildToolbar(VideoCallState state, VideoCallNotifier notifier) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildControlButton(
              icon: state.isMuted ? Icons.mic_off : Icons.mic,
              color: state.isMuted ? Colors.redAccent : Colors.white,
              onTap: () => notifier.toggleMute(),
            ),
            const SizedBox(width: 20),
            _buildControlButton(
              icon: Icons.call_end,
              color: Colors.red,
              size: 32,
              isFilled: true,
              onTap: () async {
                if (await _onWillPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(width: 20),
            _buildControlButton(
              icon: state.isVideoOff ? Icons.videocam_off : Icons.videocam,
              color: state.isVideoOff ? Colors.redAccent : Colors.white,
              onTap: () => notifier.toggleVideo(),
            ),
            const SizedBox(width: 20),
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              color: Colors.white,
              onTap: () => notifier.switchCamera(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 24,
    bool isFilled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFilled ? color : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isFilled ? Colors.white : color, size: size),
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Call?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to disconnect from this meeting?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('STAY', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('END CALL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
