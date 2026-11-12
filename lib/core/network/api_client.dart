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

  Future<dynamic> post(String path, {Object? data}) =>
      _unwrap(() => _dio.post(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _unwrap(() => _dio.put(path, data: data));

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
