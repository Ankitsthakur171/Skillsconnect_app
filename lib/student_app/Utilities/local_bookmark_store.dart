import 'package:shared_preferences/shared_preferences.dart';

/// Simple local cache for bookmark state
/// Key format: bookmark:<Module>:<moduleId>
class LocalBookmarkStore {
  static const _prefix = 'bookmark:';

  static String _key(String module, int moduleId) => '$_prefix$module:$moduleId';

  static Future<bool> get(String module, int moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(module, moduleId);
    final value = prefs.getBool(key) ?? false;
    print('[LocalBookmarkStore.get] $key → $value');
    return value;
  }

  static Future<void> set(String module, int moduleId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(module, moduleId);
    await prefs.setBool(key, value);
    print('[LocalBookmarkStore.set] $key ← $value');
  }
}
