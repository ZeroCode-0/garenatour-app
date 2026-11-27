import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A stable per-install device id + a friendly device name.
/// Powered by NeXdEvE.
class DeviceInfo {
  DeviceInfo._(this.id, this.name);

  final String id;
  final String name;

  static DeviceInfo? _cached;

  static Future<DeviceInfo> load() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();

    var id = prefs.getString('bz_device_id');
    if (id == null || id.isEmpty) {
      id = _randomId();
      await prefs.setString('bz_device_id', id);
    }

    String name = 'Mobile';
    try {
      final plugin = DeviceInfoPlugin();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final a = await plugin.androidInfo;
        name = '${a.manufacturer} ${a.model}'.trim();
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final i = await plugin.iosInfo;
        name = i.utsname.machine;
      }
    } catch (_) {}

    _cached = DeviceInfo._(id, name.isEmpty ? 'Mobile' : name);
    return _cached!;
  }

  static String _randomId() {
    final r = Random.secure();
    final bytes = List<int>.generate(20, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
