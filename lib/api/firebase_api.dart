// firebase_api.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';

import '../Constant/constants.dart';
import '../HR/Calling/Firebase_store.dart';
import '../HR/Calling/call_screen.dart';
import '../firebase_options.dart';
import '../HR/Calling/call_incoming_watcher.dart';
import '../HR/Calling/call_kit.dart';
import '../app_globals.dart';
import 'package:skillsconnect/HR/Calling/call_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillsconnect/HR/bloc/Notification/notification_bloc.dart';
import 'package:skillsconnect/HR/bloc/Notification/notification_event.dart';
import 'package:skillsconnect/HR/model/notification_model.dart';
import 'package:skillsconnect/HR/screens/notification_screen.dart';

String? globalFcmToken;

/* ------------------------- Helpers ------------------------- */


StreamSubscription? _ringChanSub;
StreamSubscription? _ringPeerSub;
// ---- Add these near other globals ----
bool _pendingJoinNavigated = false;
const int _PJOIN_TTL_MS = 60 * 1000; // 60s window


Future<void> _clearPendingJoinAll() async {
  final p = await SharedPreferences.getInstance();
  // legacy
  await p.remove('pending_join');
  await p.remove('pending_join_at');
  await p.setBool('pending_boot_pump', false);
  // flutter-namespace (Android side writes these)
  await p.remove('flutter.pending_join');
  await p.remove('flutter.pending_join_at');
  await p.setBool('flutter.pending_boot_pump', false);
  await p.remove('flutter.pending_join_callId');
}


Future<void> _tryConsumePendingJoinAndOpen() async {
  if (_pendingJoinNavigated) return;

  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('pending_join');
  if (raw == null || raw.isEmpty) return;

  Map<String, dynamic> extra;
  try {
    extra = Map<String, dynamic>.from(jsonDecode(raw));
  } catch (_) {
    return;
  }




  // 🔧 important: enrich missing fields via Firestore
  final enriched = await _enrichCallExtra(extra);

  final ch = (enriched['channel'] ?? enriched['channelid'] ?? enriched['callId'] ?? '').toString();
  final callerId = (enriched['callerId'] ?? '').toString();
  final receiverId = (enriched['receiverId'] ?? '').toString();
  if (ch.isEmpty || callerId.isEmpty || receiverId.isEmpty) {
    debugPrint('[PJOIN] missing fields after enrich -> abort: $enriched');
    await _clearPendingJoinAll(); // remove pending_join, pending_join_at, pending_boot_pump

    return;
  }

  await _forceOpenCallScreenReplacingStack({
    'channel': ch,
    'callerId': callerId,
    'receiverId': receiverId,
    'callerName': (enriched['callerName'] ?? enriched['title'] ?? 'Caller').toString(),
  });

  // ✅ consume → clear (taaki next app open par na aaye)
  _pendingJoinNavigated = true;
  await prefs.remove('pending_join');
  await prefs.remove('pending_join_at');
  await prefs.setBool('pending_boot_pump', false);
// // UI own kar raha hai
//   await prefs.setBool('call_join_active', true);
  // _pendingJoinNavigated = true;
  // await prefs.remove('pending_join');
}


Future<void> _setEndSuppression({int ms = 3000}) async {
  final p = await SharedPreferences.getInstance();
  final until = DateTime.now().millisecondsSinceEpoch + ms;
  await p.setInt('call_end_suppress_until', until);
}

Future<bool> _isEndSuppressed(String callId) async {
  // callId currently not needed; time based suppression enough
  final p = await SharedPreferences.getInstance();
  final until = p.getInt('call_end_suppress_until') ?? 0;
  return DateTime.now().millisecondsSinceEpoch < until;
}


