/// Uniform error shape for every API call, mapped from dio/HTTP failures.
class ApiException implements Exception {
  const ApiException({this.statusCode, required this.message});

  final int? statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isSuspended => statusCode == 403 && message == 'Account suspended';
  bool get mustChangePassword =>
      statusCode == 403 &&
      message == 'Please set your own password before buying or moving money.';
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
