import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../Constant/constants.dart';
import '../../Calling/call_incoming_watcher.dart';
import '../login_screen.dart';
import '../../../utils/session_guard.dart';
              // LoginScreen

class ForceLogout {
  ForceLogout._();
  static bool _inProgress = false;

  static void run(BuildContext context, {String? message}) {
    // build ke beech navigation/async na ho, isliye next frame me
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doLogout(context, message: message);
    });
  }

  static Future<void> _doLogout(BuildContext context, {String? message}) async {
    if (_inProgress) return;
    _inProgress = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // ✅ Multi-login safety: detach this device token from the old user before clearing prefs.
      try {
        if (token != null && token.isNotEmpty) {
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
      try { await FirebaseMessaging.instance.deleteToken(); } catch (_) {}

      // Try server logout (best-effort)
      try {
        await http.post(
          Uri.parse("${BASE_URL}auth/logout"),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
        );
      } catch (_) {}

      // Local cleanup
      await prefs.remove('pending_join');
      await prefs.clear();

      // Disable global 401 guard after logout
      SessionGuard.disable();

      // Stop any background listeners
      CallIncomingWatcher.stop();

      if (!context.mounted) return;

      // Optional toast/snackbar
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              backgroundColor: Colors.red, // 🔴 red background
              behavior: SnackBarBehavior.floating, // ⬅️ make it float
              margin: const EdgeInsets.only(
                bottom: 40,  // ⬆️ adjust this value to move it higher
                left: 16,
                right: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(seconds: 10),
            ),
          );
      }

      // Go to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
      );
    } finally {
      _inProgress = false;
    }
  }
}