void _pumpPendingJoin() {
  Timer.periodic(const Duration(milliseconds: 350), (t) async {
    final p    = await SharedPreferences.getInstance();
    final raw  = p.getString('pending_join') ?? '';
    final active = p.getBool('call_join_active') ?? false;
    final boot = p.getBool('pending_boot_pump') ?? false;
    final at   = p.getInt('pending_join_at') ?? 0;
    final fresh = DateTime.now().millisecondsSinceEpoch - at < _PJOIN_TTL_MS;

    // pull callId from pending JSON
    String pjCallId = '';
    if (raw.isNotEmpty) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(raw));
        pjCallId = (m['channel'] ?? m['channelid'] ?? m['callId'] ?? '').toString();
      } catch (_) {}
    }
    final consumedId = p.getString('pjoin_consumed_callId') ?? '';

    // ✅ already consumed => wipe & stop (so reopen par dobara na aaye)
    if (pjCallId.isNotEmpty && pjCallId == consumedId) {
      await p.remove('pending_join');
      await p.remove('pending_join_at');
      await p.setBool('pending_boot_pump', false);
      t.cancel();
      return;
    }

    // ❌ invalid/stale OR UI already owning => cleanup/stop
    if (raw.isEmpty || !fresh || !boot) {
      await _clearPendingJoinAll();  // ✅ clear regardless of 'active'
      t.cancel();
      return;
    }
    // ✅ fresh + boot + not active => consume (only once)
    await _tryConsumePendingJoinAndOpen();
  });
}


// void _pumpPendingJoin() {
//   Timer.periodic(const Duration(milliseconds: 350), (t) async {
//     final prefs = await SharedPreferences.getInstance();
//     final has = (prefs.getString('pending_join') ?? '').isNotEmpty;
//     final active = prefs.getBool('call_join_active') ?? false;
//
//     if (!has || active) { // CallScreen ne UI own kar liya ya pending hat gaya
//       t.cancel();
//       return;
//     }
//     await _tryConsumePendingJoinAndOpen(); // keep trying until CallScreen sticks
//   });
// }


void _cancelRingWatchers() {
  try { _ringChanSub?.cancel(); } catch (_) {}
  try { _ringPeerSub?.cancel(); } catch (_) {}
  _ringChanSub = null; _ringPeerSub = null;
}

void _attachAutoDismissForRinging(Map<String, dynamic> extra) {
  final channelId  = (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
  final receiverId = (extra['receiverId'] ?? '').toString();
  if (channelId.isEmpty || receiverId.isEmpty) return;

  _cancelRingWatchers();

  // active_calls/{channelId} => already channel scoped
  _ringChanSub = FirebaseFirestore.instance
      .collection('active_calls').doc(channelId)
      .snapshots().listen((snap) async {
    final d  = snap.data();
    if (d == null) return;
    final st = (d['status'] ?? '').toString().toLowerCase();
    final ch = (d['channelId'] ?? channelId).toString();
    if (ch != channelId) return; // safety
    if (st == 'ended' || st == 'rejected') {
      try { await FlutterCallkitIncoming.endAllCalls(); } catch (_) {}
      _cancelRingWatchers();
    }
  });

  // calls/{receiverId} => MUST match same channel, also ignore first stale "ended"
  bool _firstPeerSnap = true;

  _ringPeerSub = FirebaseFirestore.instance
      .collection('calls').doc(receiverId)
      .snapshots().listen((snap) async {
    final d = snap.data();
    if (d == null) return;

    final st = (d['status'] ?? '').toString().toLowerCase();
    final ch = (d['channelId'] ?? '').toString();

    // ignore snapshots for other/old channels
    if (ch.isEmpty || ch != channelId) return;

    // ignore the very first stale "ended/rejected" snapshot from previous call
    if (_firstPeerSnap) {
      _firstPeerSnap = false;
      if (st == 'ended' || st == 'rejected') return;
    }

    if (st == 'ended' || st == 'rejected') {
      try { await FlutterCallkitIncoming.endAllCalls(); } catch (_) {}
      _cancelRingWatchers();
    }
  });
}



Future<void> _ensureFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}
}

// --- context wait helper (firebase_api.dart, top-level) ---
Future<BuildContext?> _awaitContext({int ms = 5000}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsedMilliseconds < ms) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) return ctx;
    await Future.delayed(const Duration(milliseconds: 60));
  }
  return navigatorKey.currentContext;
}


void _L(String m, [Map? data]) {
  final now = DateTime.now().toIso8601String();
  if (data == null || data.isEmpty) {
    print("[$now] [CALL] $m");
  } else {
    print("[$now] [CALL] $m -> ${const JsonEncoder.withIndent('  ').convert(data)}");
  }
}

