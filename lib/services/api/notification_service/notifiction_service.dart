import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:arianth/screens/meetings/ui/video_call_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/screens/chat/riverpod/chat_detail_notifier.dart';
import 'package:arianth/screens/chat/riverpod/chat_notifier.dart';
import 'dart:convert';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) async {
  if (details.actionId == 'reply_action' && details.input != null && details.input!.trim().isNotEmpty) {
    if (details.payload != null && details.payload!.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(details.payload!);
        if (decoded is Map<String, dynamic>) {
          final rawConvId = decoded['conversation_id'] ?? decoded['id'];
          final convId = rawConvId is int ? rawConvId : int.tryParse(rawConvId?.toString() ?? '');
          if (convId != null) {
            await NotificationService.sendReplyMessage(convId, details.input!.trim());
          }
        }
      } catch (e) {
        debugPrint("Error in notificationTapBackground reply: $e");
      }
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    // Request permission for iOS/Android
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Set presentation options for iOS foreground notifications
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print("FirebaseMessaging initialization failed: $e");
      }
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings();

    const DarwinInitializationSettings macOSInitializationSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
      macOS: macOSInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (kDebugMode) {
          print("Notification response: id=${details.id}, actionId=${details.actionId}, input=${details.input}, payload=${details.payload}");
        }

        // If the user used the direct inline Reply action
        if (details.actionId == 'reply_action' && details.input != null && details.input!.trim().isNotEmpty) {
          if (details.payload != null && details.payload!.isNotEmpty) {
            try {
              final dynamic decoded = jsonDecode(details.payload!);
              if (decoded is Map<String, dynamic>) {
                final rawConvId = decoded['conversation_id'] ?? decoded['id'];
                final convId = rawConvId is int ? rawConvId : int.tryParse(rawConvId?.toString() ?? '');
                if (convId != null) {
                  await sendReplyMessage(convId, details.input!.trim());
                  return;
                }
              }
            } catch (e) {
              if (kDebugMode) print("Error handling inline reply: $e");
            }
          }
        }

        if (details.payload != null && details.payload!.isNotEmpty) {
          try {
            final dynamic decoded = jsonDecode(details.payload!);
            if (decoded is Map<String, dynamic>) {
              final isMeeting = decoded['action'] == 'join_meeting' ||
                  decoded['meeting_id'] != null ||
                  decoded['room_id'] != null ||
                  decoded['call_type'] != null;

              if (isMeeting) {
                _navigateToMeeting(decoded);
              } else {
                navigateToChat(decoded);
              }
            }
          } catch (_) {
            Get.toNamed(AppRoutes.chat);
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isIOS) {
      try {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } catch (e) {
        if (kDebugMode) {
          print("IOS notifications permission request failed: $e");
        }
      }
    } else if (Platform.isMacOS) {
      try {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } catch (e) {
        if (kDebugMode) {
          print("MacOS notifications permission request failed: $e");
        }
      }
    }

    // Initialize CallKit Listener
    if (Platform.isAndroid || Platform.isIOS) {
      listenerCallKit();
      
      // Check for current call if app was launched from CallKit
      _checkCurrentCall();
    }

    // Set up MethodChannel to handle iOS Siri/CallKit start call intents
    if (Platform.isIOS) {
      const intentChannel = MethodChannel('com.arihanth.app/call_intent');
      intentChannel.setMethodCallHandler((call) async {
        if (call.method == 'handleStartCallIntent') {
          final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
          if (kDebugMode) {
            print("Received start call intent from channel: $data");
          }
          final String? token = SharedPreferencesHelper().getString("token");
          if (token != null && token.isNotEmpty) {
            _navigateToMeeting(data);
          }
        }
        return null;
      });

      try {
        final pendingCall = await intentChannel.invokeMethod('getPendingCallIntent');
        if (pendingCall != null) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(pendingCall);
          if (kDebugMode) {
            print("Received pending start call intent: $data");
          }
          final String? token = SharedPreferencesHelper().getString("token");
          if (token != null && token.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _navigateToMeeting(data);
            });
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error checking pending call intent: $e");
        }
      }
    }

    // Foreground notification handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("Received foreground message: ${message.notification?.title}");
        print("Data: ${message.data}");
      }
      
      final isMeeting = message.data['action'] == 'join_meeting' ||
          message.data['meeting_id'] != null ||
          message.data['room_id'] != null ||
          message.data['call_type'] != null;

      // Check for Meeting Action
      if (isMeeting) {
        showCallKitIncoming(message.data);
      } else {
        // Chat message or other notification
        final rawConvId = message.data['conversation_id'] ?? message.data['id'];
        final convId = rawConvId is int ? rawConvId : int.tryParse(rawConvId?.toString() ?? '');

        // 1. If currently inside this conversation, silently refresh the messages immediately
        if (convId != null && convId == ChatDetailNotifier.activeConversationId) {
          ChatDetailNotifier.onActiveMessageReceived?.call();
        } else {
          // 2. Otherwise show system local notification popup
          _showLocalNotification(message);
        }

        // 3. Refresh recent chats list in background so the snippet and timestamp are updated
        ChatNotifier.onMessageReceivedCallback?.call();
      }
    });
    
    // Background interaction handling
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("Notification message opened from background: ${message.notification?.title}");
      }
      
      final isMeeting = message.data['action'] == 'join_meeting' ||
          message.data['meeting_id'] != null ||
          message.data['room_id'] != null ||
          message.data['call_type'] != null;

      if (isMeeting) {
        _navigateToMeeting(message.data);
      } else {
        navigateToChat(message.data);
      }
    });
  }

  static void _handleMeetingNotification(Map<String, dynamic> data) {
    final callerName = data['caller_name']?.toString() ??
        data['host_name']?.toString() ??
        data['title']?.toString() ??
        'Incoming Video Call';

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.video_call, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                callerName,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incoming meeting call. Would you like to attend now?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (data['channel_name'] != null || data['room_id'] != null) ...[
              const SizedBox(height: 10),
              Text(
                'Meeting ID: ${data['meeting_id'] ?? data['room_id'] ?? data['channel_name']}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              endAllCalls();
              Get.back();
            },
            child: const Text('DECLINE', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              endAllCalls();
              Get.back();
              _navigateToMeeting(data);
            },
            icon: const Icon(Icons.call, color: Colors.black, size: 18),
            label: const Text('ATTEND', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static Future<void> _navigateToMeeting(Map<String, dynamic> data) async {
    try {
      var appId = data['app_id']?.toString() ?? "";
      var channelName = data['channel_name']?.toString() ?? data['handle']?.toString() ?? "";
      var token = data['token']?.toString() ?? "";
      var uidStr = data['uid']?.toString() ?? "0";
      var uid = int.tryParse(uidStr) ?? 0;

      if (appId.isEmpty && channelName.isNotEmpty) {
        // Look up meetingId from SharedPreferences to notify/wake up opponent
        try {
          final prefs = await SharedPreferences.getInstance();
          final meetingId = prefs.getInt('meeting_id_$channelName');
          if (meetingId != null) {
            if (kDebugMode) print("Found meeting ID: $meetingId for channel: $channelName. Waking up opponent.");
            await ApiClient().post(
              endpoint: "api/common/meetings/$meetingId/approve",
              body: {},
            );
          }
        } catch (e) {
          if (kDebugMode) print("Error approving meeting on recall: $e");
        }

        // Fetch meeting details/token dynamically from API
        final response = await ApiClient().get(
          endpoint: "api/common/meetings/$channelName/token",
        );
        if (response != null && response["status"] == 1) {
          final actualResponse = response["data"];
          if (actualResponse != null && actualResponse["success"] == true) {
            final agoraData = actualResponse["data"];
            if (agoraData != null) {
              appId = agoraData["app_id"]?.toString() ?? "";
              channelName = agoraData["channel_name"]?.toString() ?? channelName;
              token = agoraData["token"]?.toString() ?? "";
              uid = agoraData["uid"] is int ? agoraData["uid"] : int.tryParse(agoraData["uid"].toString()) ?? 0;
              
              // Persist fetched caller/host name if available
              final String? hostName = agoraData["host_name"]?.toString() ?? agoraData["caller_name"]?.toString();
              if (hostName != null && hostName.isNotEmpty) {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('caller_name_$channelName', hostName);
                } catch (e) {
                  if (kDebugMode) print("Error saving fetched caller name to prefs: $e");
                }
              }
            }
          }
        }
      }

      // Extract opponent/caller name from data payload or fallback to SharedPreferences
      String? opponentName = data['caller_name']?.toString() ??
          data['callerName']?.toString() ??
          data['host_name']?.toString() ??
          data['hostName']?.toString() ??
          data['sender_name']?.toString() ??
          data['title']?.toString();

      if (opponentName == null || opponentName.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          opponentName = prefs.getString('caller_name_$channelName');
        } catch (e) {
          if (kDebugMode) print("Error reading opponent name from prefs: $e");
        }
      }

      if (appId.isNotEmpty && channelName.isNotEmpty) {
        // --- Permission Check ---
        final cameraStatus = await Permission.camera.request();
        final micStatus = await Permission.microphone.request();

        if (cameraStatus.isGranted && micStatus.isGranted) {
          endAllCalls();
          Get.to(() => VideoCallScreen(
            appId: appId,
            channelName: channelName,
            token: token,
            uid: uid,
            opponentName: opponentName,
          ));
        } else {
          Toaster.showError("Camera and Microphone permissions are required to join the meeting. Please enable them in Settings.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error navigating to meeting: $e");
      }
    }
  }

  static final Map<String, DateTime> _processedMeetings = {};

  static Future<void> showCallKitIncoming(Map<String, dynamic> data) async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;
      final meetingId = data['meeting_id']?.toString() ?? data['room_id']?.toString() ?? data['channel_name']?.toString() ?? '';
      if (meetingId.isNotEmpty) {
        final now = DateTime.now();
        final lastProcessed = _processedMeetings[meetingId];
        if (lastProcessed != null && now.difference(lastProcessed).inSeconds < 10) {
          if (kDebugMode) {
            print("Duplicate meeting notification ignored for meeting_id: $meetingId");
          }
          return;
        }
        _processedMeetings[meetingId] = now;
        _processedMeetings.removeWhere((key, value) => now.difference(value).inSeconds > 60);
      }

      final uuid = const Uuid().v4();
      
      // Get logo path from assets safely
      String logoPath = "";
      try {
        final byteData = await rootBundle.load('assets/image/app_lancher_logo_img.jpeg');
        final file = File('${(await getApplicationDocumentsDirectory()).path}/app_logo.jpeg');
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        logoPath = file.path;
      } catch (e) {
        if (kDebugMode) print("Error loading logo asset: $e");
      }

      final String callerName = data['caller_name']?.toString() ??
          data['host_name']?.toString() ??
          data['hostName']?.toString() ??
          data['sender_name']?.toString() ??
          data['title']?.toString() ??
          'Meeting Invitation';

      final String channelName = data['channel_name']?.toString() ?? 'Join Meeting';

      // Check if it is a video call from incoming payload
      final bool isVideoCall = data['isVideo'] == true ||
          data['isVideo'] == 'true' ||
          data['is_video'] == true ||
          data['is_video'] == 'true' ||
          data['call_type'] == 'video' ||
          data['type'] == 1 ||
          data['type'] == '1';

      // Persist caller name and meeting ID in SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('caller_name_$channelName', callerName);
        final rawMeetingId = data['meeting_id'] ?? data['id'] ?? data['room_id'];
        if (rawMeetingId != null) {
          final mId = int.tryParse(rawMeetingId.toString());
          if (mId != null) {
            await prefs.setInt('meeting_id_$channelName', mId);
          }
        }
      } catch (e) {
        if (kDebugMode) print("Error saving details to prefs: $e");
      }

      final callKitParams = CallKitParams(
        id: uuid,
        nameCaller: callerName,
        appName: 'Arihanth',
        avatar: logoPath.isNotEmpty ? 'file://$logoPath' : '',
        handle: channelName,
        type: isVideoCall ? 1 : 0, // 0: Audio, 1: Video
        duration: 30000,
        textAccept: 'Attend',
        textDecline: 'Decline',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'Missed meeting invitation',
          callbackText: 'Call back',
        ),
        extra: data,
        android: AndroidParams(
          isCustomNotification: true,
          isShowLogo: true,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#A57C52',
          backgroundUrl: '',
          actionColor: '#4CAF50',
        ),
        ios: const IOSParams(
          iconName: 'AppIcon',
          handleType: 'generic',
          supportsVideo: true,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'videoChat',
          audioSessionActive: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );

      if (kDebugMode) {
        print("Calling FlutterCallkitIncoming.showCallkitIncoming for $callerName (video: $isVideoCall)");
      }
      await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
      if (kDebugMode) {
        print("FlutterCallkitIncoming.showCallkitIncoming completed successfully");
      }
    } catch (e, st) {
      if (kDebugMode) {
        print("Error displaying CallKit incoming call: $e\n$st");
      }
    }
  }

  static void listenerCallKit() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      switch (event!.event) {
        case Event.actionCallAccept:
        case Event.actionCallStart:
        case Event.actionCallCallback:
          final Map<String, dynamic> data = (event.body['extra'] != null && (event.body['extra'] as Map).isNotEmpty)
              ? Map<String, dynamic>.from(event.body['extra'])
              : Map<String, dynamic>.from(event.body);
          _navigateToMeeting(data);
          break;
        case Event.actionCallDecline:
          endAllCalls();
          break;
        case Event.actionCallEnded:
          _notificationsPlugin.cancelAll();
          break;
        default:
          break;
      }
    });
  }

  static Future<void> endAllCalls() async {
    try {
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      if (activeCalls is List && activeCalls.isNotEmpty) {
        await FlutterCallkitIncoming.endAllCalls();
      }
    } catch (e) {
      if (kDebugMode) print("Error ending all calls: $e");
    }
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> _checkCurrentCall() async {
    final calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List && calls.isNotEmpty) {
      final call = calls.first;
      if (call['extra'] != null) {
        final String? token = SharedPreferencesHelper().getString("token");
        if (token != null && token.isNotEmpty) {
          Future.delayed(const Duration(seconds: 1), () {
            _navigateToMeeting(Map<String, dynamic>.from(call['extra']));
          });
        }
      }
    }
  }

  static void navigateToChat(Map<String, dynamic> data) {
    try {
      final rawConvId = data['conversation_id'] ?? data['id'];
      final convId = rawConvId is int
          ? rawConvId
          : int.tryParse(rawConvId?.toString() ?? '');

      final partnerName = data['sender_name']?.toString() ??
          data['partner_name']?.toString() ??
          data['caller_name']?.toString() ??
          data['name']?.toString() ??
          data['title']?.toString() ??
          'Chat';

      if (convId != null && convId > 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.toNamed(
            AppRoutes.chatDetails,
            arguments: {
              'conversationId': convId,
              'chatName': partnerName,
            },
          );
        });
      } else {
        // Fallback to chat list
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.toNamed(AppRoutes.chat);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error navigating to chat: $e");
      }
    }
  }

  static Future<void> sendReplyMessage(int conversationId, String messageText) async {
    try {
      final payload = {
        "body": messageText,
        "message": messageText,
        "content": messageText,
      };

      // 1. First attempt the dedicated reply endpoint: /chat/conversations/{id}/reply
      dynamic response = await ApiClient().post(
        endpoint: "api/common/chat/conversations/$conversationId/reply",
        body: payload,
      );

      // If reply endpoint is not found (404) or failed, fallback to messages endpoint
      if (response == null || (response is Map && (response["status"] == 0 || response["success"] == false))) {
        if (kDebugMode) {
          print("Attempting fallback to standard conversation message endpoint...");
        }
        response = await ApiClient().post(
          endpoint: "api/common/chat/conversations/$conversationId/messages",
          body: {
            "body": messageText,
          },
        );
      }

      if (kDebugMode) {
        print("Reply sent via notification response: $response");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sending reply message from notification: $e");
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (Platform.isIOS) return;

    final notification = message.notification;
    final String? title = notification?.title ??
        message.data['sender_name']?.toString() ??
        message.data['title']?.toString() ??
        message.data['sender_code']?.toString();

    final String? body = notification?.body ??
        message.data['message']?.toString() ??
        message.data['body']?.toString() ??
        message.data['content']?.toString() ??
        message.data['text']?.toString();

    if ((title != null || body != null) && !kIsWeb) {
      String payloadString;
      try {
        payloadString = jsonEncode(message.data);
      } catch (_) {
        payloadString = message.data.toString();
      }

      final notificationId = message.messageId.hashCode != 0
          ? message.messageId.hashCode
          : (notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch.remainder(100000));

      await _notificationsPlugin.show(
        id: notificationId,
        title: title ?? 'New Message',
        body: body ?? '',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'reply_action',
                'Reply',
                inputs: <AndroidNotificationActionInput>[
                  AndroidNotificationActionInput(
                    label: 'Type a message...',
                  ),
                ],
                showsUserInterface: false,
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payloadString,
      );
    }
  }

  static Future<String?> getToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        // Wait until the APNs token is available
        String? apnsToken;
        int retries = 0;
        while (apnsToken == null && retries < 10) {
          try {
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          } catch (_) {}
          if (apnsToken == null) {
            await Future.delayed(const Duration(milliseconds: 500));
            retries++;
          }
        }
        if (apnsToken == null) {
          if (kDebugMode) {
            print("APNS token not set after retries. Cannot get FCM token.");
          }
          return null;
        }
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) {
        print("Error getting device token: $e");
      }
      return null;
    }
  }

  static Future<String?> getAPNSToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        print("---");
        String? apnsToken;
        int retries = 0;
        while (apnsToken == null && retries < 10) {
          try {
            print("error From fb handling");
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();

          } catch (e) {
            print("error From fb handling$e");
          }
          if (apnsToken == null) {
            await Future.delayed(const Duration(milliseconds: 500));
            retries++;
          }
        }
        return apnsToken;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting APNS token: $e");
      }
      return null;
    }
  }
}
