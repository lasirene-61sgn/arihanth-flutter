import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';

class RegistrationState {
  final bool isLoading;
  final String? error;

  const RegistrationState({
    this.isLoading = false,
    this.error,
  });

  RegistrationState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return RegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier() : super(const RegistrationState());

  Future<void> register({
    required String name,
    required String email,
    required String mobile,
    required String businessName,
    String? city,
    String? stateName,
    String? pincode,
    String? address,
    String? gstNo,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient().headerLessPost(
        endpoint: "api/register",
        body: {
          "name": name,
          "email": email,
          "mobile": mobile,
          "business_name": businessName,
          "city": city,
          "state": stateName,
          "pincode": pincode,
          "address": address,
          "gst_no": gstNo,
          "password": password,
        },
      );

      print("Registration Response: $response");

      if (response["status"] == 1) {
        final apiData = response["data"];
        final message = (apiData is Map && apiData.containsKey('message')) 
            ? apiData['message'] 
            : "Registration successful!";
        
        Toaster.showSuccess(message);
        state = state.copyWith(isLoading: false);
        Get.offAllNamed(AppRoutes.login);
      } else {
        final dynamic rawError = response['message'];
        String errorMsg = 'Registration failed';
        
        if (rawError is String) {
          errorMsg = rawError;
        } else if (rawError is Map) {
          // Handle Laravel validation errors map
          final List<String> errors = [];
          rawError.forEach((key, value) {
            if (value is List) {
              errors.addAll(value.map((e) => e.toString()));
            } else {
              errors.add(value.toString());
            }
          });
          if (errors.isNotEmpty) {
            errorMsg = errors.join("\n");
          } else if (rawError.containsKey('message')) {
            errorMsg = rawError['message'].toString();
          }
        }
        
        Toaster.showError(errorMsg);
        state = state.copyWith(isLoading: false, error: errorMsg);
      }
    } catch (e) {
      print("Registration error: $e");
      const errorMsg = "Network error. Please try again.";
      Toaster.showError(errorMsg);
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }
}

final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>(
  (ref) => RegistrationNotifier(),
);
