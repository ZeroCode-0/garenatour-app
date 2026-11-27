/// A normalized error surfaced from the API layer. Powered by NeXdEvE.
class ApiException implements Exception {
  ApiException(
    this.code,
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  bool get isNetwork => code == 'NETWORK';
  bool get isAuth => statusCode == 401 || code == 'AUTH_REQUIRED' || code == 'AUTH_INVALID';
  bool get isValidation => code == 'VALIDATION' || statusCode == 422;
  bool get isBanned => code == 'ACCOUNT_BANNED';
  bool get isMaintenance => code == 'APP_CLOSED' || code == 'NOT_INSTALLED';

  factory ApiException.network() =>
      ApiException('NETWORK', 'No internet connection. Check your network and try again.');

  factory ApiException.unknown([String? m]) =>
      ApiException('UNKNOWN', m ?? 'Something went wrong. Please try again.');

  @override
  String toString() => 'ApiException($code, $message)';
}
