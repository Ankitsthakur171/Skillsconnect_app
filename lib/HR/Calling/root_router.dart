// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../screens/splash_screen.dart';
// import 'call_screen.dart';
//
//
// class RootRouter extends StatefulWidget {
//   const RootRouter({super.key});
//   @override
//   State<RootRouter> createState() => _RootRouterState();
// }
//
// class _RootRouterState extends State<RootRouter> {
//   @override
//   void initState() {
//     super.initState();
//     _route();
//   }
//
//   Future<void> _route() async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString('pending_join') ?? '';
//     debugPrint("🔎 RootRouter pending_join = $raw");
//
//     if (raw.isNotEmpty) {
//       await prefs.remove('pending_join');
//       final extra = Map<String, dynamic>.from(jsonDecode(raw));
//
//       final channelId = (extra['channel'] ?? extra['callId'] ?? '').toString();
//       final callerId  = (extra['callerId'] ?? '').toString();
//       final receiverId= (extra['receiverId'] ?? '').toString();
//       final peerName  = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();
//
//       if (!mounted) return;
//       Navigator.pushReplacement(context, MaterialPageRoute(
//         builder: (_) => CallScreen(
//           channelId: channelId,
//           callerId: callerId,
//           receiverId: receiverId,
//           peerName: peerName,
//           isCaller: false,
//         ),
//       ));
//       return;
//     }
//
//     // default case → splash
//     if (!mounted) return;
//     Navigator.pushReplacement(context,
//       MaterialPageRoute(builder: (_) => const SplashScreen()),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) => const SizedBox.shrink();
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/splash_screen.dart';
import 'call_screen.dart';

class RootRouter extends StatefulWidget {
  const RootRouter({super.key});
  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  static const int _CHANNEL_COOLDOWN_MS = 1 * 1000; // 1 seconds

