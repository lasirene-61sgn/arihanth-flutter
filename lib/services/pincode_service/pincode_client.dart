import 'dart:convert';
import 'package:arianth/services/pincode_service/pin_code_model.dart';
import 'package:dio/dio.dart';

class PincodeApiService {
  static const String _baseUrl = 'https://api.postalpincode.in';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    // Don't throw on 4xx/5xx - handle manually
    validateStatus: (status) => status != null && status < 500,
  ));

  Future<List<PincodePostOffice>> fetchByPincode(String pincode) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      throw ArgumentError('Pincode must be a 6-digit number');
    }

    try {


      final response = await _dio.get('/pincode/$pincode');

      // 🔥 DEBUG: Log raw response for debugging


      // Handle non-200 status codes
      if (response.statusCode != 200) {

        throw Exception('Server returned ${response.statusCode}: ${response.statusMessage}');
      }

      // API returns a List, not a single object [[6]][[8]]
      if (response.data is! List) {

        throw Exception('Invalid API response format: expected List, got ${response.data.runtimeType}');
      }

      final List<dynamic> responseData = response.data;

      if (responseData.isEmpty) {
        throw Exception('Empty response from API');
      }

      // Parse first response object
      final firstResponse = responseData[0];

      if (firstResponse is! Map<String, dynamic>) {

        throw Exception('Invalid response structure');
      }

      final pincodeResponse = PincodeResponse.fromJson(firstResponse);



      if (!pincodeResponse.isSuccess) {
        // API returned error status
        throw Exception(pincodeResponse.message.isEmpty ? 'Pincode not found' : pincodeResponse.message);
      }

      if (!pincodeResponse.hasData) {
        throw Exception('No post offices found for pincode: $pincode');
      }


      return pincodeResponse.postOffices!;

    } on DioException catch (e) {
      // 🔥 DEBUG: Log full DioException details


      if (e.response != null) {

      }

      // User-friendly error messages
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception('Connection timeout. Check your internet.');
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          if (status == 404) {
            throw Exception('Pincode not found in database');
          } else if (status == 429) {
            throw Exception('Too many requests. Please try again later.');
          }
          throw Exception('Server error (${status ?? 'unknown'}). Please try again.');
        case DioExceptionType.cancel:
          throw Exception('Request cancelled');
        default:
          throw Exception('Network error: ${e.message ?? 'Unknown error'}');
      }

    } catch (e, stack) {

      rethrow;
    }
  }
}