import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/chat/model/message_model.dart';
import 'package:arianth/screens/chat/riverpod/chat_detail_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import 'package:get/get.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/screens/main_screen/main_layout.dart';
import 'package:arianth/screens/main_screen/menu_notifier.dart';
import 'package:arianth/screens/work_orders/riverpod/work_orders_notifier.dart';
import 'package:arianth/screens/purchase_order/riverpod/purchase_orders_notifier.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String chatName;
  final String? partnerCode;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.chatName,
    this.partnerCode,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PusherChannelsFlutter? _pusher;

  // Voice recording & playback state
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;
  bool _isRecording = false;
  int _recordDurationSeconds = 0;
  Timer? _recordTimer;
  String? _currentlyPlayingUrl;
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  final Map<String, Duration> _audioKnownDurations = {};

  // Audio download cache: remote URL -> local temp file path
  final Map<String, String> _audioCachePaths = {};
  // URLs currently being downloaded (shows spinner in bubble)
  final Set<String> _downloadingAudioUrls = {};

  // Scroll to bottom (latest message) button state
  bool _showScrollToBottom = false;

  // Super Admin WhatsApp multi-select & forwarding state
  bool _isSuperAdmin = false;
  bool _isSelectMode = false;
  final Set<int> _selectedMessageIndices = {};
  bool _isForwarding = false;

  @override
  void initState() {
    super.initState();
    final role = SharedPreferencesHelper().getString("role")?.toLowerCase();
    _isSuperAdmin = role == "super_admin";
    ChatDetailNotifier.activeConversationId = widget.conversationId;
    ChatDetailNotifier.onActiveMessageReceived = () {
      if (mounted) {
        ref.read(chatDetailProvider.notifier).fetchMessages(widget.conversationId, isSilent: true);
      }
    };
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _initAudioPlayerListeners();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
    _scrollController.addListener(_onChatScroll);
    Future.microtask(() {
      if (mounted) {
        ref.read(chatDetailProvider.notifier).fetchMessages(widget.conversationId);
        _initPusher();
      }
    });
  }

  void _onChatScroll() {
    // In reverse ListView: offset 0 is the bottom (latest message).
    // Scrolling up into chat history increases pixels (> 250 means scrolled up).
    if (!_scrollController.hasClients) return;
    final bool shouldShow = _scrollController.offset > 250;
    if (shouldShow != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = shouldShow;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _initPusher() async {
    try {
      _pusher = PusherChannelsFlutter.getInstance();

      await _pusher!.init(
        apiKey: "9bcfabd864b6ce776339",
        cluster: "ap2",
        onAuthorizer: (channelName, socketId, options) async {
          try {
            debugPrint("Pusher Authorizing channel: $channelName, socketId: $socketId");
            // Call the Laravel broadcasting auth endpoint via ApiClient
            final response = await ApiClient().post(
              endpoint: "api/broadcasting/auth",
              body: {
                "socket_id": socketId,
                "channel_name": channelName,
              },
            );
            debugPrint("Pusher Authorizer response: $response");

            if (response is Map) {
              final authData = response["data"] is Map ? response["data"] : response;
              if (authData["auth"] != null) {
                return {
                  "auth": authData["auth"].toString(),
                  if (authData["channel_data"] != null)
                    "channel_data": authData["channel_data"].toString(),
                  if (authData["shared_secret"] != null)
                    "shared_secret": authData["shared_secret"].toString(),
                };
              }
            }
          } catch (e) {
            debugPrint("Pusher Authorizer error: $e");
          }

          // Fallback to headers if backend handles it via standard authEndpoint
          final userAuthToken = SharedPreferencesHelper().getString("token") ?? "";
          return {
            "headers": {
              "Authorization": "Bearer $userAuthToken",
              "Accept": "application/json",
            }
          };
        },
        onError: (message, code, error) {
          debugPrint("Pusher Error: $message (code: $code, error: $error)");
        },
        onSubscriptionError: (message, error) {
          debugPrint("Pusher Subscription Error: $message (error: $error)");
        },
      );

      await _pusher!.connect();

      final channelName = "private-conversation.${widget.conversationId}";
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (dynamic event) {
          if (!mounted) return;
          try {
            final eventName = event.eventName?.toString() ?? '';
            final isTargetEvent = eventName == "message.sent" ||
                eventName == ".message.sent" ||
                eventName.contains("MessageSent") ||
                eventName == "App\\Events\\MessageSent";

            if (isTargetEvent) {
              final dynamic eventData = event.data;
              final rawData = eventData is String ? jsonDecode(eventData) : eventData;
              final messageData = (rawData is Map && rawData.containsKey('message'))
                  ? rawData['message']
                  : rawData;

              if (messageData is Map) {
                final currentUserId = SharedPreferencesHelper().getInt("userId");
                final currentUserCode = SharedPreferencesHelper().getString("user_code");
                final partnerCode = widget.partnerCode ?? ref.read(chatDetailProvider).partnerCode;
                final incomingMessage = MessageModel.fromJson(
                  messageData,
                  currentUserId: currentUserId,
                  currentUserCode: currentUserCode,
                  partnerCode: partnerCode,
                );
                ref.read(chatDetailProvider.notifier).addReceivedMessage(incomingMessage);
              }
            }
          } catch (e) {
            debugPrint("Error handling Pusher event: $e");
          }
        },
      );
    } catch (e) {
      debugPrint("Pusher init error: $e");
    }
  }

  void _initAudioPlayerListeners() {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _audioPosition = Duration.zero;
          _currentlyPlayingUrl = null;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _audioDuration = newDuration;
          if (_currentlyPlayingUrl != null) {
            _audioKnownDurations[_currentlyPlayingUrl!] = newDuration;
          }
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _audioPosition = newPosition;
        });
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100);
        await _audioRecorder.start(config, path: filePath);

        setState(() {
          _isRecording = true;
          _recordDurationSeconds = 0;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordDurationSeconds++;
            });
          }
        });
      } else {
        Fluttertoast.showToast(msg: "Microphone permission is required to record voice notes.");
      }
    } catch (e) {
      debugPrint("Error starting voice recording: $e");
      Fluttertoast.showToast(msg: "Failed to start recording: $e");
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordDurationSeconds = 0;
      });

      if (path != null && File(path).existsSync()) {
        final fileName = path.split('/').last;
        _sendPickedFile(path, fileName);
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint("Error cancelling recording: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordDurationSeconds = 0;
        });
      }
    }
  }

  /// Downloads a remote audio URL with auth headers to a local temp file,
  /// caches the result, then plays from the local path.
  Future<void> _togglePlayAudio(String url) async {
    try {
      // --- PAUSE if already playing this track ---
      if (_currentlyPlayingUrl == url && _isPlayingAudio) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _isPlayingAudio = false);
        return;
      }

      // Stop any current playback
      await _audioPlayer.stop();

      // --- LOCAL FILE: play directly ---
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        await _audioPlayer.play(DeviceFileSource(url));
        if (mounted) {
          setState(() {
            _currentlyPlayingUrl = url;
            _isPlayingAudio = true;
          });
        }
        return;
      }

      // --- REMOTE URL: check cache first ---
      if (_audioCachePaths.containsKey(url)) {
        final cachedPath = _audioCachePaths[url]!;
        if (File(cachedPath).existsSync()) {
          await _audioPlayer.play(DeviceFileSource(cachedPath));
          if (mounted) {
            setState(() {
              _currentlyPlayingUrl = url;
              _isPlayingAudio = true;
            });
          }
          return;
        } else {
          // Cache entry stale — remove it
          _audioCachePaths.remove(url);
        }
      }

      // --- Download with Bearer token ---
      if (mounted) setState(() => _downloadingAudioUrls.add(url));

      try {
        final token = SharedPreferencesHelper().getString("token") ?? "";
        final tempDir = await getTemporaryDirectory();
        // Use URL hash as filename to avoid collisions
        final fileName = 'audio_${url.hashCode.abs()}${_audioExtension(url)}';
        final localPath = '${tempDir.path}/$fileName';

        final dio = Dio();
        await dio.download(
          url,
          localPath,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': '*/*',
            },
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

        _audioCachePaths[url] = localPath;

        if (mounted) {
          setState(() => _downloadingAudioUrls.remove(url));
        }

        await _audioPlayer.play(DeviceFileSource(localPath));
        if (mounted) {
          setState(() {
            _currentlyPlayingUrl = url;
            _isPlayingAudio = true;
          });
        }
      } catch (downloadError) {
        debugPrint("Audio download failed: $downloadError");
        if (mounted) setState(() => _downloadingAudioUrls.remove(url));
        // Fallback: try direct URL (may work on Android without token)
        try {
          await _audioPlayer.play(UrlSource(url));
          if (mounted) {
            setState(() {
              _currentlyPlayingUrl = url;
              _isPlayingAudio = true;
            });
          }
        } catch (e) {
          debugPrint("Error playing audio (fallback): $e");
          Fluttertoast.showToast(msg: "Could not play audio. Please try again.");
        }
      }
    } catch (e) {
      debugPrint("Error in _togglePlayAudio: $e");
      if (mounted) setState(() => _downloadingAudioUrls.remove(url));
    }
  }

  /// Returns the file extension from a URL (e.g. '.m4a'), defaults to '.mp3'
  String _audioExtension(String url) {
    final path = url.split('?').first;
    final dot = path.lastIndexOf('.');
    if (dot != -1 && (path.length - dot) <= 5) {
      return path.substring(dot);
    }
    return '.mp3';
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  String _formatDurationFromDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _seekAudio(double value) async {
    final targetPosition = Duration(milliseconds: value.toInt());
    await _audioPlayer.seek(targetPosition);
  }

  bool _isAudioUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.m4a') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.opus') ||
        lower.endsWith('.flac') ||
        lower.contains('/chat/media/') ||
        lower.contains('/stream') ||
        lower.contains('/audio');
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.3gp') ||
        lower.contains('/video');
  }

  @override
  void dispose() {
    if (ChatDetailNotifier.activeConversationId == widget.conversationId) {
      ChatDetailNotifier.activeConversationId = null;
      ChatDetailNotifier.onActiveMessageReceived = null;
    }
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    if (_pusher != null) {
      try {
        _pusher!.disconnect();
      } catch (e) {
        debugPrint("Pusher dispose error: $e");
      }
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      final success = await ref.read(chatDetailProvider.notifier).sendMessage(content);
      if (success && mounted) {
        _messageController.clear();
        // Scroll to bottom after sending
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: const Color(0xFFE91E63),
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromCamera();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromGallery();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      color: const Color(0xFF00ACC1),
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideo();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.mic_rounded,
                      label: 'Voice Note',
                      color: const Color(0xFFFF9800),
                      onTap: () {
                        Navigator.pop(context);
                        _startRecording();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.insert_drive_file_rounded,
                      label: 'Document',
                      color: const Color(0xFF536DFE),
                      onTap: () {
                        Navigator.pop(context);
                        _pickDocument();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.location_on_rounded,
                      label: 'Location',
                      color: const Color(0xFF00BFA5),
                      onTap: () {
                        Navigator.pop(context);
                        _shareCurrentLocation();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      // Send 100% raw uncompressed camera resolution for maximum jewelry clarity
      final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 100);
      if (photo != null) {
        _sendPickedFile(photo.path, photo.name);
      }
    } catch (e) {
      debugPrint("Error capturing photo: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      // Send 100% raw uncompressed gallery image for maximum jewelry clarity
      final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (photo != null) {
        _sendPickedFile(photo.path, photo.name);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        _sendPickedFile(video.path, video.name);
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final file = result.files.single;
        _sendPickedFile(file.path!, file.name);
      }
    } catch (e) {
      debugPrint("Error picking document: $e");
    }
  }

  Future<void> _shareCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: "Location services are disabled. Please enable GPS.");
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: "Location permission denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: "Location permissions are permanently denied. Please enable in Settings.");
        await Geolocator.openAppSettings();
        return;
      }

      Fluttertoast.showToast(msg: "Getting current location...");

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final String mapsUrl = "https://maps.google.com/?q=${position.latitude},${position.longitude}";
      final String messageText = "📍 Live Location\n$mapsUrl";

      ref.read(chatDetailProvider.notifier).sendMessage(messageText);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint("Error sharing location: $e");
      Fluttertoast.showToast(msg: "Unable to retrieve location: $e");
    }
  }

  void _sendPickedFile(String path, String fileName) {
    final caption = _messageController.text.trim();
    ref.read(chatDetailProvider.notifier).sendAttachment(
          filePath: path,
          fileName: fileName,
          caption: caption.isNotEmpty ? caption : null,
        );
    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatDetailState = ref.watch(chatDetailProvider);
    final String effectiveCode = (widget.partnerCode != null && widget.partnerCode!.isNotEmpty)
        ? widget.partnerCode!
        : (chatDetailState.partnerCode ?? '');

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSelectMode = false;
                    _selectedMessageIndices.clear();
                  });
                },
              )
            : null,
        title: _isSelectMode
            ? Text(
                '${_selectedMessageIndices.length} selected',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(text: widget.chatName),
                    if (_isSuperAdmin && effectiveCode.isNotEmpty)
                      TextSpan(
                        text: ' ($effectiveCode)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
        backgroundColor: AppColor.appBarBackground,
        actions: [
          if (_isSuperAdmin) ...[
            if (_isSelectMode) ...[
              IconButton(
                tooltip: _selectedMessageIndices.length == chatDetailState.messages.length
                    ? 'Deselect All'
                    : 'Select All',
                icon: Icon(
                  _selectedMessageIndices.length == chatDetailState.messages.length
                      ? Icons.select_all
                      : Icons.checklist,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_selectedMessageIndices.length == chatDetailState.messages.length) {
                      _selectedMessageIndices.clear();
                    } else {
                      _selectedMessageIndices.clear();
                      for (int i = 0; i < chatDetailState.messages.length; i++) {
                        _selectedMessageIndices.add(i);
                      }
                    }
                  });
                },
              ),
              IconButton(
                tooltip: 'Forward via WhatsApp',
                icon: const Icon(FontAwesomeIcons.whatsapp, size: 24, color: Colors.white),
                onPressed: _selectedMessageIndices.isEmpty || _isForwarding
                    ? null
                    : () => _forwardSelectedToWhatsApp(chatDetailState.messages),
              ),
            ] else ...[
              IconButton(
                tooltip: 'Select messages to forward',
                icon: const Icon(FontAwesomeIcons.whatsapp, size: 24, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSelectMode = true;
                    _selectedMessageIndices.clear();
                  });
                },
              ),
            ],
          ],
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: chatDetailState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : chatDetailState.error != null
                      ? _buildErrorState(chatDetailState.error!)
                      : chatDetailState.messages.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages yet. Say hello!',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            )
                          : Stack(
                              children: [
                                ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: chatDetailState.messages.length,
                                  itemBuilder: (context, index) {
                                    final message = chatDetailState.messages[index];
                                    final bool showDateHeader = _shouldShowDateHeader(chatDetailState.messages, index);

                                    final bubbleWidget = _buildMessageBubble(message, index);

                                    if (!showDateHeader) {
                                      return bubbleWidget;
                                    }

                                    final headerText = _formatDateHeader(message.createdAt);
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildDateHeader(headerText),
                                        bubbleWidget,
                                      ],
                                    );
                                  },
                                ),
                                if (_showScrollToBottom)
                                  Positioned(
                                    bottom: 12,
                                    right: 16,
                                    child: AnimatedScale(
                                      scale: _showScrollToBottom ? 1.0 : 0.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _scrollToBottom,
                                          borderRadius: BorderRadius.circular(22),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: AppColor.primary,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.25),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.keyboard_double_arrow_down_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
            ),
            if (_isSelectMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${_selectedMessageIndices.length} Selected",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedMessageIndices.isEmpty
                                  ? "Tap messages to select"
                                  : "Ready to forward to WhatsApp",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSelectMode = false;
                            _selectedMessageIndices.clear();
                          });
                        },
                        child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: _selectedMessageIndices.isEmpty || _isForwarding
                            ? null
                            : () => _forwardSelectedToWhatsApp(chatDetailState.messages),
                        icon: _isForwarding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(FontAwesomeIcons.whatsapp, size: 20, color: Colors.white),
                        label: Text(
                          _isForwarding ? "Sharing..." : "Forward",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    final bool isNotFound = errorMessage.toLowerCase().contains("not found");
    final IconData icon = isNotFound ? Icons.chat_bubble_outline_rounded : Icons.cloud_off_rounded;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isNotFound
                    ? Colors.orange.shade50
                    : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: isNotFound ? Colors.orange.shade700 : Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isNotFound ? "Conversation Unavailable" : "Unable to Load Messages",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                ref.read(chatDetailProvider.notifier).fetchMessages(widget.conversationId);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                "Retry",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, int index) {
    final bool isMe = message.isMe;
    final hasAttachment = message.attachmentUrl != null && message.attachmentUrl!.trim().isNotEmpty;
    final bool isImage = hasAttachment && (_isImageUrl(message.attachmentUrl!) || message.type == 'image');
    final bool isAudio = hasAttachment && (_isAudioUrl(message.attachmentUrl!) || message.type == 'audio' || message.type == 'voice');
    final bool isVideo = hasAttachment && (_isVideoUrl(message.attachmentUrl!) || message.type == 'video');

    final bool isSelected = _selectedMessageIndices.contains(index);

    return InkWell(
      onLongPress: _isSuperAdmin
          ? () {
              setState(() {
                _isSelectMode = true;
                if (_selectedMessageIndices.contains(index)) {
                  _selectedMessageIndices.remove(index);
                } else {
                  _selectedMessageIndices.add(index);
                }
              });
            }
          : null,
      onTap: _isSelectMode
          ? () {
              setState(() {
                if (_selectedMessageIndices.contains(index)) {
                  _selectedMessageIndices.remove(index);
                } else {
                  _selectedMessageIndices.add(index);
                }
              });
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          // Sender (isMe) on Right, Receiver on Left
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_isSelectMode && !isMe)
              Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 8),
                child: Checkbox(
                  value: isSelected,
                  activeColor: AppColor.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedMessageIndices.add(index);
                      } else {
                        _selectedMessageIndices.remove(index);
                      }
                    });
                  },
                ),
              ),

            // Bubble Container
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? AppColor.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  border: isMe ? null : Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Top row: Sender name & top-right dropdown arrow for super admin
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe && message.senderName != null && message.senderName!.isNotEmpty)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4.0, right: 6.0),
                              child: Text(
                                message.senderName!,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.primary,
                                ),
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        if (_isSuperAdmin)
                          Align(
                            alignment: Alignment.topRight,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                              tooltip: "Forward Options",
                              onSelected: (value) {
                                if (value == 'forward_whatsapp') {
                                  _forwardSingleToWhatsApp(message);
                                } else if (value == 'select_multiple') {
                                  setState(() {
                                    _isSelectMode = true;
                                    _selectedMessageIndices.add(index);
                                  });
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'forward_whatsapp',
                                  child: Row(
                                    children: [
                                      Icon(FontAwesomeIcons.whatsapp, size: 20, color: Color(0xFF25D366)),
                                      SizedBox(width: 8),
                                      Text('Forward via WhatsApp', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'select_multiple',
                                  child: Row(
                                    children: [
                                      Icon(Icons.checklist, size: 20, color: AppColor.primary),
                                      SizedBox(width: 8),
                                      Text('Select Multiple', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Attachment View
                    if (hasAttachment) ...[
                      if (isImage)
                        GestureDetector(
                          onTap: () => _openFullScreenImage(message.attachmentUrl!),
                          onLongPress: () => _showMediaOptions(message.attachmentUrl!, 'image'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight: 240,
                                minWidth: 160,
                              ),
                              color: Colors.black12,
                              child: _buildImageWidget(message.attachmentUrl!),
                            ),
                          ),
                        )
                      else if (isVideo)
                        _buildVideoBubble(message.attachmentUrl!, isMe: isMe)
                      else if (isAudio)
                        _buildAudioBubble(message.attachmentUrl!, isMe: isMe)
                      else
                        _buildDocumentBubble(message.attachmentUrl!, isMe: isMe),
                      const SizedBox(height: 6),
                    ],

                    // Location Card, Order Action Card, or Message text / caption
                    if (message.content != null &&
                        message.content!.isNotEmpty &&
                        (!hasAttachment || message.content != _getFileName(message.attachmentUrl!))) ...[
                      if (_isLocationMessage(message.content!))
                        _buildLocationBubbleCard(message.content!, isMe: isMe)
                      else if (_extractOrderInfo(message.content!) != null)
                        _buildOrderActionBubbleCard(message.content!, isMe: isMe)
                      else if (_extractUrlsFromText(message.content!).isNotEmpty && !hasAttachment)
                        _buildTextWithLinks(message.content!, isMe: isMe)
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            message.content!,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                              height: 1.25,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                    ],

                    // Timestamp & ticks
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                              color: isMe ? Colors.white.withOpacity(0.75) : Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all,
                              size: 13,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isSelectMode && isMe)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 8),
                child: Checkbox(
                  value: isSelected,
                  activeColor: AppColor.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedMessageIndices.add(index);
                      } else {
                        _selectedMessageIndices.remove(index);
                      }
                    });
                  },
                ),
              ),

            if (!isMe) const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 160,
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 120,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    } else {
      // Local file preview if offline or just sent
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return const SizedBox(
        height: 100,
        child: Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }


  /// Extracts all http/https URLs from text
  List<String> _extractUrlsFromText(String text) {
    final exp = RegExp(r'https?://[^\s]+', caseSensitive: false);
    return exp.allMatches(text).map((m) => m.group(0)!).toList();
  }

  String _getFileName(String path) {
    final cleanPath = path.split('?').first;
    return cleanPath.split('/').last;
  }

  void _openFullScreenImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (ctx) => _FullScreenImageViewer(
        url: url,
        onDownload: () => _openFileUrl(url),
      ),
    );
  }

  Map<String, String>? _extractOrderInfo(String text) {
    // Check for Work Order pattern
    final woMatch = RegExp(r'(?:Work Order|WO#?):?\s*([A-Za-z0-9_-]+)', caseSensitive: false).firstMatch(text);
    if (woMatch != null) {
      final code = woMatch.group(1)!.trim();
      if (code.isNotEmpty) {
        return {'type': 'WO', 'number': code};
      }
    }

    // Check for Stock Order pattern
    final stockMatch = RegExp(r'(?:Live Stock Order|Stock Order|Stock#?):?\s*([A-Za-z0-9_-]+)', caseSensitive: false).firstMatch(text);
    if (stockMatch != null) {
      final code = stockMatch.group(1)!.trim();
      if (code.isNotEmpty) {
        return {'type': 'STOCK', 'number': code};
      }
    }

    // Check for Purchase Order pattern
    final poMatch = RegExp(r'(?:Purchase Order|PO#?):?\s*([A-Za-z0-9_-]+)', caseSensitive: false).firstMatch(text);
    if (poMatch != null) {
      final code = poMatch.group(1)!.trim();
      if (code.isNotEmpty) {
        return {'type': 'PO', 'number': code};
      }
    }

    return null;
  }

  Widget _buildOrderActionBubbleCard(String text, {required bool isMe}) {
    final orderInfo = _extractOrderInfo(text);
    final orderType = orderInfo?['type'] ?? '';
    final isWO = orderType == 'WO';
    final isStock = orderType == 'STOCK';
    final orderNumber = orderInfo?['number'] ?? '';

    final String titleText = isWO
        ? 'Work Order'
        : (isStock ? 'Stock Order' : 'Purchase Order');
    final IconData iconData = isWO
        ? Icons.assignment_rounded
        : (isStock ? Icons.inventory_2_rounded : Icons.shopping_bag_rounded);
    final Color badgeColor = isWO
        ? AppColor.primary
        : (isStock ? Colors.teal.shade700 : Colors.amber.shade700);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.16) : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? Colors.white24 : Colors.amber.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titleText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isMe ? Colors.white : Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isMe ? Colors.white : AppColor.primary,
                foregroundColor: isMe ? AppColor.primary : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                'View $orderNumber',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              onPressed: () async {
                if (isWO) {
                  String targetStatus = 'New';
                  String tabParam = 'new-orders';
                  try {
                    final res = await ApiClient().get(
                      endpoint: 'api/common/work-orders?tab=all-orders&search=${Uri.encodeComponent(orderNumber)}',
                    );
                    if (res != null && res['status'] == 1 && res['data'] != null) {
                      final rawData = res['data']['data'];
                      final List<dynamic> list = rawData is Map ? (rawData['data'] ?? []) : [];
                      if (list.isNotEmpty) {
                        final found = list.firstWhere(
                          (o) => o['work_order_number']?.toString().toLowerCase() == orderNumber.toLowerCase(),
                          orElse: () => list.first,
                        );
                        final rawStatus = found['status']?.toString();
                        if (rawStatus != null && rawStatus.isNotEmpty) {
                          final statusLower = rawStatus.toLowerCase();
                          if (statusLower == 'allocated') {
                            targetStatus = 'Allocated';
                            tabParam = 'allocated-orders';
                          } else if (statusLower == 'in process' || statusLower == 'in_process') {
                            targetStatus = 'In Process';
                            tabParam = 'in-process-orders';
                          } else if (statusLower == 'for approval' || statusLower == 'for_approval') {
                            targetStatus = 'For Approval';
                            tabParam = 'for-approval-orders';
                          } else if (statusLower == 'completed') {
                            targetStatus = 'Completed';
                            tabParam = 'completed-orders';
                          } else if (statusLower == 'rejected') {
                            targetStatus = 'Rejected';
                            tabParam = 'rejected-orders';
                          } else if (statusLower == 'overdue') {
                            targetStatus = 'Overdue';
                            tabParam = 'overdue-orders';
                          } else {
                            targetStatus = 'New';
                            tabParam = 'new-orders';
                          }
                        }
                      }
                    }
                  } catch (_) {}

                  ref.read(workOrderTargetProvider.notifier).state = OrderTargetState(
                    orderNumber: orderNumber,
                    status: targetStatus,
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                  );

                  ref.read(workOrderListProvider.notifier).fetchWorkOrders(
                    urls: 'api/common/work-orders?tab=$tabParam&search=${Uri.encodeComponent(orderNumber)}',
                  );

                  ref.read(menuIndexProvider.notifier).state = 7;
                  Get.until((route) => route.settings.name == AppRoutes.home || Get.currentRoute == AppRoutes.home || route.isFirst);
                } else if (isStock) {
                  ref.read(menuIndexProvider.notifier).state = 18;
                  Get.until((route) => route.settings.name == AppRoutes.home || Get.currentRoute == AppRoutes.home || route.isFirst);
                } else {
                  String targetStatus = 'New';
                  String tabParam = 'created';
                  try {
                    final res = await ApiClient().get(
                      endpoint: 'api/common/purchase-orders?tab=all&search=${Uri.encodeComponent(orderNumber)}',
                    );
                    if (res != null && res['status'] == 1 && res['data'] != null) {
                      final rawData = res['data']['data'];
                      final List<dynamic> list = rawData is Map ? (rawData['data'] ?? []) : [];
                      if (list.isNotEmpty) {
                        final found = list.firstWhere(
                          (o) => (o['purchase_order_code'] ?? o['order_number'] ?? o['orderNumber'])
                              ?.toString()
                              .toLowerCase() == orderNumber.toLowerCase(),
                          orElse: () => list.first,
                        );
                        final rawStatus = found['status']?.toString();
                        if (rawStatus != null && rawStatus.isNotEmpty) {
                          final statusLower = rawStatus.toLowerCase();
                          if (statusLower == 'allocated') {
                            targetStatus = 'Allocated';
                            tabParam = 'allocated';
                          } else if (statusLower == 'in process' || statusLower == 'in_process') {
                            targetStatus = 'In Process';
                            tabParam = 'in_process';
                          } else if (statusLower == 'for approval' || statusLower == 'for_approval') {
                            targetStatus = 'For Approval';
                            tabParam = 'for_approval';
                          } else if (statusLower == 'completed') {
                            targetStatus = 'Completed';
                            tabParam = 'completed';
                          } else if (statusLower == 'rejected') {
                            targetStatus = 'Rejected';
                            tabParam = 'rejected';
                          } else if (statusLower == 'overdue') {
                            targetStatus = 'Overdue';
                            tabParam = 'overdue';
                          } else {
                            targetStatus = 'New';
                            tabParam = 'created';
                          }
                        }
                      }
                    }
                  } catch (_) {}

                  ref.read(purchaseOrderTargetProvider.notifier).state = OrderTargetState(
                    orderNumber: orderNumber,
                    status: targetStatus,
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                  );

                  ref.read(purchaseOrderListProvider.notifier).fetchPurchaseOrders(
                    customUrl: 'api/common/purchase-orders?tab=$tabParam&search=${Uri.encodeComponent(orderNumber)}',
                  );

                  ref.read(menuIndexProvider.notifier).state = 8;
                  Get.until((route) => route.settings.name == AppRoutes.home || Get.currentRoute == AppRoutes.home || route.isFirst);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // WhatsApp Forwarding Implementation for Super Admin
  Future<void> _forwardSingleToWhatsApp(MessageModel message) async {
    await _shareMessagesToWhatsApp([message]);
  }

  Future<void> _forwardSelectedToWhatsApp(List<MessageModel> allMessages) async {
    if (_selectedMessageIndices.isEmpty) return;
    final List<MessageModel> selected = _selectedMessageIndices
        .where((idx) => idx >= 0 && idx < allMessages.length)
        .map((idx) => allMessages[idx])
        .toList();
    // Reverse because messages are stored reverse in chat list (index 0 is newest)
    await _shareMessagesToWhatsApp(selected.reversed.toList());
    if (mounted) {
      setState(() {
        _isSelectMode = false;
        _selectedMessageIndices.clear();
      });
    }
  }

  Future<void> _shareMessagesToWhatsApp(List<MessageModel> messages) async {
    if (messages.isEmpty) return;

    // 1. Analyze items to forward
    int textCount = 0;
    int imageCount = 0;
    int videoCount = 0;
    int audioCount = 0;
    int docCount = 0;

    for (final msg in messages) {
      final url = msg.attachmentUrl?.trim();
      if (url != null && url.isNotEmpty) {
        if (_isImageUrl(url) || msg.type == 'image') {
          imageCount++;
        } else if (_isVideoUrl(url) || msg.type == 'video') {
          videoCount++;
        } else if (_isAudioUrl(url) || msg.type == 'audio' || msg.type == 'voice') {
          audioCount++;
        } else {
          docCount++;
        }
      }
      if (msg.content != null && msg.content!.trim().isNotEmpty) {
        final content = msg.content!.trim();
        if (url == null || content != _getFileName(url)) {
          textCount++;
        }
      }
    }

    final int totalAttachments = imageCount + videoCount + audioCount + docCount;
    bool isCancelled = false;
    double progress = totalAttachments == 0 ? 0.5 : 0.0;
    int completedCount = 0;
    int elapsedSeconds = 0;
    Timer? durationTimer;

    // Show persistent progress dialog with white text
    final dialogCompleter = Completer<void>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            durationTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (dialogCtx.mounted) {
                setDialogState(() => elapsedSeconds++);
              }
            });

            final String durationString =
                "${(elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}";

            return PopScope(
              canPop: false,
              child: Dialog(
                backgroundColor: const Color(0xFF1E232A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Icon(FontAwesomeIcons.whatsapp, size: 26, color: Color(0xFF25D366)),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Forwarding to WhatsApp",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              durationString,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Format breakdown chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (textCount > 0)
                            _buildForwardCountBadge(Icons.text_fields_rounded, "$textCount Text${textCount > 1 ? 's' : ''}"),
                          if (imageCount > 0)
                            _buildForwardCountBadge(Icons.image_rounded, "$imageCount Image${imageCount > 1 ? 's' : ''}"),
                          if (videoCount > 0)
                            _buildForwardCountBadge(Icons.videocam_rounded, "$videoCount Video${videoCount > 1 ? 's' : ''}"),
                          if (audioCount > 0)
                            _buildForwardCountBadge(Icons.audiotrack_rounded, "$audioCount Audio"),
                          if (docCount > 0)
                            _buildForwardCountBadge(Icons.insert_drive_file_rounded, "$docCount File${docCount > 1 ? 's' : ''}"),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: totalAttachments == 0 ? null : progress,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF25D366)),
                          minHeight: 7,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Progress percentage / count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            totalAttachments > 0
                                ? "Processing $completedCount of $totalAttachments media"
                                : "Preparing text content...",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Cancel Button with White Text
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            isCancelled = true;
                            Navigator.of(dialogCtx, rootNavigator: true).pop();
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      durationTimer?.cancel();
      isCancelled = true;
    });

    setState(() => _isForwarding = true);

    try {
      final List<XFile> mediaFiles = [];
      final List<String> textParts = [];
      final tempDir = await getTemporaryDirectory();
      final token = SharedPreferencesHelper().getString("token") ?? "";
      final dio = Dio();

      for (int i = 0; i < messages.length; i++) {
        if (isCancelled) break;

        final msg = messages[i];
        final url = msg.attachmentUrl?.trim();

        // 1. If message has attachment (image, video, document, audio)
        if (url != null && url.isNotEmpty) {
          if (!url.startsWith('http://') && !url.startsWith('https://')) {
            if (File(url).existsSync()) {
              mediaFiles.add(XFile(url));
            }
          } else {
            try {
              final fileName = _getFileName(url);
              final safeFileName = "${DateTime.now().millisecondsSinceEpoch}_$i"
                  "_${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}";
              final localPath = '${tempDir.path}/$safeFileName';

              await dio.download(
                url,
                localPath,
                options: Options(
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Accept': '*/*',
                  },
                ),
              );

              if (File(localPath).existsSync()) {
                mediaFiles.add(XFile(localPath));
              }
            } catch (err) {
              debugPrint("Failed to download attachment for WhatsApp share: $err");
              textParts.add(url);
            }
          }
          completedCount++;
          progress = totalAttachments > 0 ? (completedCount / totalAttachments).clamp(0.0, 1.0) : 1.0;
        }

        // 2. If message has text/content
        if (msg.content != null && msg.content!.trim().isNotEmpty) {
          final content = msg.content!.trim();
          if (url == null || content != _getFileName(url)) {
            textParts.add(content);
          }
        }
      }

      durationTimer?.cancel();

      // Close progress dialog if still open
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (isCancelled) return;

      final String sharedText = textParts.join("\n\n");

      if (mediaFiles.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            files: mediaFiles,
            text: sharedText.isNotEmpty ? sharedText : null,
          ),
        );
      } else if (sharedText.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            text: sharedText,
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "No content available to forward");
      }
    } catch (e) {
      debugPrint("WhatsApp forward error: $e");
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      Fluttertoast.showToast(msg: "Failed to forward via WhatsApp");
    } finally {
      durationTimer?.cancel();
      if (mounted) {
        setState(() => _isForwarding = false);
      }
    }
  }

  Widget _buildForwardCountBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF25D366)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  bool _isLocationMessage(String text) {
    return text.contains("maps.google.com") ||
        text.contains("maps.apple.com") ||
        text.contains("goo.gl/maps") ||
        text.contains("📍 Live Location");
  }

  String _extractLocationUrl(String text) {
    final exp = RegExp(r'(https?://[^\s]+)');
    final match = exp.firstMatch(text);
    return match != null ? match.group(0)! : text;
  }

  Widget _buildLocationBubbleCard(String text, {required bool isMe}) {
    final url = _extractLocationUrl(text);

    return InkWell(
      onTap: () => _openFileUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.18) : Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? Colors.white24 : Colors.green.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white : Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 18,
                    color: isMe ? AppColor.primary : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Location Shared',
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to open in Maps',
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isMe ? Colors.white70 : Colors.grey.shade500,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentBubble(String url, {required bool isMe}) {
    final fileName = _getFileName(url);
    final isPdf = fileName.toLowerCase().endsWith('.pdf') || url.toLowerCase().contains('.pdf');

    return Container(
      width: 240,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? Colors.white24 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header info
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () => _viewDocument(url),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPdf
                          ? Colors.red.withOpacity(isMe ? 0.3 : 0.1)
                          : (isMe ? Colors.white24 : AppColor.primary.withOpacity(0.1)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                      color: isPdf ? (isMe ? Colors.white : Colors.red) : (isMe ? Colors.white : AppColor.primary),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPdf ? 'PDF Document' : 'Document',
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Action Buttons: View & Download
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: isMe ? Colors.white : AppColor.primary,
                    ),
                    label: Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isMe ? Colors.white : AppColor.primary,
                      ),
                    ),
                    onPressed: () => _viewDocument(url),
                  ),
                ),
                Container(
                  height: 16,
                  width: 1,
                  color: isMe ? Colors.white24 : Colors.grey.shade300,
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(
                      Icons.download_rounded,
                      size: 16,
                      color: isMe ? Colors.white : AppColor.primary,
                    ),
                    label: Text(
                      'Download',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isMe ? Colors.white : AppColor.primary,
                      ),
                    ),
                    onPressed: () => _downloadDocument(url),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewDocument(String url) async {
    final fileName = _getFileName(url).toLowerCase();
    final bool isPdf = fileName.endsWith('.pdf') || url.toLowerCase().contains('.pdf');

    if (isPdf) {
      _openFullScreenPdf(url);
    } else {
      _openFileUrl(url);
    }
  }

  void _openFullScreenPdf(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (ctx) => _FullScreenPdfViewerDialog(pdfUrl: url),
    );
  }

  Future<void> _downloadDocument(String url) async {
    try {
      Fluttertoast.showToast(msg: "Starting download...");
      final tempDir = await getTemporaryDirectory();
      final fileName = _getFileName(url);
      final localPath = '${tempDir.path}/$fileName';

      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        await Share.shareXFiles([XFile(url)], text: fileName);
        return;
      }

      final token = SharedPreferencesHelper().getString("token") ?? "";
      final dio = Dio();
      await dio.download(
        url,
        localPath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': '*/*',
          },
        ),
      );

      Fluttertoast.showToast(msg: "Document saved! Opening share options...");
      await Share.shareXFiles([XFile(localPath)], text: fileName);
    } catch (e) {
      debugPrint("Download error: $e");
      _openFileUrl(url);
    }
  }

  Future<void> _openFileUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(msg: "Could not open document");
      }
    } catch (e) {
      debugPrint("Error opening file: $e");
      Fluttertoast.showToast(msg: "Error opening document");
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return createdAt;
    }
  }

  bool _shouldShowDateHeader(List<MessageModel> messages, int index) {
    // In reverse: true ListView:
    // messages[0] is the newest message (bottom of screen)
    // messages[messages.length - 1] is the oldest message (top of screen)
    // A date header appears ABOVE a message if it's the oldest message of that day.
    // In reverse list, the item above `messages[index]` visually is `messages[index + 1]`.
    if (index >= messages.length - 1) {
      return true; // The oldest message always has a date header above it
    }

    final currentMessage = messages[index];
    final olderMessage = messages[index + 1];

    if (currentMessage.createdAt == null) return false;
    if (olderMessage.createdAt == null) return true;

    try {
      final currentDate = DateTime.parse(currentMessage.createdAt!).toLocal();
      final olderDate = DateTime.parse(olderMessage.createdAt!).toLocal();

      return currentDate.year != olderDate.year ||
          currentDate.month != olderDate.month ||
          currentDate.day != olderDate.day;
    } catch (e) {
      return false;
    }
  }

  String _formatDateHeader(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'Today';
    try {
      final msgDate = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateOnly = DateTime(msgDate.year, msgDate.month, msgDate.day);

      if (dateOnly == today) {
        return 'Today';
      } else if (dateOnly == yesterday) {
        return 'Yesterday';
      } else if (now.year == msgDate.year) {
        return DateFormat('dd MMMM').format(msgDate);
      } else {
        return DateFormat('dd MMMM yyyy').format(msgDate);
      }
    } catch (e) {
      return createdAt;
    }
  }

  Widget _buildDateHeader(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildAudioBubble(String url, {required bool isMe, bool isVoiceNote = false}) {
    final bool isThisPlaying = _currentlyPlayingUrl == url && _isPlayingAudio;
    final bool isThisActive = _currentlyPlayingUrl == url;
    final bool isDownloading = _downloadingAudioUrls.contains(url);
    final String label = isVoiceNote ? 'Voice Note' : 'Audio Message';

    // Duration and position for this audio item
    final Duration totalDuration = isThisActive && _audioDuration > Duration.zero
        ? _audioDuration
        : (_audioKnownDurations[url] ?? Duration.zero);
    final Duration currentPosition = isThisActive ? _audioPosition : Duration.zero;

    final String positionText = _formatDurationFromDuration(currentPosition);
    final String totalText = totalDuration > Duration.zero
        ? _formatDurationFromDuration(totalDuration)
        : (isThisActive ? '00:00' : '--:--');

    return GestureDetector(
      onTap: isDownloading ? null : () => _togglePlayAudio(url),
      onLongPress: () => _showMediaOptions(url, 'audio'),
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.18) : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? Colors.white24 : Colors.orange.shade200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Play/pause button or download spinner
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white : AppColor.primary,
                    shape: BoxShape.circle,
                  ),
                  child: isDownloading
                      ? Padding(
                          padding: const EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: isMe ? AppColor.primary : Colors.white,
                          ),
                        )
                      : InkWell(
                          onTap: () => _togglePlayAudio(url),
                          borderRadius: BorderRadius.circular(20),
                          child: Icon(
                            isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: isMe ? AppColor.primary : Colors.white,
                            size: 22,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: isThisPlaying
                                ? (isMe ? Colors.white : AppColor.primary)
                                : (isMe ? Colors.white54 : Colors.grey.shade400),
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDownloading
                            ? 'Downloading...'
                            : isThisPlaying
                                ? 'Playing'
                                : 'Tap to play',
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Progress slider / bar
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: isMe ? Colors.white : AppColor.primary,
                inactiveTrackColor: isMe ? Colors.white30 : Colors.grey.shade300,
                thumbColor: isMe ? Colors.white : AppColor.primary,
              ),
              child: Slider(
                value: (totalDuration.inMilliseconds > 0 &&
                        currentPosition.inMilliseconds <= totalDuration.inMilliseconds)
                    ? currentPosition.inMilliseconds.toDouble()
                    : 0.0,
                max: totalDuration.inMilliseconds > 0
                    ? totalDuration.inMilliseconds.toDouble()
                    : 1.0,
                onChanged: isThisActive && totalDuration > Duration.zero
                    ? (val) => _seekAudio(val)
                    : null,
              ),
            ),
            // Duration indicator: current position / total length
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    positionText,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    totalText,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBubble(String url, {required bool isMe}) {
    return GestureDetector(
      onTap: () => _openFullScreenVideo(url),
      onLongPress: () => _showMediaOptions(url, 'video'),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 240,
          maxHeight: 180,
          minWidth: 160,
          minHeight: 120,
        ),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Icon(Icons.videocam_rounded, color: Colors.white24, size: 48),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
            ),
            Positioned(
              bottom: 8,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _getFileName(url),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenVideo(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (ctx) => _FullScreenVideoPlayerDialog(videoUrl: url),
    );
  }

  /// Shows a bottom sheet with view (inline) and redirect (external browser/app) options
  void _showMediaOptions(String url, String mediaType) {
    final bool isNetwork = url.startsWith('http://') || url.startsWith('https://');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // View inline
                  if (mediaType == 'image')
                    ListTile(
                      leading: const Icon(Icons.zoom_in_rounded, color: Colors.indigo),
                      title: const Text('View Full Screen'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFullScreenImage(url);
                      },
                    ),
                  if (mediaType == 'video')
                    ListTile(
                      leading: const Icon(Icons.play_circle_outline_rounded, color: Colors.indigo),
                      title: const Text('Play Video'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFullScreenVideo(url);
                      },
                    ),
                  if (mediaType == 'audio')
                    ListTile(
                      leading: const Icon(Icons.play_arrow_rounded, color: Colors.orange),
                      title: const Text('Play Audio'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _togglePlayAudio(url);
                      },
                    ),
                  // Open externally
                  if (isNetwork)
                    ListTile(
                      leading: const Icon(Icons.open_in_new_rounded, color: Colors.teal),
                      title: Text('Open ${mediaType == 'file' ? 'File' : mediaType == 'audio' ? 'Audio' : mediaType == 'video' ? 'Video' : 'Image'} Externally'),
                      subtitle: const Text('Opens in browser or external app'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFileUrl(url);
                      },
                    ),
                  // Copy URL
                  if (isNetwork)
                    ListTile(
                      leading: const Icon(Icons.link_rounded, color: Colors.blueGrey),
                      title: const Text('Copy Link'),
                      onTap: () async {
                        Navigator.pop(ctx);
                        // Use clipboard
                        await _copyToClipboard(url);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      Fluttertoast.showToast(msg: 'Link copied to clipboard');
    } catch (_) {}
  }

  /// Builds a text widget that makes detected URLs tappable with a "view or redirect" option
  Widget _buildTextWithLinks(String text, {required bool isMe}) {
    // Split text into parts around URLs
    final List<InlineSpan> spans = [];
    int lastEnd = 0;
    final exp = RegExp(r'https?://[^\s]+', caseSensitive: false);
    for (final match in exp.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.25,
          ),
        ));
      }
      final urlText = match.group(0)!;
      // Determine if it's a media URL
      final bool isMediaAudio = _isAudioUrl(urlText);
      final bool isMediaVideo = _isVideoUrl(urlText);
      final bool isMediaImage = _isImageUrl(urlText);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () {
            if (isMediaVideo) {
              _openFullScreenVideo(urlText);
            } else if (isMediaImage) {
              _openFullScreenImage(urlText);
            } else if (isMediaAudio) {
              _togglePlayAudio(urlText);
            } else {
              _openFileUrl(urlText);
            }
          },
          onLongPress: () {
            final type = isMediaVideo ? 'video' : isMediaImage ? 'image' : isMediaAudio ? 'audio' : 'file';
            _showMediaOptions(urlText, type);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isMe ? Colors.white.withOpacity(0.18) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isMe ? Colors.white38 : Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMediaVideo
                      ? Icons.play_circle_outline_rounded
                      : isMediaImage
                          ? Icons.image_outlined
                          : isMediaAudio
                              ? Icons.headphones_rounded
                              : Icons.link_rounded,
                  size: 14,
                  color: isMe ? Colors.white : Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    urlText.length > 40 ? '${urlText.substring(0, 40)}...' : urlText,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.blue.shade700,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 12,
                  color: isMe ? Colors.white70 : Colors.blue.shade400,
                ),
              ],
            ),
          ),
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 15,
          height: 1.25,
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: RichText(
        text: TextSpan(children: spans),
      ),
    );
  }

  Widget _buildMessageInput() {
    final chatDetailState = ref.watch(chatDetailProvider);
    final isSending = chatDetailState.isSending;
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: _isRecording
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: _cancelRecording,
                    tooltip: 'Cancel recording',
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.fiber_manual_record_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_recordDurationSeconds),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Recording...',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.green),
                    onPressed: _stopAndSendRecording,
                    tooltip: 'Send voice note',
                  ),
                ],
              )
            : Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded),
                    color: Colors.grey.shade600,
                    onPressed: isSending ? null : _showAttachmentOptions,
                    tooltip: 'Attach file or image',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isSending)
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  else if (hasText)
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: AppColor.primary,
                      onPressed: _sendMessage,
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.mic_rounded),
                      color: AppColor.primary,
                      onPressed: _startRecording,
                      tooltip: 'Record Voice Note',
                    ),
                ],
              ),
      ),
    );
  }
}

class _FullScreenVideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const _FullScreenVideoPlayerDialog({required this.videoUrl});

  @override
  State<_FullScreenVideoPlayerDialog> createState() => _FullScreenVideoPlayerDialogState();
}

class _FullScreenVideoPlayerDialogState extends State<_FullScreenVideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _statusText = 'Loading video...';
  bool _isLandscape = false;
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.videoUrl;
    try {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        // Local file
        _controller = VideoPlayerController.file(File(url));
        await _setupController();
        return;
      }

      // Remote network video: first download to local cache file with Bearer token
      // This prevents CoreMediaErrorDomain byte-range mismatch on iOS/macOS with ngrok/proxies
      final tempDir = await getTemporaryDirectory();
      final ext = _getVideoExtension(url);
      final localPath = '${tempDir.path}/video_${url.hashCode.abs()}$ext';
      final localFile = File(localPath);

      if (localFile.existsSync() && await localFile.length() > 0) {
        _controller = VideoPlayerController.file(localFile);
        await _setupController();
        return;
      }

      setState(() => _statusText = 'Downloading video...');
      final token = SharedPreferencesHelper().getString("token") ?? "";
      final dio = Dio();
      await dio.download(
        url,
        localPath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': '*/*',
          },
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      _controller = VideoPlayerController.file(File(localPath));
      await _setupController();
    } catch (e) {
      debugPrint("Direct cache load failed: $e. Falling back to networkUrl...");
      try {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
        await _setupController();
      } catch (fallbackError) {
        debugPrint("Error initializing video player: $fallbackError");
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      }
    }
  }

  String _getVideoExtension(String url) {
    final path = url.split('?').first;
    final dot = path.lastIndexOf('.');
    if (dot != -1 && (path.length - dot) <= 5) {
      return path.substring(dot);
    }
    return '.mp4';
  }

  Future<void> _setupController() async {
    await _controller.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
    }
    _controller.addListener(() {
      if (mounted && !_isDragging) setState(() {});
    });
  }

  void _toggleRotation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _isInitialized ? _controller.value.duration : Duration.zero;
    final position = _isInitialized ? _controller.value.position : Duration.zero;
    final totalMs = duration.inMilliseconds.toDouble();
    final currentMs = _isDragging ? _dragValue : position.inMilliseconds.toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: _hasError
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Failed to load video',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  )
                : _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: !_controller.value.isPlaying
                                      ? Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 48,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 12),
                            Text(
                              _statusText,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
          ),

          // Top action bar: Close and Rotate buttons
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                if (_isInitialized)
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: Icon(
                        _isLandscape ? Icons.screen_lock_rotation_rounded : Icons.screen_rotation_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _toggleRotation,
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Controls: Draggable Duration Slider + Timers + Play/Pause Button
          if (_isInitialized)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Draggable Slider
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: Colors.amber,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.amber,
                      ),
                      child: Slider(
                        value: (totalMs > 0 && currentMs <= totalMs) ? currentMs : 0.0,
                        min: 0.0,
                        max: totalMs > 0 ? totalMs : 1.0,
                        onChangeStart: (val) {
                          setState(() {
                            _isDragging = true;
                            _dragValue = val;
                          });
                        },
                        onChanged: (val) {
                          setState(() {
                            _dragValue = val;
                          });
                        },
                        onChangeEnd: (val) async {
                          final target = Duration(milliseconds: val.toInt());
                          await _controller.seekTo(target);
                          setState(() {
                            _isDragging = false;
                          });
                        },
                      ),
                    ),
                    // Row with Play/Pause button and Elapsed / Total duration labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_isDragging ? Duration(milliseconds: _dragValue.toInt()) : position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FullScreenPdfViewerDialog extends StatefulWidget {
  final String pdfUrl;

  const _FullScreenPdfViewerDialog({required this.pdfUrl});

  @override
  State<_FullScreenPdfViewerDialog> createState() => _FullScreenPdfViewerDialogState();
}

