import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceFingerprint {
  static const _kDeviceIdKey = 'device_id'; // do NOT clear on logout

  /// Always returns the same app-scoped device_id for this install.
  static Future<String> getOrCreateDeviceId() async {
    final sp = await SharedPreferences.getInstance();
    final existing = sp.getString(_kDeviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    String? newId;

    // 1) Prefer Android ID on Android (scoped to signing key + user since Android O)
    if (Platform.isAndroid) {
      try {
        final androidId = await const AndroidId().getId();
        if (androidId != null && androidId.isNotEmpty) newId = 'aid:$androidId';
      } catch (_) {}
    }

    // 2) Prefer IDFV on iOS
    if (newId == null && Platform.isIOS) {
      try {
        final info = await DeviceInfoPlugin().iosInfo;
        final idfv = info.identifierForVendor; // may be null on very first launch
        if (idfv != null && idfv.isNotEmpty) newId = 'idfv:$idfv';
      } catch (_) {}
    }

    // 3) Fallback to app-scoped UUID
    newId ??= 'uuid:${const Uuid().v4()}';

    await sp.setString(_kDeviceIdKey, newId);
    return newId;
  }

  /// Extra device context (nice-to-have for server logs / device verification UI)
  static Future<Map<String, dynamic>> getDeviceContext() async {
    final deviceId = await getOrCreateDeviceId();
    final deviceInfo = DeviceInfoPlugin();
    final pkg = await PackageInfo.fromPlatform();

    String platform = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : Platform.operatingSystem;
    String brand = '', model = '', osVersion = '';

    try {
      if (Platform.isAndroid) {
        final a = await deviceInfo.androidInfo;
        brand = a.brand ?? '';
        model = a.model ?? '';
        osVersion = 'Android ${a.version.release} (SDK ${a.version.sdkInt})';
      } else if (Platform.isIOS) {
        final i = await deviceInfo.iosInfo;
        brand = 'Apple';
        model = i.utsname.machine ?? i.model ?? '';
        osVersion = '${i.systemName} ${i.systemVersion}';
      }
    } catch (_) {}

    return {
      'device_id': deviceId,                    // <— stable ID you wanted
      'platform': platform,
      'brand': brand,
      'model': model,
      'os_version': osVersion,
      'app_version': '${pkg.version}+${pkg.buildNumber}',
      // optionally add 'fcm_token' at call-site where you already fetch it
    };
  }
}
