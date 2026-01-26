// lib/common/call_restore.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/app_globals.dart';          // navigatorKey
import 'package:skillsconnect/HR/Calling/call_screen.dart';

/// Internal guards to avoid double navigation
bool _restoreInFlight = false;
String? _lastRestoredChannel;

Future<List<Map<String, dynamic>>> _getActiveCalls() async {
  try {
    final list = await FlutterCallkitIncoming.activeCalls();
    if (list is List) {
      return List<Map<String, dynamic>>.from(
          list.map((e) => Map<String, dynamic>.from(e as Map)));
    }
  } catch (_) {}
  try {
    // some plugin versions expose getActiveCalls()
    // ignore: deprecated_member_use
    final list = await FlutterCallkitIncoming.activeCalls();
    if (list is List) {
      return List<Map<String, dynamic>>.from(
          list.map((e) => Map<String, dynamic>.from(e as Map)));
    }
  } catch (_) {}
  return const [];
}

/// Waits for navigator to be ready (cold start), up to [timeoutMs]
Future<NavigatorState?> _awaitNav({int timeoutMs = 8000}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsedMilliseconds < timeoutMs) {
    final nav = navigatorKey.currentState;
    if (nav != null && nav.mounted) return nav;
    await Future.delayed(const Duration(milliseconds: 80));
  }
  return navigatorKey.currentState;
}

/// Call from the earliest point (RootRouter/Splash initState)
/// Returns true if it navigated to CallScreen.
Future<bool> tryRestoreCallFromCallKitOnce() async {
  if (_restoreInFlight) return false;
  _restoreInFlight = true;

  try {
    // 1) small retry loop: 6 attempts over ~3s to tolerate very cold starts
    Map<String, dynamic>? first;
    for (int i = 0; i < 6; i++) {
      final calls = await _getActiveCalls();
      if (calls.isNotEmpty) {
        first = Map<String, dynamic>.from(calls.first);
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (first == null) return false;

    final extra = Map<String, dynamic>.from(first['extra'] ?? {});
    final String channelId = (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? first['id'] ?? '').toString();
    final String callerId  = (extra['callerId'] ?? '').toString();
    final String receiverId= (extra['receiverId'] ?? '').toString();
    final String peerName  = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();

    if (channelId.isEmpty || callerId.isEmpty || receiverId.isEmpty) return false;
    if (_lastRestoredChannel == channelId) return false; // de-dupe

    final nav = await _awaitNav(timeoutMs: 8000);
    if (nav == null || !nav.mounted) return false;

    // Very important: DO NOT end the OS call UI before navigation on slow devices.
    // End it a bit later from CallScreen init; otherwise activeCalls() may turn empty.

    // Store flags so app re-opens correctly even if killed again
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_join', '{"channel":"$channelId","callerId":"$callerId","receiverId":"$receiverId","callerName":"$peerName"}');
      await prefs.setBool('call_nav_in_progress', true);
    } catch (_) {}

    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelId: channelId,
          callerId: callerId,
          receiverId: receiverId,
          peerName: peerName,
          isCaller: false,
        ),
      ),
          (_) => false,
    );

    _lastRestoredChannel = channelId;
    return true;
  } catch (_) {
    return false;
  } finally {
    _restoreInFlight = false;
  }
}