  // ---------- tiny debug helper ----------
  void _D(String msg, [Map<String, Object?> extra = const {}]) {
    final ts = DateTime.now().toIso8601String();
    if (extra.isEmpty) {
      debugPrint("[$ts] [RootRouter] $msg");
    } else {
      debugPrint("[$ts] [RootRouter] $msg -> ${const JsonEncoder.withIndent('  ').convert(extra)}");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    _D("route() called, mounted=$mounted");

    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      _D("SharedPreferences.getInstance FAILED, navigating Splash", {"error": e.toString()});
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SplashScreen()));
      return;
    }

    // Read pending join (and log)
    final raw = prefs.getString('pending_join') ?? '';
    _D("Read pending_join", {"raw": raw});

    // Always clear pending right away to avoid re-open loops
    try {
      final removedJoin = await prefs.remove('pending_join');
      final removedAt   = await prefs.remove('pending_join_at'); // optional: also clear any attached timestamp
      _D("Cleared pending keys", {"pending_join": removedJoin, "pending_join_at": removedAt});
    } catch (e) {
      _D("Error clearing pending keys (non-fatal)", {"error": e.toString()});
    }

    // Parse JSON
    Map<String, dynamic>? extra;
    if (raw.isNotEmpty) {
      try {
        extra = Map<String, dynamic>.from(jsonDecode(raw));
        _D("Parsed pending_join JSON", {"extra": extra});
      } catch (e) {
        extra = null;
        _D("JSON parse failed; will fallback to Splash", {"error": e.toString(), "raw": raw});
      }
    } else {
      _D("No pending_join payload present");
    }

    // If we have a valid payload, apply the 60s "same channel" rule
    if (extra != null) {
      final channelId = (extra['channel'] ?? extra['callId'] ?? '').toString();
      final callerId  = (extra['callerId'] ?? '').toString();
      final receiverId= (extra['receiverId'] ?? '').toString();
      final peerName  = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();

      _D("Extracted IDs", {
        "channelId": channelId,
        "callerId": callerId,
        "receiverId": receiverId,
        "peerName": peerName,
      });

      // Require all ids
      if (channelId.isNotEmpty && callerId.isNotEmpty && receiverId.isNotEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Previously seen?
        final lastCh = prefs.getString('last_pjoin_channel') ?? '';
        final lastAt = prefs.getInt('last_pjoin_seen_at') ?? 0;

        final sameChannel = lastCh.isNotEmpty && lastCh == channelId;
        final olderThan60s = lastAt > 0 && (now - lastAt) > _CHANNEL_COOLDOWN_MS;

        _D("Cooldown check", {
          "last_pjoin_channel": lastCh,
          "last_pjoin_seen_at": lastAt,
          "now": now,
          "sameChannel": sameChannel,
          "olderThan60s": olderThan60s,
          "deltaMs": lastAt == 0 ? null : now - lastAt,
        });

        // Rule:
        // - If SAME channel and it's older than 60s -> go to Splash (do NOT open CallScreen)
        // - Else (new channel OR same within 60s) -> open CallScreen and update last seen
        if (sameChannel && olderThan60s) {
          _D("Decision: BLOCK reopen (same channel after 60s). Navigating Splash.", {
            "channelId": channelId
          });
          if (!mounted) {
            _D("Not mounted; aborting navigation to Splash");
            return;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
          return;
        } else {
          _D("Decision: ALLOW (new channel OR same within 60s). Navigating CallScreen.", {
            "channelId": channelId
          });

          // Update last seen markers
          try {
            await prefs.setString('last_pjoin_channel', channelId);
            await prefs.setInt('last_pjoin_seen_at', now);
            _D("Updated last_pjoin_* markers", {
              "last_pjoin_channel": channelId,
              "last_pjoin_seen_at": now,
            });
          } catch (e) {
            _D("Failed to set last_pjoin_* markers (non-fatal)", {"error": e.toString()});
          }

          if (!mounted) {
            _D("Not mounted; aborting navigation to CallScreen");
            return;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CallScreen(
                channelId: channelId,
                callerId: callerId,
                receiverId: receiverId,
                peerName: peerName,
                isCaller: false,
              ),
            ),
          );
          return;
        }
      } else {
        _D("Missing required IDs; fallback to Splash", {
          "channelId": channelId,
          "callerId": callerId,
          "receiverId": receiverId
        });
      }
    } else {
      _D("No valid extra payload; going to Splash");
    }

    // Fallback → splash
    if (!mounted) {
      _D("Not mounted; aborting fallback navigation");
      return;
    }
    _D("Navigating Splash (fallback)");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}



//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../screens/splash_screen.dart';
// import 'call_screen.dart';
//
// class RootRouter extends StatefulWidget {
//   const RootRouter({super.key});
//   @override
//   State<RootRouter> createState() => _RootRouterState();
// }
//
// class _RootRouterState extends State<RootRouter> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _route());
//   }
//
//   Future<void> _route() async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString('pending_join') ?? '';
//     debugPrint("🔎 RootRouter pending_join = $raw");
//
//     if (raw.isNotEmpty) {
//       Map<String, dynamic>? extra;
//       try {
//         extra = Map<String, dynamic>.from(jsonDecode(raw));
//       } catch (_) {
//         extra = null;
//       }
//
//       // ✅ always clear stale value
//       await prefs.remove('pending_join');
//
//       if (extra != null) {
//         final channelId = (extra['channel'] ?? extra['callId'] ?? '').toString();
//         final callerId  = (extra['callerId'] ?? '').toString();
//         final receiverId= (extra['receiverId'] ?? '').toString();
//         final peerName  = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();
//
//         // ✅ check if IDs are valid before opening CallScreen
//         if (channelId.isNotEmpty && callerId.isNotEmpty && receiverId.isNotEmpty) {
//           if (!mounted) return;
//           Navigator.pushReplacement(context, MaterialPageRoute(
//             builder: (_) => CallScreen(
//               channelId: channelId,
//               callerId: callerId,
//               receiverId: receiverId,
//               peerName: peerName,
//               isCaller: false,
//             ),
//           ));
//           return;
//         }
//       }
//     }
//
//     // default → splash
//     if (!mounted) return;
//     Navigator.pushReplacement(context,
//       MaterialPageRoute(builder: (_) => const SplashScreen()),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) => const SizedBox.shrink();
// }
