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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:arianth/screens/splash/ui/splash_screen.dart';
import 'package:upgrader/upgrader.dart';

import 'firebase_options.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    print("Handling background message: ${message.messageId}");
    print("Data: ${message.data}");
  }

  if (message.data['action'] == 'join_meeting') {
    await NotificationService.showCallKitIncoming(message.data);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await SharedPreferencesHelper().init();
  await NotificationService.init();

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    String? apnsToken = await NotificationService.getAPNSToken();
    if (apnsToken != null) {
      print("--------- APNS TOKEN ---------");
      print(apnsToken);
      print("------------------------------");
    }
  }

  String? deviceToken = await NotificationService.getToken();
  if (deviceToken != null) {
    print("--------- DEVICE TOKEN ---------");
    print(deviceToken);
    SharedPreferencesHelper().setString("DToken", deviceToken);
    print("--------------------------------");
  } else {
    print("Device token is null");
  }


  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print("App launched from terminated state via notification");
    // You can handle redirection logic here or inside NotificationService
  }

  final String? token = SharedPreferencesHelper().getString("token");
  final String initialRoute = (token != null && token.isNotEmpty)
      ? AppRoutes.home
      : AppRoutes.login;

  runApp(
    ProviderScope(
      child: MyApp(initialRoute: initialRoute),
    ),
  );
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