/// read/repair ids using local user + Firestore (receiver doc)
Future<Map<String, dynamic>> _enrichCallExtra(Map<String, dynamic> raw) async {
  final x = Map<String, dynamic>.from(raw);
  final prefs = await SharedPreferences.getInstance();

  // receiverId fill
  final localUserId = (prefs.getString('user_id') ?? '').trim();
  if ((x['receiverId'] ?? '').toString().trim().isEmpty && localUserId.isNotEmpty) {
    x['receiverId'] = localUserId;
  }

  x['callId']   ??= x['channelid'] ?? x['channel'];
  x['channel']  ??= x['callId'];
  x['channelid']??= x['callId'];

  // Firestore try
  final receiverId = (x['receiverId'] ?? '').toString().trim();
  final needs = ((x['callerId'] ?? '').toString().trim().isEmpty) ||
      ((x['channel']  ?? '').toString().trim().isEmpty);
  if (receiverId.isNotEmpty && needs) {
    try {
      final doc = await FirebaseFirestore.instance.collection('calls').doc(receiverId).get();
      final data = doc.data();
      if (data != null) {
        x['callerId']   = (x['callerId'] ?? data['callerId'] ?? '').toString();
        x['callerName'] = (x['callerName'] ?? data['callerName'] ?? x['title'] ?? 'Caller').toString();
        final ch = (x['channel'] ?? x['channelid'] ?? x['callId'] ?? data['channel'] ?? data['channelId'] ?? '').toString();
        if (ch.isNotEmpty) {
          x['channel']   = ch; x['channelid'] = ch; x['callId'] = ch;
        }
      }
    } catch (_) {}
  }

  // 🔁 LAST-RESORT: use last_callkit_extra if still missing callerId
  if ((x['callerId'] ?? '').toString().isEmpty) {
    try {
      final last = prefs.getString('last_callkit_extra');
      if (last != null && last.isNotEmpty) {
        final m = Map<String, dynamic>.from(jsonDecode(last));
        if ((x['callerId'] ?? '').toString().isEmpty && (m['callerId'] ?? '').toString().isNotEmpty) {
          x['callerId'] = m['callerId'];
        }
        if ((x['channel'] ?? '').toString().isEmpty && (m['channel'] ?? '').toString().isNotEmpty) {
          x['channel'] = m['channel']; x['callId'] = m['channel']; x['channelid'] = m['channel'];
        }
        if ((x['receiverId'] ?? '').toString().isEmpty && (m['receiverId'] ?? '').toString().isNotEmpty) {
          x['receiverId'] = m['receiverId'];
        }
        if ((x['callerName'] ?? '').toString().isEmpty && (m['callerName'] ?? '').toString().isNotEmpty) {
          x['callerName'] = m['callerName'];
        }
      }
    } catch (_) {}
  }

  return x;
}

Future<bool> _shouldShowCallkit(String ch) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastCh = prefs.getString('last_callkit_ch') ?? '';
    final lastTs = prefs.getInt('last_callkit_ts') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    // 8s ke andar same channel fir se na dikhe
    if (lastCh == ch && (now - lastTs) < 8000) return false;
    await prefs.setString('last_callkit_ch', ch);
    await prefs.setInt('last_callkit_ts', now);
    return true;
  } catch (_) {
    return true;
  }
}


// Future<void> _updateCallStatus(String callerId, String receiverId, String status) async {
//   final db = FirebaseFirestore.instance;
//   await db.collection("calls").doc(receiverId).set({
//     "status": status, "isCalling": false, "timestamp": FieldValue.serverTimestamp(),
//   }, SetOptions(merge: true));
//   await db.collection("calls").doc(callerId).set({
//     "status": status, "isCalling": false, "timestamp": FieldValue.serverTimestamp(),
//   }, SetOptions(merge: true));
// }

// open your CallScreen via your existing service
Future<void> _openCallViaService(Map<String, dynamic> extra) async {
  try { await CallService.joinCall(extra); } catch (e) { debugPrint("joinCall err: $e"); }
}

/* ---------- Accept/End guards (avoid double handling) ---------- */
final Set<String> _acceptedCalls = <String>{};
final Set<String> _endedCalls    = <String>{};

