
import 'package:arianth/screens/login/model/user_response_model.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:arianth/screens/main_screen/main_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;
  final UserLoginResponse? user; // ✅ store full response here

  const LoginState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
    this.user,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
    UserLoginResponse? user,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final Ref ref;
  LoginNotifier(this.ref) : super(const LoginState());
  Future<void> login(String username, String password, BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);
   final String token = SharedPreferencesHelper().getString("DToken") ?? '';
    try {
      final response = await ApiClient().headerLessPost(
        endpoint: "api/login",
        body: {
          "email": username,
          "password": password,
          "fcm_token":token,
        },
      );

      print("Login Response: $response");

      if (response["status"] == 1) {
        final userData = UserLoginResponse.fromJson(response);

        await SharedPreferencesHelper().init();
        await SharedPreferencesHelper().setBool("isLoggedIn", true);
        await SharedPreferencesHelper().setString("token", userData.token);
        await SharedPreferencesHelper().setString("role", userData.role);
        await SharedPreferencesHelper().setString("name", userData.fullName);
        await SharedPreferencesHelper().setString("userId", userData.userId.toString());
        await SharedPreferencesHelper().setString("email", userData.email);
        await SharedPreferencesHelper().setString("user_code", userData.userCode ?? "");
        await SharedPreferencesHelper().setString("userBpCode", userData.bpCode ?? "");
        await SharedPreferencesHelper().setString("mobile", userData.mobile ?? "");
        await SharedPreferencesHelper().setString("businessName", userData.businessName ?? "");
        await SharedPreferencesHelper().setString("image", userData.image ?? "");
        await SharedPreferencesHelper().setString("aadharNo", userData.aadharNo ?? "");

        Toaster.showSuccess(userData.message.isNotEmpty
            ? userData.message
            : "Welcome To Your Dashboard");

        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          user: userData,
        );

        ref.read(menuIndexProvider.notifier).state = 0; // Reset sidebar to Dashboard
        Get.offAllNamed(AppRoutes.home);
      } else {
        final dynamic rawError = response['message'];
        String errorMsg = 'Login failed';
        if (rawError is String) {
          errorMsg = rawError;
        } else if (rawError is Map && rawError.containsKey('message')) {
          errorMsg = rawError['message'].toString();
        }
        Toaster.showError(errorMsg);
        state = state.copyWith(isLoading: false, error: errorMsg);
      }
    } catch (e, stackTrace) {
      print("Login error: $e\n$stackTrace");
      const errorMsg = "Network error. Please try again.";
      Toaster.showError(errorMsg);
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // 1. Initialize SharedPreferences
      await SharedPreferencesHelper().init();

      final token = await SharedPreferencesHelper().getString("token");

      if (token != null && token.isNotEmpty) {
        try {
          await ApiClient().get(endpoint: "api/logout");
        } catch (e) {
          debugPrint("Server-side logout failed, proceeding with local logout: $e");
        }
      }

      await SharedPreferencesHelper().clear();

      state = const LoginState();

      Toaster.showSuccess("Logged out successfully");
      ref.read(menuIndexProvider.notifier).state = 0; // Reset sidebar on logout
      Get.offAllNamed(AppRoutes.login);

    } catch (e, stackTrace) {
      debugPrint("Logout error: $e\n$stackTrace");
      Toaster.showError("An error occurred during logout");
      state = state.copyWith(isLoading: false, error: "Logout failed");
    }
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>(
      (ref) => LoginNotifier(ref),
);