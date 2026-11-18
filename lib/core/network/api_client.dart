import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../config/env.dart';
import 'api_exception.dart';

/// The single `dio` client in the app (Architecture.md). Only this class adds
/// `Authorization` — via [tokenProvider], set once auth (FR-107) exists.
class ApiClient {
  ApiClient({Dio? dio, this.tokenProvider}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = Env.apiBaseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenProvider?.call();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  /// Returns the current JWT, or null when signed out. Wired by auth (FR-107).
  final Future<String?> Function()? tokenProvider;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _unwrap(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path,
          {Object? data, Map<String, dynamic>? query}) =>
      _unwrap(() => _dio.post(path, data: data, queryParameters: query));

  Future<dynamic> put(String path, {Object? data}) =>
      _unwrap(() => _dio.put(path, data: data));

  Future<dynamic> delete(String path) => _unwrap(() => _dio.delete(path));

  /// Downloads raw bytes with the auth header attached (FR-1103: support
  /// attachments need `Authorization`, which an `Image.network`/`WebView`
  /// can't add on its own -- API.md section 12).
  Future<Uint8List> getBytes(String path) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<dynamic> _unwrap(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode;
    final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
    final message = detail is String
        ? detail
        : (detail != null ? detail.toString() : e.message ?? 'Network error');
    return ApiException(statusCode: status, message: message);
  }
}
