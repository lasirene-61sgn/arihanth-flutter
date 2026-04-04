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
    // Don't call real API, just update state
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 50));
    state = state.copyWith(isLoading: false, isLoggedIn: true);
  }
}

void main() {
  // Setup for all tests
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel firebaseChannel = MethodChannel('plugins.flutter.io/firebase_messaging');
  const MethodChannel firebaseCoreChannel = MethodChannel('plugins.flutter.io/firebase_core');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    
    // Mock Firebase Core to prevent crash on Firebase.initializeApp() or FirebaseMessaging.instance
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(firebaseCoreChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeApp') {
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake',
            'appId': 'fake',
            'messagingSenderId': 'fake',
            'projectId': 'fake',
          },
          'pluginConstants': {},
        };
      }
      return null;
    });

    // Mock Firebase Messaging to prevent crash on getToken()
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(firebaseChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'FirebaseMessaging#getToken') {
        return 'fake_device_token';
      }
      return null;
    });
  });

  group('Login Screen Widget Tests', () {
    testWidgets('Scenario 1: Initial state check (UI Presence)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Check for header logo (AssetImage)
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      // Check for Header Text
      // Note: Since we haven't loaded real translations, it might show the key or the default text
      // In this app, ref.watchTr('login') returns the key if not found, usually 'Login' in en.dart
      expect(find.textContaining(RegExp('Login', caseSensitive: false)), findsWidgets);
      
      // Check for Input Fields
      expect(find.byType(CustomInputField), findsNWidgets(2));
      
      // Check for Login Button
      expect(find.byType(CustomButton), findsOneWidget);
      expect(find.textContaining(RegExp('LOGIN', caseSensitive: false)), findsOneWidget);
    });

    testWidgets('Scenario 2: Validation check (Empty Fields)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Tap Login Button without entering data
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      // Check for validation error text "Required" (from login.dart:134, 150)
      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('Scenario 3: Password visibility toggle', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Find the password field
      final passwordField = find.byType(CustomInputField).last;
      final CustomInputField widget = tester.widget(passwordField);
      
      // Initially it should be obscured
      expect(widget.obscureText, isTrue);

      // Find and tap the visibility icon
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Now it should NOT be obscured
      final updatedWidget1 = tester.widget<CustomInputField>(passwordField);
      expect(updatedWidget1.obscureText, isFalse);
      
      // Tap again to obscure
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      
      final updatedWidget2 = tester.widget<CustomInputField>(passwordField);
      expect(updatedWidget2.obscureText, isTrue);
    });

    testWidgets('Scenario 4: Successful Data Entry (sa001 / password)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter User Code
      await tester.enterText(find.byType(CustomInputField).first, 'sa001');
      // Enter Password
      await tester.enterText(find.byType(CustomInputField).last, 'password');
      
      await tester.pump();

      // Verify text is entered
      expect(find.text('sa001'), findsOneWidget);
      expect(find.text('password'), findsOneWidget);
    });

    testWidgets('Scenario 5: Login trigger (sa001 / password)', (tester) async {
      // Create a specific override for this test
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

      // Enter credentials
      await tester.enterText(find.byType(CustomInputField).first, 'sa001');
      await tester.enterText(find.byType(CustomInputField).last, 'password');
      
      // Tap Login
      await tester.tap(find.byType(CustomButton));
      await tester.pump(); // Start the async operation

      // Access the notifier from the tree
      final element = tester.element(find.byType(LoginScreen));
      final container = ProviderScope.containerOf(element);
      final notifier = container.read(loginProvider.notifier) as MockLoginNotifier;
      
      expect(notifier.loginCalled, isTrue);
      expect(notifier.lastUsername, 'sa001');
      expect(notifier.lastPassword, 'password');
      
      // Verify loading state appears
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
