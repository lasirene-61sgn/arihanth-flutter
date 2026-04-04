import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ForgotPasswordState {
  final bool isLoading;
  final String? error;
  final String? role;
  final String? resetToken;

  const ForgotPasswordState({
    this.isLoading = false,
    this.error,
    this.role,
    this.resetToken,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? error,
    String? role,
    String? resetToken,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      role: role ?? this.role,
      resetToken: resetToken ?? this.resetToken,
    );
  }
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordNotifier() : super(const ForgotPasswordState());

  Future<bool> sendOtp({
    required String identifier,
    required String method,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient().headerLessPost(
        endpoint: 'api/forgot-password',
        body: {'identifier': identifier, 'method': method},
      );
      print(res);
      if (res['status'] == 1) {
        final data = res['data'];
        final String? role = data?['role']?.toString() ?? '';
        Toaster.showSuccess(data?['message']?.toString() ?? 'OTP sent successfully');
        state = state.copyWith(isLoading: false, role: role);
        return true;
      } else {
        String errorMsg = 'Failed to send OTP';
        if (res['message'] != null) {
          final m = res['message'];
          if (m is String) {
            errorMsg = m;
          } else if (m is Map) {
            if (m.containsKey('message')) errorMsg = m['message'].toString();
            else if (m.containsKey('errors')) {
              final errs = m['errors'];
              if (errs is Map && errs.isNotEmpty) {
                final firstErr = errs.values.first;
                if (firstErr is List && firstErr.isNotEmpty) errorMsg = firstErr.first.toString();
              }
            }
          }
        } else if (res['data']?['message'] != null) {
          errorMsg = res['data']['message'].toString();
        }
        Toaster.showError(errorMsg);
        state = state.copyWith(isLoading: false, error: errorMsg);
        return false;
      }
    } catch (_) {
      const errorMsg = 'Network error. Please try again.';
      Toaster.showError(errorMsg);
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient().headerLessPost(
        endpoint: 'api/verify-otp',
        body: {
          'identifier': identifier,
          'otp': otp,
          'role': state.role,
        },
      );
      if (res['status'] == 1) {
        final data = res['data'];
        final String? resetToken = data?['reset_token']?.toString();
        Toaster.showSuccess(data?['message']?.toString() ?? 'OTP verified!');
        state = state.copyWith(isLoading: false, resetToken: resetToken);
        return true;
      } else {
        String errorMsg = 'Invalid OTP';
        if (res['message'] != null) {
          final m = res['message'];
          if (m is String) {
            errorMsg = m;
          } else if (m is Map) {
            if (m.containsKey('message')) errorMsg = m['message'].toString();
            else if (m.containsKey('errors')) {
              final errs = m['errors'];
              if (errs is Map && errs.isNotEmpty) {
                final firstErr = errs.values.first;
                if (firstErr is List && firstErr.isNotEmpty) errorMsg = firstErr.first.toString();
              }
            }
          }
        } else if (res['data']?['message'] != null) {
          errorMsg = res['data']['message'].toString();
        }
        Toaster.showError(errorMsg);
        state = state.copyWith(isLoading: false, error: errorMsg);
        return false;
      }
    } catch (_) {
      const errorMsg = 'Network error. Please try again.';
      Toaster.showError(errorMsg);
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<bool> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient().headerLessPost(
        endpoint: 'api/reset-password',
        body: {
          "identifier": identifier,
          "otp": otp,
          'role': state.role,
          'reset_token': state.resetToken,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      print(res);
      if (res['status'] == 1) {
        final data = res['data'];
        Toaster.showSuccess(data?['message']?.toString() ?? 'Password reset successfully! Please login.');
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        String errorMsg = 'Reset failed';
        if (res['message'] != null) {
          final m = res['message'];
          if (m is String) {
            errorMsg = m;
          } else if (m is Map) {
            if (m.containsKey('message')) errorMsg = m['message'].toString();
            else if (m.containsKey('errors')) {
              final errs = m['errors'];
              if (errs is Map && errs.isNotEmpty) {
                final firstErr = errs.values.first;
                if (firstErr is List && firstErr.isNotEmpty) errorMsg = firstErr.first.toString();
              }
            }
          }
        } else if (res['data']?['message'] != null) {
          errorMsg = res['data']['message'].toString();
        }
        Toaster.showError(errorMsg);
        state = state.copyWith(isLoading: false, error: errorMsg);
        return false;
      }
    } catch (_) {
      const errorMsg = 'Network error. Please try again.';
      Toaster.showError(errorMsg);
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }
}

final forgotPasswordProvider =
    StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
        (ref) => ForgotPasswordNotifier());
