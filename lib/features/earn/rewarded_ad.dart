// Picks the real AdMob implementation on Android/iOS and a stub on web.
export 'rewarded_ad_stub.dart' if (dart.library.io) 'rewarded_ad_mobile.dart';
