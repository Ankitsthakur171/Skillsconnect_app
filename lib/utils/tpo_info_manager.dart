import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInfoManager extends ChangeNotifier {
  // Singleton
  static final UserInfoManager _instance = UserInfoManager._internal();
  factory UserInfoManager() => _instance;
  UserInfoManager._internal();

  // Pref keys (legacy + new)
  static const _kImg           = 'userImg';         // legacy
  static const _kProfileImage  = 'profile_image';   // ✅ new (use this in AppBar)
  static const _kName          = 'fullName';
  static const _kRole          = 'role';
  static const _kCollege       = 'college_name';

  String? userImg;
  String? fullName;
  String? role;
  String? collegeName;

  bool _isLoaded = false;

  String? _nz(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }


  Future<void> initFromPrefs() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();

    userImg     = _nz(prefs.getString(_kProfileImage)) ?? _nz(prefs.getString(_kImg));
    fullName    = _nz(prefs.getString(_kName));
    role        = _nz(prefs.getString(_kRole));
    collegeName = _nz(prefs.getString(_kCollege));
    _isLoaded   = true;

    if (kDebugMode) {
      debugPrint('🟢 initFromPrefs -> img=$userImg, role=$role, college=$collegeName');
    }

    notifyListeners(); // 👈 important: first build me hi repaint ho
  }

  Future<String?> getProfileImageCached() async {
    if (userImg != null) return userImg;               // 👈 no Future delay
    final prefs = await SharedPreferences.getInstance();
    userImg = _nz(prefs.getString(_kProfileImage)) ?? _nz(prefs.getString(_kImg));
    return userImg;
  }

  Future<String?> getCollegeNameCached() async {
    if (collegeName != null) return collegeName;       // 👈 no Future delay
    final prefs = await SharedPreferences.getInstance();
    collegeName = _nz(prefs.getString(_kCollege));
    return collegeName;
  }


  /// 🔴 Call this on logout: clears prefs + in-memory + resets loaded flag.
  Future<void> clearOnLogout() async {
    final prefs = await SharedPreferences.getInstance();

    // remove only our keys (safer than prefs.clear())
    await prefs.remove(_kProfileImage); // ✅ new
    await prefs.remove(_kImg);          // legacy
    await prefs.remove(_kName);
    await prefs.remove(_kRole);
    await prefs.remove(_kCollege);

    // reset in-memory state
    userImg     = null;
    fullName    = null;
    role        = null;
    collegeName = null;
    _isLoaded   = false;

    if (kDebugMode) debugPrint('🚪 Logged out: user info cache cleared');
  }

  ///  - सावधानी से use करें (ये *सभी* prefs मिटा देगा)
  Future<void> nukeAllPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    userImg = fullName = role = collegeName = null;
    _isLoaded = false;
    if (kDebugMode) debugPrint('🧨 All SharedPreferences cleared');
  }

  Future<void> loadUserDataOnce(
      Future<Map<String, dynamic>> Function() getUserData, {
        bool forceReload = false,
      }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!_isLoaded) {
      await initFromPrefs();
    }
    if (!forceReload && (userImg?.isNotEmpty == true || role?.isNotEmpty == true)) {
      return;
    }

    final data = await getUserData();

    userImg     = _nz((data['user_image'] ?? data['user_img'])?.toString());
    fullName    = _nz(data['full_name']?.toString());
    role        = _nz(data['role']?.toString());
    collegeName = _nz(data['college_name']?.toString());
    _isLoaded   = true;

    // ✅ write-or-remove (no empty strings!)
    if (userImg == null) {
      await prefs.remove(_kProfileImage);
      await prefs.remove(_kImg);
    } else {
      await prefs.setString(_kProfileImage, userImg!);
      await prefs.setString(_kImg,          userImg!);
    }

    if (fullName == null) await prefs.remove(_kName); else await prefs.setString(_kName, fullName!);
    if (role == null)     await prefs.remove(_kRole); else await prefs.setString(_kRole, role!);

    if (collegeName == null) await prefs.remove(_kCollege); else await prefs.setString(_kCollege, collegeName!);

    if (kDebugMode) {
      debugPrint('✅ loaded & cached -> img=$userImg, role=$role, college=$collegeName');
    }

    notifyListeners(); // 👈 UI ko immediately repaint karao
  }


  Future<void> setUserImage(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    userImg = _nz(url);

    if (userImg == null) {
      await prefs.remove(_kProfileImage);
      await prefs.remove(_kImg);
    } else {
      await prefs.setString(_kProfileImage, userImg!);
      await prefs.setString(_kImg,          userImg!);
    }

    if (kDebugMode) debugPrint('📝 setUserImage: $userImg');
    notifyListeners(); // 👈
  }

  Future<void> setCollegeName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    collegeName = _nz(name);

    if (collegeName == null) {
      await prefs.remove(_kCollege);
    } else {
      await prefs.setString(_kCollege, collegeName!);
    }

    if (kDebugMode) debugPrint('🏫 setCollegeName: $collegeName');
    notifyListeners(); // 👈
  }

}
