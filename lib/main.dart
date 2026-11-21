import 'dart:ui';
import 'package:arianth/services/api/notification_service/notifiction_service.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/network_service/network_error_screen.dart';
import 'package:arianth/services/network_service/network_notifier.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/routes/route_page/route_page.dart';
import 'package:arianth/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:arianth/screens/splash/ui/splash_screen.dart';
import 'package:upgrader/upgrader.dart';

import 'firebase_options.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("=================== FCM BACKGROUND PAYLOAD ===================");
  print("🔥 [BACKGROUND FCM] Message received: ${message.messageId}");
  print("🔥 [BACKGROUND FCM] Title: ${message.notification?.title}");
  print("🔥 [BACKGROUND FCM] Body: ${message.notification?.body}");
  print("🔥 [BACKGROUND FCM] Data Keys: ${message.data.keys.toList()}");
  message.data.forEach((key, value) {
    print("🔥 [BACKGROUND FCM]   - $key : $value");
  });
  print("==============================================================");

  final isMeeting = message.data['action'] == 'join_meeting' ||
      message.data['meeting_id'] != null ||
      message.data['room_id'] != null ||
      message.data['call_type'] != null;

  if (isMeeting) {
    print("📞 [BACKGROUND FCM] Triggering showCallKitIncoming for meeting...");
    await NotificationService.showCallKitIncoming(message.data);
    print("📞 [BACKGROUND FCM] CallKit incoming call triggered successfully!");
  } else {
    print("ℹ️ [BACKGROUND FCM] Not a meeting push, showing local notification with direct reply action...");
    await NotificationService.showLocalNotification(message);
  }
  print("==================================================");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase.initializeApp error: $e");
  }

  await SharedPreferencesHelper().init();

  // Run app immediately so iOS Watchdog timer never terminates app on startup
  final String? token = SharedPreferencesHelper().getString("token");
  final String initialRoute = (token != null && token.isNotEmpty)
      ? AppRoutes.home
      : AppRoutes.login;

  runApp(
    ProviderScope(
      child: MyApp(initialRoute: initialRoute),
    ),
  );

  // Initialize background push notifications, VoIP, and FCM tokens asynchronously
  _initServicesAsync();
}

Future<void> _initServicesAsync() async {
  try {
    await NotificationService.init();

    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        String? apnsToken = await NotificationService.getAPNSToken();
        if (apnsToken != null) {
          debugPrint("--------- APNS TOKEN ---------\n$apnsToken\n------------------------------");
        }
      } catch (e) {
        debugPrint("Error getting APNS token: $e");
      }

      try {
        String? voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
        if (voipToken != null && voipToken.isNotEmpty) {
          debugPrint("--------- VOIP TOKEN (PushKit for Meetings) ---------\n$voipToken\n-----------------------------------------------------");
          await SharedPreferencesHelper().setString("VoIPToken", voipToken);
        }
      } catch (e) {
        debugPrint("Error getting VoIP token: $e");
      }
    }

    try {
      String? deviceToken = await NotificationService.getToken();
      if (deviceToken != null && deviceToken.isNotEmpty) {
        debugPrint("--------- DEVICE TOKEN ---------\n$deviceToken\n--------------------------------");
        await SharedPreferencesHelper().setString("DToken", deviceToken);
      }
    } catch (e) {
      debugPrint("Error getting device token: $e");
    }

    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint("App launched from terminated state via notification: ${initialMessage.data}");
        final isMeeting = initialMessage.data['action'] == 'join_meeting' ||
            initialMessage.data['meeting_id'] != null ||
            initialMessage.data['room_id'] != null ||
            initialMessage.data['call_type'] != null;

        if (!isMeeting) {
          Future.delayed(const Duration(seconds: 1), () {
            NotificationService.navigateToChat(initialMessage.data);
          });
        }
      }
    } catch (e) {
      debugPrint("Error handling initial notification: $e");
    }
  } catch (e) {
    debugPrint("Background services init error: $e");
  }
}

class MyApp extends ConsumerWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ta'),
        Locale('hi'),
        Locale('bn'),
        Locale('mr'),
        Locale('te'),
        Locale('gu'),
        Locale('ur'),
        Locale('kn'),
        Locale('or'),
        Locale('ml'),
        Locale('pa'),
      ],
      localizationsDelegates:  [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,

      home: SplashScreen(targetRoute: initialRoute),
      getPages: AppPages.routes,

      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      builder: (context, child) {
        return UpgradeAlert(
          upgrader: Upgrader(),
          showIgnore: false,
          showLater: true,
          dialogStyle: UpgradeDialogStyle.cupertino,
          child: Stack(
            children: [
              child!,
              Consumer(
                builder: (context, ref, _) {
                  final isConnectedAsync = ref.watch(networkStatusProvider);
                  final isConnected = isConnectedAsync.maybeWhen(
                    data: (value) => value,
                    orElse: () => true,
                  );
  
                  if (!isConnected) return const NetworkOverlay();
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
