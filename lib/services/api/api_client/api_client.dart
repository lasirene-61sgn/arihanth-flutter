import 'dart:io';


import 'package:arianth/services/widget/custom_msg.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ApiClient {
  // static const String baseUrl = "https://declivitous-limicoline-dotty.ngrok-free.dev/";
  // static const String baseUrl = "https://arianth.lasirene.xyz/";
  static const String baseUrl = "https://arihanthjewellers.in/";
  late final Dio _dio;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  // ------------------ INIT ------------------
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // baseUrl: "https://arianth.lasirene.xyz/",
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },

      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  // ------------------ TOKEN ------------------
  Future<String> _getToken() async {
    final prefs = await _prefs;
    final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
    final token = prefs.getString("token") ?? "";
    print(token);
    return isLoggedIn && token.isNotEmpty ? token : "";
  }

  // ------------------ URL HELPER ------------------
  /// Strips the scheme + host from a full URL and returns just the
  /// relative path + query string.
  ///
  /// Example:
  ///   https://anything.ngrok-free.dev/api/foo?page=2  →  api/foo?page=2
  ///   http://veto.co.in/api/bar                       →  api/bar
  ///   api/already-relative                            →  api/already-relative
  static String toRelativeUrl(String fullUrl) {
    try {
      final uri = Uri.parse(fullUrl);
      // If no host it's already relative
      if (uri.host.isEmpty) return fullUrl;
      // path starts with '/', drop it to match ApiClient conventions
      final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      return uri.query.isNotEmpty ? '$path?${uri.query}' : path;
    } catch (_) {
      return fullUrl;
    }
  }



  // ------------------ GET ------------------
  Future<dynamic> get({
    String? endpoint,
    Map<String, dynamic>? query,
  }) async {
    try {
      // _logRequest('GET', endpoint ?? '', query);
      final response = await _dio.get(
        endpoint ?? '',
        queryParameters: query,
      );
      print("get design url: $endpoint");
      return _handleResponse(response);
    } catch (e) {
      return _handleDioError(e);
    }
  }

  // ------------------ DOWNLOAD ------------------
  Future<dynamic> downloadFile({
    required String urlPath,
    required String savePath,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // _logRequest('DOWNLOAD', urlPath, queryParameters);
      final response = await _dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleDioError(e);
    }
  }

  // ------------------ POST ------------------
  Future<dynamic> post({
    String? endpoint,
    Map<String, dynamic>? body,
  }) async {
    try {
      // _logRequest('POST', endpoint ?? '', body);
      final response = await _dio.post(
        endpoint ?? '',
        data: body ?? {},
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleDioError(e);
    }
  }

  // ------------------ PUT (JSON) ------------------
  Future<dynamic> put({
    String? endpoint,
    Map<String, dynamic>? body,
  }) async {
    try {
      // _logRequest('PUT', endpoint ?? '', body);
      final response = await _dio.put(
        endpoint ?? '',
        data: body ?? {},
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleDioError(e);
    }
  }

  // ------------------ DELETE ------------------
  Future<dynamic> delete({
    String? endpoint,
    Map<String, dynamic>? body,
  }) async {
    try {
      // _logRequest('DELETE', endpoint ?? '', body);
      final response = await _dio.delete(
        endpoint ?? '',
        data: body,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleDioError(e);
    }
  }

  // ------------------ HEADER LESS POST ------------------
  Future<dynamic> headerLessPost({
    String? endpoint,
    Map<String, dynamic>? body,
  }) async {
    try {
      // _logRequest('POST (no auth)', endpoint ?? '', body);
      final dio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final response = await dio.post(
        endpoint ?? '',
        data: body ?? {},
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleDioError(e);
    }
  }

  // ------------------ REQUEST WITH FILES (UNIFIED) ------------------
  Future<dynamic> requestWithFiles({
    String? endpoint,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? files,
    String method = 'POST',
  }) async {
    // 1. Print all file names from the Map before probuicessing
    if (files != null && files.isNotEmpty) {
      print("--- Files being uploaded ---");
      files.forEach((key, value) {
        if (value is PlatformFile) {
          print("Field: $key | File Name: ${value.name}");
        } else if (value is List<PlatformFile>) {
          for (var i = 0; i < value.length; i++) {
            print("Field: $key[$i] | File Name: ${value[i].name}");
          }
        }
      });
      print("---------------------------");
    }

    try {
      final formData = FormData();

      if (fields != null) {
        _flattenFields(fields, "").forEach((entry) {
          formData.fields.add(entry);
        });
      }

      _attachFiles(formData, files);

      // _logRequest(method.toUpperCase(), endpoint ?? '', fields);

      final response = await _dio.request(
        endpoint ?? '',
        options: Options(method: method.toUpperCase()),
        data: formData,
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleDioError(e);
    }
  }

  // ------------------ FLATTEN HELPER ------------------
  List<MapEntry<String, String>> _flattenFields(dynamic value, String prefix) {
    List<MapEntry<String, String>> entries = [];

    if (value is Map) {
      value.forEach((k, v) {
        final newPrefix = prefix.isEmpty ? k : '$prefix[$k]';
        entries.addAll(_flattenFields(v, newPrefix));
      });
    } else if (value is List) {
      for (int i = 0; i < value.length; i++) {
        final newPrefix = '$prefix[$i]';
        entries.addAll(_flattenFields(value[i], newPrefix));
      }
    } else if (value != null) {
      entries.add(MapEntry(prefix, value.toString()));
    }

    return entries;
  }

  // ------------------ FILE HELPER ------------------
  void _attachFiles(FormData formData, Map<String, dynamic>? files) {
    if (files == null) return;

    files.forEach((key, value) {
      if (value == null) return;

      final list = value is List ? value : [value];

      for (final item in list) {
        if (item is PlatformFile) {
          final mime = lookupMimeType(item.name) ?? 'application/octet-stream';

          if (kIsWeb && item.bytes != null) {
            formData.files.add(
              MapEntry(
                key,
                MultipartFile.fromBytes(
                  item.bytes!,
                  filename: item.name,
                  contentType: MediaType.parse(mime),
                ),
              ),
            );
          } else if (!kIsWeb && item.path != null) {
            formData.files.add(
              MapEntry(
                key,
                MultipartFile.fromFileSync(
                  item.path!,
                  filename: item.name,
                  contentType: MediaType.parse(mime),
                ),
              ),
            );
          }
        }
      }
    });
  }

  // ------------------ RESPONSE HANDLER ------------------
  dynamic _handleResponse(Response response) {
    final status = response.statusCode ?? 0;

    if (status >= 200 && status < 300) {
      return {
        "status": 1,
        "data": response.data,
      };
    }

    if (status == 401) {
      return {
        "status": 2,
        "message": "Unauthenticated. Please login again.",
      };
    }

    return {
      "status": 0,
      "message": response.data ?? "Unexpected error",
    };
  }

  // ------------------ ERROR HANDLER ------------------
// ------------------ ERROR HANDLER ------------------
  dynamic _handleDioError(dynamic error) {
    if (error is DioException) {
      final response = error.response;

      // 1. Check for Timeout or Network Connection Errors
      if ({
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionError,
      }.contains(error.type) || error.error is SocketException) {
        Toaster.showError("Poor internet connection or server timeout. Please try again.");

        return {
          "status": 0,
          "message": "Poor internet connection or server timeout.",
        };
      }

      return {
        "status": 0,
        "message": response?.data ?? error.message,
      };
    }


    return {
      "status": 0,
      "message": "Unexpected error occurred",
    };
  }
}