bool _markAccepted(String id) {
  if (_endedCalls.contains(id) || _acceptedCalls.contains(id)) return false;
  _acceptedCalls.add(id);
  return true;
}

bool _markEnded(String id) {
  if (_endedCalls.contains(id)) return false;
  _endedCalls.add(id);
  return true;
}

void _resetCall(String id) {
  _acceptedCalls.remove(id);
  _endedCalls.remove(id);
}

Future<void> _forceOpenCallScreenReplacingStack(Map<String, dynamic> extra) async {
  var ctx = await _awaitContext(ms: 5000);
  if (ctx == null || !ctx.mounted) {
    // second chance shortly after first frame
    await Future.delayed(const Duration(milliseconds: 200));
    ctx = await _awaitContext(ms: 3000);
  }
  if (ctx == null || !ctx.mounted) return;

  // parse fields from extra
  final String channelId  = (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
  final String callerId   = (extra['callerId'] ?? '').toString();
  final String receiverId = (extra['receiverId'] ?? '').toString();
  final String peerName   = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();

  if (channelId.isEmpty || callerId.isEmpty || receiverId.isEmpty) {
    debugPrint("❌ forceOpen: missing ids, skipping");
    return;
  }

  final nav = Navigator.of(ctx, rootNavigator: true);

  // safety: close any lingering OS popups
  try { await FlutterCallkitIncoming.endAllCalls(); } catch (_) {}

  // clear whole stack and show CallScreen on top
  nav.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => CallScreen(
        channelId: channelId,
        callerId: callerId,
        receiverId: receiverId,
        peerName: peerName,
        isCaller: false, // accept hamesha callee-side se aata
      ),
    ),
        (_) => false,
  );
}


/* --------------------- FCM background handler --------------------- */

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // auth check (optional)
  final prefs = await SharedPreferences.getInstance();
  if ((prefs.getString('auth_token') ?? '').isEmpty) return;

  await _ensureFirebase();

  final raw = Map<String, dynamic>.from(message.data);
  final isIncoming = raw['type'] == 'incoming_call'
      || raw.containsKey('channel') || raw.containsKey('channelid');

  if (!isIncoming) return;

  final enriched = await _enrichCallExtra(raw); // callerId, receiverId, channel normalize
  final callerId   = (enriched['callerId'] ?? '').toString().trim();
  final receiverId = (enriched['receiverId'] ?? '').toString().trim();
  final channel    = (enriched['channel'] ?? enriched['callId'] ?? '').toString().trim();
  if (callerId.isEmpty || receiverId.isEmpty || channel.isEmpty) return;

  if (await _shouldShowCallkit(channel)) {
    await CallkitService.showIncomingCall(enriched);
    _attachAutoDismissForRinging(enriched);
  }

}

/* ============================ FirebaseApi ============================ */

class FirebaseApi {

  FirebaseMessaging get _fm => FirebaseMessaging.instance;
  StreamSubscription<CallEvent?>? _callkitSub;

