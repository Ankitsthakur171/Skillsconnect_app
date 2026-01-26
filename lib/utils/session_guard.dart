

// utils/session_guard.dart
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/student_app/ProfileLogic/ProfileEvent.dart';
import 'package:skillsconnect/student_app/blocpage/bloc_event.dart';
import '../Constant/constants.dart';
import '../HR/screens/splash_screen.dart';
import '../student_app/Utilities/auth/StudentAuth.dart';
import '../student_app/blocpage/bloc_logic.dart';
import '../student_app/ProfileLogic/ProfileLogic.dart';
import '../student_app/blocpage/BookmarkBloc/bookmarkLogic.dart';
import '../student_app/blocpage/BookmarkBloc/bookmarkEvent.dart';
import '../student_app/blocpage/jobFilterBloc/jobFilter_logic.dart';
import '../student_app/blocpage/jobFilterBloc/jobFilter_event.dart';

class SessionGuard {
  static GlobalKey<NavigatorState>? _navKey;
  static bool _enabled = false;            // 🔸 NEW: start disabled
  static bool _loggingOut = false;         // 🔸 NEW: re-entrancy guard

  static void init(GlobalKey<NavigatorState> key) { _navKey = key; }

  /// Call after you know user is authenticated
  ///
  static void enable() => _enabled = true;

  /// Call on logout / app start before auth check
  static void disable() => _enabled = false;

  /// Check if logout is currently in progress
  static bool get isLoggingOut {
    final result = _loggingOut;
    print('🔍 [SessionGuard.isLoggingOut] getter called, returning: $result');
    return result;
  }

  static Future<void> scan({int? statusCode, String? body}) async {
    print('🔍 [SessionGuard.scan] called with statusCode=$statusCode, enabled=$_enabled, loggingOut=$_loggingOut');

    if (!_enabled || statusCode == null) {
      print('🔍 [SessionGuard.scan] returning early - enabled: $_enabled, statusCode: $statusCode');
      return;
    }

    if (statusCode == 401) {
      print('🚨 [SessionGuard.scan] 401 detected - triggering logout');
      // await _forceLogoutWithMessage('You are currently logged in on another device.'
      //     ' Logging in here will log you out from the other device');
      await _forceLogoutWithMessage('You are currently logged in on another device.'
          ' Logging in here will log you out from the other device');
    } else if (statusCode == 403) {
      print('🚨 [SessionGuard.scan] 403 detected - triggering logout');
      await _forceLogoutWithMessage('Session expired.');
    } else {
      print('🔍 [SessionGuard.scan] statusCode $statusCode - no action needed');
    }
  }

  static Future<void> _forceLogoutWithMessage(String message) async {
    print('🚪 [_forceLogoutWithMessage] START - message: $message');

    if (_loggingOut) {
      print('🚪 [_forceLogoutWithMessage] already logging out, returning');
      return;
    }
    _loggingOut = true;
    print('🚪 [_forceLogoutWithMessage] set _loggingOut = true');

    try {
      final ctx = _navKey?.currentContext;
      print('🚪 [_forceLogoutWithMessage] context available: ${ctx != null}');

      // 1️⃣ SnackBar dikhao (agar context available ho)
      if (ctx != null) {
        print('🚪 [_forceLogoutWithMessage] showing snackbar');
        ScaffoldMessenger.of(ctx).clearSnackBars();
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 40,  // ⬆️ adjust this value to move it higher
              left: 16,
              right: 16,
            ),
            duration: const Duration(seconds: 10), // ⏱️ now visible for 10 sec
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 900));
        print('🚪 [_forceLogoutWithMessage] snackbar delay completed');
      }

      // 2️⃣ Logout API hit karo (token ke sath)
      print('🚪 [_forceLogoutWithMessage] calling logout API');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      // ✅ Multi-login safety: detach this device token from the old user before clearing prefs.
      try {
        if (token != null && token.isNotEmpty) {
          print('🚪 [_forceLogoutWithMessage] updating FCM token');
          await http.post(
            Uri.parse('${BASE_URL}common/update-fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'fcmToken': ''}),
          );
        }
      } catch (_) {}
      try {
        print('🚪 [_forceLogoutWithMessage] deleting FCM token');
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}

      try {
        print('🚪 [_forceLogoutWithMessage] calling logout endpoint');
        final response = await http.post(
          Uri.parse("${BASE_URL}auth/logout"),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        );

        debugPrint("🔸 Logout API status: ${response.statusCode}");
      } catch (e) {
        debugPrint("⚠️ Logout API failed: $e");
      }

      // 3️⃣ Tokens wipe - Clear ALL token formats (HR/TPO + Student)
      print('🚪 [_forceLogoutWithMessage] clearing tokens');
      await prefs.remove('auth_token');      // HR/TPO format
      await prefs.remove('authToken');       // Student format
      await prefs.remove('connectSid');      // Student cookie
      await prefs.remove('user_data');
      await prefs.remove('user_id');

      // Clear student-specific data
      print('🚪 [_forceLogoutWithMessage] clearing student data');
      await StudentAuth.clearAuth();

      // 4️⃣ Reset student BLoCs to clear navigation state
      if (ctx != null) {
        print('🚪 [_forceLogoutWithMessage] resetting blocs');
        try {
          final navBloc = ctx.findAncestorWidgetOfExactType<BlocProvider<NavigationBloc>>();
          if (navBloc != null) {
            ctx.read<NavigationBloc>().add(ResetNavigation());
          }
        } catch (_) {}

        try {
          final profileBloc = ctx.findAncestorWidgetOfExactType<BlocProvider<ProfileBloc>>();
          if (profileBloc != null) {
            ctx.read<ProfileBloc>().add(ResetProfileData());
          }
        } catch (_) {}

        try {
          final bookmarkBloc = ctx.findAncestorWidgetOfExactType<BlocProvider<BookmarkBloc>>();
          if (bookmarkBloc != null) {
            ctx.read<BookmarkBloc>().add(ResetBookmarksEvent());
          }
        } catch (_) {}

        try {
          final jobFilterBloc = ctx.findAncestorWidgetOfExactType<BlocProvider<JobFilterBloc>>();
          if (jobFilterBloc != null) {
            ctx.read<JobFilterBloc>().add(ResetJobFilters());
          }
        } catch (_) {}
      }

      // 5️⃣ Safe navigation to unified login (SplashScreen)
      print('🚪 [_forceLogoutWithMessage] navigating to splash screen');
      if (ctx != null) {
        Future.microtask(() {
          Navigator.of(ctx).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
                (_) => false,
          );
        });
      }
    } finally {
      print('🚪 [_forceLogoutWithMessage] finally block - resetting flags');
      _enabled = false;     // logout ke baad guard OFF
      _loggingOut = false;
    }

    print('🚪 [_forceLogoutWithMessage] COMPLETED');
  }
}
