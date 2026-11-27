/// App-wide configuration. Powered by NeXdEvE.
class Env {
  Env._();

  /// Backend base — the USER API.
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://garenatour.com/api/user',
  );

  static const String siteUrl = 'https://garenatour.com';
  static const String appName = 'Garena Tour';
  static const String poweredBy = 'NeXdEvE';

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Access token lifetime is 15 min on the server; refresh a bit early.
  static const Duration accessSkew = Duration(seconds: 45);
}