  Future<void> initNotifications(BuildContext context) async {
    try { await _fm.requestPermission(alert: true, badge: true, sound: true);


    final p = await SharedPreferences.getInstance();
    final at = p.getInt('pending_join_at') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (at != 0 && (now - at) > 60000) { // 60s TTL
      await p.remove('pending_join');
      await p.remove('pending_join_at');
      await p.setBool('call_join_active', false);
    }

    } catch (_) {}

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // token
    try {
      final token = await _fm.getToken();
      if (token != null && token.isNotEmpty) {
        globalFcmToken = token;
        await sendFcmTokenToServer(token);
      }
    } catch (_) {}

    // Firestore watcher (your own)
    await _startFirestoreIncomingWatcher();
    // 🔽 boot par pump
    _pumpPendingJoin();

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      final raw = Map<String, dynamic>.from(msg.data);
      final isIncoming = raw['type']=='incoming_call'
          || raw.containsKey('channel') || raw.containsKey('channelid');
      if (!isIncoming) {
        _handleNotification(context, msg);
        return;
      }

      final enriched = await _enrichCallExtra(raw);
      final ok = (enriched['callerId'] ?? '').toString().isNotEmpty
          && (enriched['receiverId'] ?? '').toString().isNotEmpty
          && (enriched['channel'] ?? enriched['callId'] ?? '').toString().isNotEmpty;
      if (!ok) return;

      await CallkitService.showIncomingCall(enriched);
      _attachAutoDismissForRinging(enriched);  // 👈 auto-dismiss

      Future.microtask(() async {
        await Future.delayed(const Duration(milliseconds: 300));
        debugPrint('[PJOIN] post-init check...');
        await _tryConsumePendingJoinAndOpen();
      });

    });

    // FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
    //   final raw = Map<String, dynamic>.from(msg.data);
    //   final isIncoming = raw['type']=='incoming_call'
    //       || raw.containsKey('channel') || raw.containsKey('channelid');
    //
    //   // 👉 app foreground (resumed) hai to CallKit popup bilkul mat dikhana
    //   //    normal notifications ki tarah "silent" treat karo
    //   if (isIncoming) {
    //     final appState = WidgetsBinding.instance.lifecycleState;
    //     final isForeground = appState == AppLifecycleState.resumed;
    //     if (isForeground) {
    //       // Optional: yahan kuch bhi mat karo (tumne bola "aur kuch nahi karna")
    //       return; // 🔕 suppress CallKit while app is open
    //     }
    //   }
    //
    //   if (!isIncoming) {
    //     _handleNotification(context, msg);
    //     return;
    //   }
    //
    //   // (rest same as before)
    //   final enriched = await _enrichCallExtra(raw);
    //   final ok = (enriched['callerId'] ?? '').toString().isNotEmpty
    //       && (enriched['receiverId'] ?? '').toString().isNotEmpty
    //       && (enriched['channel'] ?? enriched['callId'] ?? '').toString().isNotEmpty;
    //   if (!ok) return;
    //
    //   final ch = (enriched['channel'] ?? enriched['callId'] ?? '').toString();
    //   if (await _shouldShowCallkit(ch)) {
    //     await CallkitService.showIncomingCall(enriched);
    //     _attachAutoDismissForRinging(enriched);
    //   }
    // });


    // User tapped a push
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) async {
      final d = Map<String, dynamic>.from(msg.data);
      final incoming = d['type']=='incoming_call'
          || d.containsKey('channel') || d.containsKey('channelid');
      if (incoming) return; // CallKit/FCM ने already handle कर लिया
      _handleNotification(context, msg, openScreen: true);
    });

    // Initial push when app launches from terminated
    try {
      final initialMsg = await _fm.getInitialMessage();
      if (initialMsg != null) {
        final prefs = await SharedPreferences.getInstance();
        final auth = prefs.getString('auth_token') ?? '';
        if (auth.isNotEmpty) {
          _handleNotification(context, initialMsg, openScreen: true);
        } else {
          print("🚫 User logged out, ignore initialMessage");
        }
      }
    } catch (_) {}

    // Token refresh
    _fm.onTokenRefresh.listen((t) async {
      globalFcmToken = t;
      await sendFcmTokenToServer(t);
    });

    /* ---------------------- CallKit event handler ---------------------- */
    _callkitSub?.cancel();
    _callkitSub = FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      final ev    = event?.event;
      final body  = Map<String, dynamic>.from(event?.body ?? {});
      final extra = Map<String, dynamic>.from(body['extra'] ?? {});

      // Prefer CallKit id, else channel ids
      final String callId = (body['id']
          ?? extra['callId']
          ?? extra['channelid']
          ?? extra['channel']
          ?? DateTime.now().millisecondsSinceEpoch).toString();

      final String callerId   = (extra['callerId'] ?? '').toString();
      final String receiverId = (extra['receiverId'] ?? '').toString();

      switch (ev) {
        case Event.actionCallAccept: {
          print("📞 [DEBUG] CallKit event: actionCallAccept received");

          _cancelRingWatchers();  // popup close hone se pehle safai
          print("🧹 [DEBUG] Ring watchers cancelled");

          final enriched   = await _enrichCallExtra(extra);
          final callId     = (enriched['callId'] ?? enriched['channel'] ?? enriched['channelid'] ?? '').toString();
          final callerId   = (enriched['callerId'] ?? '').toString();
          final receiverId = (enriched['receiverId'] ?? '').toString();
          final channel    = (enriched['channel'] ?? enriched['channelid'] ?? enriched['callId'] ?? '').toString();

          print("📦 [DEBUG] Enriched Data:");
          print("       callId: $callId");
          print("       callerId: $callerId");
          print("       receiverId: $receiverId");
          print("       channel: $channel");

          _markAccepted(callId);
          print("✅ [DEBUG] Marked call accepted for callId: $callId");

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_join', jsonEncode(enriched));
          await prefs.setInt('pending_join_at', DateTime.now().millisecondsSinceEpoch); // 👈 NEW
          await prefs.setBool('call_join_active', true); // prevent other navigations from popping CallScreen


          // 2) End-suppression window (spurious Ended ko ignore karne ke liye)
          await _setEndSuppression(ms: 3000);

          print("💾 [DEBUG] pending_join saved in SharedPreferences");
          // 🔽 accept ke baad bhi pump
          _pumpPendingJoin();


          try {
            await FlutterCallkitIncoming.setCallConnected(callId);
            print("🔗 [DEBUG] setCallConnected() success for $callId");
          } catch (e) {
            print("⚠️ [DEBUG] setCallConnected() failed: $e");
          }

          try {
            await FlutterCallkitIncoming.endCall(callId);
            print("📴 [DEBUG] endCall() success for $callId");
          } catch (e) {
            print("⚠️ [DEBUG] endCall() failed: $e");
          }

          // 🔁 single source of truth
          if (callerId.isNotEmpty && receiverId.isNotEmpty) {
            print("📤 [DEBUG] Calling CallStore.instance.accept()");
            await CallStore.instance.accept(
              callerId: callerId,
              receiverId: receiverId,
              channelId: channel.isEmpty ? null : channel,
            );
            print("✅ [DEBUG] CallStore.instance.accept() done");
          } else {
            print("⚠️ [DEBUG] callerId or receiverId empty, skipping accept()");
          }

          // if (!_pendingJoinNavigated) {
          //   // try immediate nav; agar context mila to yahin open ho jayega
          //   await _forceOpenCallScreenReplacingStack(enriched);
          //   _pendingJoinNavigated = true;
          // }
          // final ctx = await _awaitContext();
          // if (ctx != null && ctx.mounted) {
          //   await _openCallViaService(enriched);
          //   _resetCall(callId);
          // }

          // ✅ always clear stack & open CallScreen (no matter which screen is open)
          await _forceOpenCallScreenReplacingStack(enriched);
// immediately purge
          await prefs.remove('pending_join');
          await prefs.remove('pending_join_at');
          await prefs.setBool('pending_boot_pump', false);
          print("🏁 [DEBUG] actionCallAccept completed successfully");
          break;
        }



      // case Event.actionCallDecline:
      // case Event.actionCallEnded:
      // case Event.actionCallTimeout:
      // _cancelRingWatchers();
      // {
      //   // agar already accept mark ho chuka, trailing end ko ignore karo
      //   if (_acceptedCalls.contains(callId)) {
      //     debugPrint("🙈 trailing end ignored after ACCEPT for $callId");
      //     break;
      //   }
      //
      //   try { await FlutterCallkitIncoming.endCall(callId); } catch (_) {}
      //
      //   // 🔁 single source of truth
      //   final channel = (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
      //   final prefs   = await SharedPreferences.getInstance();
      //   final selfId  = (prefs.getString('user_id') ?? '').trim();
      //
      //   if (callerId.isNotEmpty && receiverId.isNotEmpty) {
      //     if (ev == Event.actionCallDecline) {
      //       await CallStore.instance.reject(
      //         callerId: callerId,
      //         receiverId: receiverId,
      //         selfId: selfId.isNotEmpty ? selfId : receiverId, // jis device par event aaya
      //         channelId: channel.isEmpty ? null : channel,
      //       );
      //     } else {
      //       await CallStore.instance.end(
      //         callerId: callerId,
      //         receiverId: receiverId,
      //         selfId: selfId.isNotEmpty ? selfId : receiverId,
      //         channelId: channel.isEmpty ? null : channel,
      //       );
      //     }
      //   }
      //   break;
      // }


        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          _cancelRingWatchers();
          {
            // // agar already accept mark ho chuka, trailing end ko ignore karo
            // if (_acceptedCalls.contains(callId)) {
            //   debugPrint("🙈 trailing end ignored after ACCEPT for $callId");
            //   break;
            // }

            // Already accepted? ya suppression window me ho? => IGNORE
            if (_acceptedCalls.contains(callId) || await _isEndSuppressed(callId)) {
              debugPrint('🙈 ignore trailing ${ev?.name} due to accept/suppress window');
              break;
            }


            try { await FlutterCallkitIncoming.endCall(callId); } catch (_) {}

            // --- NEW: enrich 'extra' to ensure callerId/receiverId/channel are present ---
            final enriched = await _enrichCallExtra(extra);
            final channel = (enriched['channel'] ?? enriched['channelid'] ?? enriched['callId'] ?? '').toString();
            final finalCallerId   = (enriched['callerId'] ?? '').toString();
            final finalReceiverId = (enriched['receiverId'] ?? '').toString();

            // mark ended to avoid duplicate handling
            _markEnded(callId);

            final prefs   = await SharedPreferences.getInstance();
            final selfId  = (prefs.getString('user_id') ?? '').trim();

            if (finalCallerId.isNotEmpty && finalReceiverId.isNotEmpty) {
              if (ev == Event.actionCallDecline) {
                // callee declined -> mark request rejected for both sides
                await CallStore.instance.reject(
                  callerId: finalCallerId,
                  receiverId: finalReceiverId,
                  selfId: selfId.isNotEmpty ? selfId : finalReceiverId,
                  channelId: channel.isEmpty ? null : channel,
                );
              } else {
                // ended or timeout -> end for both sides
                await CallStore.instance.end(
                  callerId: finalCallerId,
                  receiverId: finalReceiverId,
                  selfId: selfId.isNotEmpty ? selfId : finalReceiverId,
                  channelId: channel.isEmpty ? null : channel,
                );
              }
            } else {
              // Fallback: if enrich failed to provide ids, attempt best-effort write to Firestore
              try {
                if (channel.isNotEmpty) {
                  // mark active_calls doc if you use that collection
                  await FirebaseFirestore.instance.collection('active_calls').doc(channel)
                      .set({'status': ev == Event.actionCallDecline ? 'rejected' : 'ended', 'timestamp': FieldValue.serverTimestamp()}, SetOptions(merge: true));
                }

                final p = await SharedPreferences.getInstance();
                await p.setBool('call_join_active', false);
                await p.remove('pending_join');
                await p.remove('pending_join_at');

              } catch (_) {}
            }

            break;
          }


        default:
          break;
      }
    }, onError: (_) {});
  }


  /* ---------------- server token sync ---------------- */
  Future<void> sendFcmTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null || authToken.isEmpty) return;

      await http.post(
        Uri.parse('${BASE_URL}common/update-fcm-token'),
        headers: {'Content-Type': 'application/json','Authorization': 'Bearer $authToken'},
        body: jsonEncode({'fcmToken': token}),
      );
    } catch (_) {}
  }

  /* ---------------- generic app notifications ---------------- */
  void _handleNotification(BuildContext context, RemoteMessage msg, {bool openScreen = false}) {
    try {
      final n = msg.notification;
      final d = msg.data;
      if (n == null) return;

      final model = NotificationModel(
        title: n.title ?? 'No title',
        description: n.body ?? 'No body',
        timeAgo: 'Just now',
        id: int.tryParse(d['id'] ?? '') ?? 0,
        readStatus: d['read_status'] ?? 'No',
        fromUserId: int.tryParse('${d['from_user_id'] ?? ''}') ?? 0,
        toUserId: int.tryParse('${d['to_user_id'] ?? ''}') ?? 0,
      );

      try {
        final bloc = BlocProvider.of<NotificationBloc>(context, listen: false);
        bloc.add(AddNotification(notification: model));
      } catch (_) {}

      if (openScreen) {
        try {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  void dispose() { _callkitSub?.cancel(); }

  Future<void> _startFirestoreIncomingWatcher() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      if (userId.isNotEmpty) {
        CallIncomingWatcher.start(userId);
      }
    } catch (_) {}
  }
}
