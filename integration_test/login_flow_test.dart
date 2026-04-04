import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/login/riverpod/login_notifier.dart';
import 'package:arianth/screens/login/ui/login.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock Notifier to capture login attempts
class MockLoginNotifier extends LoginNotifier {
  bool loginCalled = false;
  String? lastUsername;
  String? lastPassword;

  MockLoginNotifier(super.ref);

  @override
  Future<void> login(String username, String password, BuildContext context) async {
    loginCalled = true;
    lastUsername = username;
    lastPassword = password;
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 1)); // Delay for visual feedback
    state = state.copyWith(isLoading: false, isLoggedIn: true);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize dummy Firebase to satisfy FirebaseMessaging.instance checks
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'fake_api_key',
          appId: 'fake_app_id',
          messagingSenderId: 'fake_sender_id',
          projectId: 'fake_project_id',
        ),
      );
    } catch (e) {
      // Already initialized or failed due to environment issues
      debugPrint("Firebase initialization info: $e");
    }
  });

  const MethodChannel firebaseChannel = MethodChannel('plugins.flutter.io/firebase_messaging');
  const MethodChannel notificationChannel = MethodChannel('dexterous.com/flutter/local_notifications');

  setUp(() async {
    // Mock Firebase Messaging to stop real-device crashes on requestPermission and getToken
    // Based on logs, the method names are prefixed with 'Messaging#'
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(firebaseChannel, (MethodCall methodCall) async {
      debugPrint("Mocking FirebaseMessaging call: ${methodCall.method}");
      if (methodCall.method == 'Messaging#requestPermission') {
        return {
          'alert': 1,
          'announcement': 1,
          'badge': 1,
          'carPlay': 1,
          'criticalAlert': 1,
          'provisional': 1,
          'sound': 1,
          'lockScreen': 1,
          'notificationCenter': 1,
          'showPreviews': 1,
          'authorizationStatus': 1, // authorized
        };
      }
      if (methodCall.method == 'Messaging#getToken') {
        return 'fake_device_token';
      }
      return null;
    });

    // Mock Local Notifications to prevent crashes during initialization
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(notificationChannel, (MethodCall methodCall) async {
      debugPrint("Mocking LocalNotification call: ${methodCall.method}");
      if (methodCall.method == 'initialize') return true;
      return null;
    });
  });

  group('Login Flow Integration Test - Real Device', () {
    testWidgets('Full Login Sequence with Delays and Retry Logic', (tester) async {
      // Helper for the requested 5-10s gap
      Future<void> gap() async {
        print("Waiting for 7 seconds...");
        await Future.delayed(const Duration(seconds: 7));
        await tester.pumpAndSettle();
      }

      // Load the app with mocked login provider
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginProvider.overrideWith((ref) => MockLoginNotifier(ref)),
          ],
          child: const GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await gap();

      // --- 4 Wrong Info Attempts ---
      for (int i = 1; i <= 4; i++) {
        print("Attempt $i: Entering wrong info...");
        await tester.enterText(find.byType(CustomInputField).first, 'wronguser_$i');
        await tester.enterText(find.byType(CustomInputField).last, 'wrongpass_$i');
        await tester.pumpAndSettle();
        await gap();

        print("Attempt $i: Tapping LOGIN...");
        await tester.tap(find.byType(CustomButton));
        // In a real app, this would show an error. In our mock, we just observe the tap.
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await gap();
      }

      // --- 5th Attempt: Correct Info ---
      print("Attempt 5: Entering CORRECT info (sa001 / password)...");
      await tester.enterText(find.byType(CustomInputField).first, 'sa001');
      await tester.enterText(find.byType(CustomInputField).last, 'password');
      await tester.pumpAndSettle();
      await gap();

      print("Attempt 5: Tapping LOGIN with correct info...");
      await tester.tap(find.byType(CustomButton));
      
      // Wait for loading indicator to appear
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for the mock delay to complete and state to update
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      print("Login test completed successfully on real device after 5 attempts!");
      
      // Final gap to observe the success screen if any
      await gap();
    });
  });
}