class _FullScreenPdfViewerDialogState extends State<_FullScreenPdfViewerDialog> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  String? _errorMessage;
  int _pageCount = 0;
  int _currentPage = 1;
  String? _cachedFilePath;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final url = widget.pdfUrl;
      String localPath = url;

      if (url.startsWith('http://') || url.startsWith('https://')) {
        final tempDir = await getTemporaryDirectory();
        final fileName = url.split('?').first.split('/').last;
        final cleanName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
        localPath = '${tempDir.path}/pdf_${url.hashCode.abs()}_$cleanName';
        final localFile = File(localPath);

        if (!localFile.existsSync() || await localFile.length() == 0) {
          final token = SharedPreferencesHelper().getString("token") ?? "";
          final dio = Dio();
          await dio.download(
            url,
            localPath,
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': '*/*',
              },
            ),
          );
        }
      }

      _cachedFilePath = localPath;
      final document = await PdfDocument.openFile(localPath);
      _pageCount = document.pagesCount;

      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(localPath),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading PDF: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Could not preview PDF. Tap Download or Open Externally.";
        });
      }
    }
  }

  Future<void> _shareOrDownload() async {
    try {
      if (_cachedFilePath != null && File(_cachedFilePath!).existsSync()) {
        final fileName = widget.pdfUrl.split('?').first.split('/').last;
        await Share.shareXFiles([XFile(_cachedFilePath!)], text: fileName);
      } else {
        final uri = Uri.parse(widget.pdfUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint("Share error: $e");
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.pdfUrl.split('?').first.split('/').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
          actions: [
            if (_pageCount > 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '$_currentPage / $_pageCount',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              tooltip: 'Download / Share',
              onPressed: _shareOrDownload,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Loading document...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.open_in_browser_rounded),
                            label: const Text('Open Externally'),
                            onPressed: _shareOrDownload,
                          ),
                        ],
                      ),
                    ),
                  )
                : PdfViewPinch(
                    controller: _pdfController!,
                    onPageChanged: (page) {
                      if (mounted) setState(() => _currentPage = page);
                    },
                  ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final String url;
  final VoidCallback onDownload;

  const _FullScreenImageViewer({
    required this.url,
    required this.onDownload,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      if (mounted) {
        setState(() {
          _currentScale = scale;
        });
      }
    }
  }

  void _zoomIn() {
    final matrix = _transformationController.value.clone();
    final newScale = (_currentScale * 1.3).clamp(0.5, 3.5);
    final factor = newScale / _currentScale;
    matrix.scale(factor, factor, 1.0);
    _transformationController.value = matrix;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _zoomOut() {
    final matrix = _transformationController.value.clone();
    final newScale = (_currentScale / 1.3).clamp(0.5, 3.5);
    final factor = newScale / _currentScale;
    matrix.scale(factor, factor, 1.0);
    _transformationController.value = matrix;
    setState(() {
      _currentScale = newScale;
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _resetZoom();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final x = -position.dx * 1.2;
      final y = -position.dy * 1.2;
      final zoomed = Matrix4.identity()
        ..translate(x, y, 0.0)
        ..scale(2.2, 2.2, 1.0);
      _transformationController.value = zoomed;
      setState(() {
        _currentScale = 2.2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNetwork = widget.url.startsWith('http');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${(_currentScale * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Reset zoom',
            onPressed: _resetZoom,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download / Share',
            onPressed: widget.onDownload,
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(80),
                minScale: 0.5,
                maxScale: 3.5,
                child: isNetwork
                    ? CachedNetworkImage(
                        imageUrl: widget.url,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image,
                                  color: Colors.white60, size: 48),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Image.file(
                        File(widget.url),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
              ),
            ),
          ),
          // Zoom In / Zoom Out Floating Controls
          Positioned(
            right: 20,
            bottom: 30,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_in, color: Colors.white, size: 26),
                      tooltip: 'Zoom in',
                      onPressed: _zoomIn,
                    ),
                    Container(
                      width: 24,
                      height: 1,
                      color: Colors.white24,
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out, color: Colors.white, size: 26),
                      tooltip: 'Zoom out',
                      onPressed: _zoomOut,
                    ),
                    Container(
                      width: 24,
                      height: 1,
                      color: Colors.white24,
                    ),
                    IconButton(
                      icon: const Icon(Icons.fit_screen_rounded,
                          color: Colors.white, size: 22),
                      tooltip: 'Reset',
                      onPressed: _resetZoom,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

