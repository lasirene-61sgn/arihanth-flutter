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

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Request permission for iOS/Android
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

    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click
        if (kDebugMode) {
          print("Notification clicked: ${details.payload}");
        }
      },
    );

    // Initialize CallKit Listener
    listenerCallKit();
    
    // Check for current call if app was launched from CallKit
    _checkCurrentCall();

    // Foreground notification handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("Received foreground message: ${message.notification?.title}");
        print("Data: ${message.data}");
      }
      
      // Check for Meeting Action
      if (message.data['action'] == 'join_meeting') {
        showCallKitIncoming(message.data);
        // _handleMeetingNotification(message.data); // Removed for now to avoid double UI, CallKit is better
      } else {
        _showLocalNotification(message);
      }
    });
    
    // Background interaction handling
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("Notification message opened from background: ${message.notification?.title}");
      }
      
      if (message.data['action'] == 'join_meeting') {
        _navigateToMeeting(message.data);
      }
    });
  }

  static void _handleMeetingNotification(Map<String, dynamic> data) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.video_call, color: Colors.greenAccent),
            const SizedBox(width: 12),
            const Text('Meeting Reminder', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A meeting is about to start. Would you like to join now?',
              style: TextStyle(color: Colors.white70),
            ),
            if (data['channel_name'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Channel: ${data['channel_name']}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _navigateToMeeting(data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('CALL ATTEND', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static Future<void> _navigateToMeeting(Map<String, dynamic> data) async {
    try {
      final appId = data['app_id']?.toString() ?? "";
      final channelName = data['channel_name']?.toString() ?? "";
      final token = data['token']?.toString() ?? "";
      final uidStr = data['uid']?.toString() ?? "0";
      final uid = int.tryParse(uidStr) ?? 0;

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
          ));
        } else {
          Toaster.showError("Camera and Microphone permissions are required to join the meeting.");
          if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
            openAppSettings();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error navigating to meeting: $e");
      }
    }
  }

  static Future<void> showCallKitIncoming(Map<String, dynamic> data) async {
    final uuid = const Uuid().v4();
    
    // Get logo path from assets
    String logoPath = "";
    try {
      final byteData = await rootBundle.load('assets/image/app_lancher_logo_img.jpeg');
      final file = File('${(await getTemporaryDirectory()).path}/app_logo.jpeg');
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      logoPath = file.path;
    } catch (e) {
      if (kDebugMode) print("Error loading logo asset: $e");
    }

    final callKitParams = CallKitParams(
      id: uuid,
      nameCaller: data['caller_name'] ?? 'Meeting Invitation',
      appName: 'Arihanth',
      avatar: logoPath.isNotEmpty ? logoPath : 'https://i.pravatar.cc/100',
      handle: data['channel_name'] ?? 'Join Meeting',
      type: 0, // 0: Audio, 1: Video
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
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: logoPath.isNotEmpty ? logoPath : 'https://i.pravatar.cc/500',
        actionColor: '#4CAF50',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
  }

  static void listenerCallKit() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      switch (event!.event) {
        case Event.actionCallAccept:
          if (event.body['extra'] != null) {
            _navigateToMeeting(Map<String, dynamic>.from(event.body['extra']));
          }
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
      await FlutterCallkitIncoming.endAllCalls();
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
        // Check if token exists
        final String? token = SharedPreferencesHelper().getString("token");
        if (token != null && token.isNotEmpty) {
          // Add a small delay to ensure GetMaterialApp is initialized
          Future.delayed(const Duration(seconds: 1), () {
            _navigateToMeeting(Map<String, dynamic>.from(call['extra']));
          });
        }
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      await _notificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  static Future<String?> getToken() async {
    try {
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
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await FirebaseMessaging.instance.getAPNSToken();
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
