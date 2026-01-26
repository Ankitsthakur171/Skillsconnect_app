// // import 'dart:convert';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:uuid/uuid.dart';
// // import 'call_screen.dart';
// //
// // class CallService {
// //   static final _db = FirebaseFirestore.instance;
// //
// //   static Future<void> startCall({
// //     required BuildContext context,
// //     required String callerId,
// //     required String callerName,
// //     required String receiverId,
// //     required String receiverName,
// //   }) async {
// //     // 👇 हर call के लिए unique channelId
// //     // final channelId = const Uuid().v4();
// //     final channelId = 'great';
// //
// //     final callData = {
// //       "channelId": channelId,
// //       "callerId": callerId,
// //       "callerName": callerName,
// //       "receiverId": receiverId,
// //       "receiverName": receiverName,
// //       "status": "calling",
// //       "isCalling": true,
// //       "timestamp": FieldValue.serverTimestamp(),
// //     };
// //
// //     // Firestore → दोनों users के लिए store karo
// //     await _db.collection("calls").doc(receiverId).set(callData);
// //     await _db.collection("calls").doc(callerId).set(callData);
// //
// //     // Server push (popup) → आपकी API
// //     final prefs = await SharedPreferences.getInstance();
// //     final token = prefs.getString('auth_token') ?? '';
// //     final res = await http.post(
// //       Uri.parse("https://api.skillsconnect.in/dcxqyqzqpdydfk/api/common/make-call-notification"),
// //       headers: {
// //         "Content-Type": "application/json",
// //         if (token.isNotEmpty) "Authorization": "Bearer $token",
// //       },
// //       body: json.encode({
// //         "user_id": receiverId,
// //         "channelid": channelId,
// //         "title": "Incoming Call",
// //         "description": "Call from $callerName",
// //         "callerName": callerName,
// //       }),
// //     );
// //
// //     print("📞 Call Notification API Triggered");
// //     print('📞 Response : ${res.body}');
// //
// //     // Caller side → call UI open
// //     if (context.mounted) {
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) => CallScreen(
// //             channelId: channelId,
// //             callerId: callerId,
// //             receiverId: receiverId,
// //             peerName: receiverName,
// //             isCaller: true,
// //           ),
// //         ),
// //       );
// //     }
// //   }
// //
// //   static Future<void> endCall({
// //     required String callerId,
// //     required String receiverId,
// //   }) async {
// //     await _db.collection("calls").doc(callerId).update({
// //       "status": "ended",
// //       "isCalling": false,
// //     }).catchError((_) {});
// //     await _db.collection("calls").doc(receiverId).update({
// //       "status": "ended",
// //       "isCalling": false,
// //     }).catchError((_) {});
// //   }
// // }
// //
//
//
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';
//
// import '../../app_globals.dart'; // for navigatorKey
// import 'call_screen.dart';
//
// class CallService {
//   static final _db = FirebaseFirestore.instance;
//
//   /// Caller side: create Firestore "calling" state + hit make-call API + open caller UI
//   static Future<void> startCall({
//     required BuildContext context,
//     required String callerId,
//     required String callerName,
//     required String receiverId,
//     required String receiverName,
//   }) async {
//     // 1) UNIQUE channelId (do NOT reuse like "great")
//     // final String channelId = const Uuid().v4();
//     //
//     // final callData = {
//     //   "channelId": channelId,
//     //   "callerId": callerId,
//     //   "callerName": (callerName.isEmpty ? "Caller" : callerName),
//     //   "receiverId": receiverId,
//     //   "receiverName": receiverName,
//     //   "status": "calling",    // 👈 must be calling
//     //   "isCalling": true,      // 👈 must be true
//     //   "timestamp": FieldValue.serverTimestamp(),
//     // };
//     //
//     // // (optional but recommended) stale docs ko hata do
//     // try { await _db.collection("calls").doc(receiverId).delete(); } catch (_) {}
//     // try { await _db.collection("calls").doc(callerId).delete(); } catch (_) {}
//
//
//     final String channelId = const Uuid().v4();
//
//     final base = {
//       "channelId": channelId,
//       "callerId": callerId,
//       "callerName": callerName.isEmpty ? "Caller" : callerName,
//       "receiverId": receiverId,
//       "receiverName": receiverName,
//       "timestamp": FieldValue.serverTimestamp(),
//     };
//
// // callee doc -> triggers popup
//     final calleeDoc = {
//       ...base,
//       "status": "calling",
//       "isCalling": true,
//     };
//
// // caller doc -> outgoing, no popup
//     final callerDoc = {
//       ...base,
//       "status": "outgoing",
//       "isCalling": false,
//     };
//
// // (optional) stale cleanup
//     await _db.collection("calls").doc(receiverId).delete().catchError((_) {});
//     await _db.collection("calls").doc(callerId).delete().catchError((_) {});
//
// // write
//     await _db.collection("calls").doc(receiverId).set(calleeDoc);
//     await _db.collection("calls").doc(callerId).set(callerDoc);
//
//     // // 2) Firestore write for BOTH users
//     // print('[Caller] write calls/$receiverId => $callData');
//     // await _db.collection("calls").doc(receiverId).set(callData);
//     // print('[Caller] write calls/$callerId  => $callData');
//     // await _db.collection("calls").doc(callerId).set(callData);
//
//     // 3) Server push (simple notification)—API body exactly as you wanted (no extra `data`)
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final auth = prefs.getString('auth_token') ?? '';
//
//       final uri = Uri.parse(
//         // NOTE: ensure this path matches your working one. Earlier you used /api/common/..., later /mobile/common/...
//         "https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/common/make-call-notification",
//       );
//
//       final payload = {
//         "user_id": receiverId,
//         "channelid": channelId,
//         "title": "Incoming Call",
//         "description": "Call from $callerName",
//         "callerName": callerName,
//       };
//
//       print('[Caller] hitting make-call-notification => $payload');
//       final res = await http.post(
//         uri,
//         headers: {
//           "Content-Type": "application/json",
//           if (auth.isNotEmpty) "Authorization": "Bearer $auth",
//         },
//         body: json.encode(payload),
//       );
//       print('[Caller] API status=${res.statusCode} body=${res.body}');
//     } catch (e) {
//       print('[Caller] API error: $e');
//     }
//
//     // 4) Caller UI open
//     if (context.mounted) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => CallScreen(
//             channelId: channelId,
//             callerId: callerId,
//             receiverId: receiverId,
//             peerName: receiverName,
//             isCaller: true,
//           ),
//         ),
//       );
//     }
//   }
//
//   /// Callee: Accept par call join + UI open (FirebaseApi se call hota)
//   static Future<void> joinCall(Map<String, dynamic> extra) async {
//     final String channelId =
//     (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
//     if (channelId.isEmpty) return;
//
//     final String callerId   = (extra['callerId'] ?? '').toString();
//     final String receiverId = (extra['receiverId'] ?? '').toString();
//     final String peerName   =
//     (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();
//
//     // TODO: yahin aap apna RTC SDK join karo (Agora/Jitsi), e.g.:
//     // await AgoraProvider.instance.join(channelId, token: extra['agoraToken']);
//
//     final ctx = navigatorKey.currentContext;
//     if (ctx != null && ctx.mounted) {
//       Navigator.push(
//         ctx,
//         MaterialPageRoute(
//           builder: (_) => CallScreen(
//             channelId: channelId,
//             callerId: callerId,
//             receiverId: receiverId,
//             peerName: peerName,
//             isCaller: false,
//           ),
//         ),
//       );
//     }
//   }
//
//   /// End/Decline/Timeout → calling state band karo
//   static Future<void> endCall({
//     required String callerId,
//     required String receiverId,
//   }) async {
//     print('[CallService] endCall() caller=$callerId receiver=$receiverId');
//
//     await _db.collection("calls").doc(callerId).update({
//       "status": "ended",
//       "isCalling": false,
//     }).catchError((e) => print('endCall err caller: $e'));
//
//     await _db.collection("calls").doc(receiverId).update({
//       "status": "ended",
//       "isCalling": false,
//     }).catchError((e) => print('endCall err receiver: $e'));
//   }
// }






//
//
//
//
//
//
//
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';
// import '../../app_globals.dart';
// import 'call_screen.dart';
//
// class CallService {
//   static final _db = FirebaseFirestore.instance;
//
//   static Future<void> startCall({
//     required BuildContext context,
//     required String callerId,
//     required String callerName,
//     required String receiverId,
//     required String receiverName,
//   }) async {
//     // final String channelId = const Uuid().v4();
//     final String channelId = 'great';
//
//     final base = {
//       "channelId": channelId,
//       "callerId": callerId,
//       "callerName": callerName.isEmpty ? "Caller" : callerName,
//       "receiverId": receiverId,
//       "receiverName": receiverName,
//       "timestamp": FieldValue.serverTimestamp(),
//     };
//
//     final calleeDoc = { ...base, "status": "calling", "isCalling": true };
//     final callerDoc = { ...base, "status": "outgoing", "isCalling": false };
//
//     await _db.collection("calls").doc(receiverId).delete().catchError((_) {});
//     await _db.collection("calls").doc(callerId).delete().catchError((_) {});
//
//     await _db.collection("calls").doc(receiverId).set(calleeDoc);
//     await _db.collection("calls").doc(callerId).set(callerDoc);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final auth = prefs.getString('auth_token') ?? '';
//       final uri = Uri.parse("https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/common/make-call-notification");
//       final payload = {
//         "user_id": receiverId,
//         "channelid": channelId,
//         "title": "Incoming Call",
//         "description": "Call from $callerName",
//         "callerName": callerName,
//       };
//       await http.post(uri,
//         headers: {"Content-Type": "application/json", if (auth.isNotEmpty) "Authorization": "Bearer $auth"},
//         body: json.encode(payload),
//       );
//     } catch (_) {}
//
//     if (context.mounted) {
//       Navigator.push(context, MaterialPageRoute(
//         builder: (_) => CallScreen(
//           channelId: channelId,
//           callerId: callerId,
//           receiverId: receiverId,
//           peerName: receiverName,
//           isCaller: true,
//         ),
//       ));
//     }
//   }
//
//   static Future<void> joinCall(Map<String, dynamic> extra) async {
//     final String channelId =
//     (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
//     if (channelId.isEmpty) return;
//
//     final String callerId   = (extra['callerId'] ?? '').toString();
//     final String receiverId = (extra['receiverId'] ?? '').toString();
//     final String peerName   = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();
//
//     final ctx = navigatorKey.currentContext;
//     if (ctx != null && ctx.mounted) {
//       Navigator.push(ctx, MaterialPageRoute(
//         builder: (_) => CallScreen(
//           channelId: channelId,
//           callerId: callerId,
//           receiverId: receiverId,
//           peerName: peerName,
//           isCaller: false,
//         ),
//       ));
//     }
//   }
//
//   static Future<void> markAccepted({
//     required String callerId,
//     required String receiverId,
//   }) async {
//     await _db.collection("calls").doc(callerId).update({
//       "status": "accepted", "isCalling": false,
//     }).catchError((_) {});
//     await _db.collection("calls").doc(receiverId).update({
//       "status": "accepted", "isCalling": false,
//     }).catchError((_) {});
//   }
//
//   static Future<void> endCall({
//     required String callerId,
//     required String receiverId,
//   }) async {
//     await _db.collection("calls").doc(callerId).update({
//       "status": "ended", "isCalling": false,
//     }).catchError((_) {});
//     await _db.collection("calls").doc(receiverId).update({
//       "status": "ended", "isCalling": false,
//     }).catchError((_)import 'Firebase_store.dart';

//   }
// }

// call_service.dart




import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Constant/constants.dart';
import '../../app_globals.dart';
import 'Firebase_store.dart';
import 'call_screen.dart';

class CallService {
  CallService._();


  // 👇 add these guards
  static bool _opening = false;
  static String? _openingChannel;

  static bool _beginOpen(String ch) {
    if (_opening && _openingChannel == ch) {
      debugPrint("⛔ Already opening CallScreen for $ch — ignored");
      return false;
    }
    _opening = true;
    _openingChannel = ch;
    return true;
  }

  static void _endOpenSoon() {
    // थोड़ा delay ताकि back-to-back events से duplicate ना बने
    Future.delayed(const Duration(seconds: 2), () {
      _opening = false;
      _openingChannel = null;
    });
  }

  /// Wrapper watcher: self + peer + channel → close callback
  static StreamSubscription attachCloseWatcher({
    required String selfId,
    required String peerId,
    required String channelId,
    required VoidCallback onRemoteEnd,
  }) {
    return CallStore.instance.bindCloseWatcher(
      selfId: selfId,
      peerId: peerId,
      channelId: channelId,
      onRemoteEnd: onRemoteEnd,
    );
  }

  /// helper: open phone dialer (for Exotel case)
  static Future<void> _launchDialer(String phoneNumber) async {
    final Uri uri = Uri(scheme: "tel", path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw "Could not launch dialer for $phoneNumber";
    }
  }

  static Future<void> startCall({
    required BuildContext context,
    required String callerId,
    required String callerName,
    required String receiverId,
    required String receiverName,
  }) async {

    final String channelId = const Uuid().v4();
    // final String channelId = "${callerId}_${receiverId}";

    if (!_beginOpen(channelId)) return; // ✅ duplicate push stop

    // Single source of truth: create call docs
    await CallStore.instance.createCall(
      channelId: channelId,
      callerId: callerId,
      callerName: callerName,
      receiverId: receiverId,
      receiverName: receiverName,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final auth = prefs.getString('auth_token') ?? '';

      // Provider fetch
      final initUri = Uri.parse("${BASE_URL}calls/initialize");
      final initPayload = { "user_id": receiverId.toString() };
      final initRes = await http.post(
        initUri,
        headers: {
          "Content-Type": "application/json",
          if (auth.isNotEmpty) "Authorization": "Bearer $auth",
        },
        body: json.encode(initPayload),
      );
      final initBody  = json.decode(initRes.body);
      final provider  = initBody["provider"]?.toString() ?? "agora";

      // Send incoming notification
      final uri = Uri.parse("${BASE_URL}common/make-call-notification");
      final payload = {
        "user_id": receiverId.toString(),
        "channelid": channelId,
        "title": "Incoming Call",
        "description": "Call from $callerName",
        "callerName": callerName,
        "provider": provider,
      };
      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          if (auth.isNotEmpty) "Authorization": "Bearer $auth"
        },
        body: json.encode(payload),
      );
     print(' Make Call Api Response: $payload');
      // Exotel path → dialer
      if (provider.toLowerCase() == "exotel") {
        try {
          final body = json.decode(res.body);
          final proxyNumber = body["PorxyNumber"]?.toString();
          if (proxyNumber != null && proxyNumber.isNotEmpty) {
            await _launchDialer(proxyNumber);
          }
        } catch (e) {
          debugPrint("Exotel parse error: $e");
        }
        return;
      }

      // Agora/others → open Call UI
      if (context.mounted) {
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => CallScreen(
              channelId: channelId,
              callerId: callerId,
              receiverId: receiverId,
              peerName: receiverName,
              isCaller: true,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Call API error: $e");
    }finally {
      _endOpenSoon(); // ✅ release guard
    }
  }







  // static Future<BuildContext?> _awaitContext({int ms = 2000}) async {
  //   final sw = Stopwatch()..start();
  //   while (sw.elapsedMilliseconds < ms) {
  //     final ctx = navigatorKey.currentContext;
  //     if (ctx != null && ctx.mounted) return ctx;
  //     await Future.delayed(const Duration(milliseconds: 60));
  //   }
  //   return navigatorKey.currentContext;
  // }

  // CallService.dart

// (helper) root context ka wait
  static Future<BuildContext?> _awaitContext({int ms = 2000}) async {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < ms) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) return ctx;
      await Future.delayed(const Duration(milliseconds: 60));
    }
    return navigatorKey.currentContext;
  }

// current active CallScreen ko track (per channel)
  static String? _activeChannel;

  // ✅ expose active state so listener double push na kare
  static bool isActiveFor(String ch) => _activeChannel == ch;

  // ✅ “abhi-abhi CallKit se accept hua” flag (5s window)
  static String? _justAccepted;
  static void markExternallyAccepted(String ch) {
    _justAccepted = ch;
    Future.delayed(const Duration(seconds: 5), () {
      if (_justAccepted == ch) _justAccepted = null;
    });
  }
  static bool wasJustAccepted(String ch) => _justAccepted == ch;
// ⚠️ UPDATED: optional ctxOverride add kiya
  static Future<void> joinCall(
      Map<String, dynamic> extra, {
        BuildContext? ctxOverride,
      }) async {
    final channelId =
    (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
    if (channelId.isEmpty) return;

    final callerId   = (extra['callerId'] ?? '').toString();
    final receiverId = (extra['receiverId'] ?? '').toString();
    final peerName   = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();

    if (_activeChannel == channelId) {
      debugPrint("🚫 CallUI already open for $channelId");
      return;
    }

    // yahan se context lo (pehle override, warna root)
    final ctx = ctxOverride ?? await _awaitContext(ms: 2500);
    if (ctx == null || !ctx.mounted) {
      debugPrint("❌ joinCall: No Navigator available to push CallScreen!");
      return;
    }

    _activeChannel = channelId;
    await Navigator.of(ctx, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelId: channelId,
          callerId: callerId,
          receiverId: receiverId,
          peerName: peerName,
          isCaller: false,
        ),
      ),
    ).whenComplete(() {
      _activeChannel = null;
    });
  }

// CallService.joinCall me signature badhao:
//   static Future<void> joinCall(Map<String, dynamic> extra, {BuildContext? ctxOverride}) async {
//     final String channelId = (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString().trim();
//     if (channelId.isEmpty) {
//       debugPrint("🚫 joinCall: channelId empty -> extra=$extra");
//       return;
//     }
//
//     if (!_beginOpen(channelId)) {
//       debugPrint("⛔ joinCall blocked by guard for $channelId");
//       return;
//     }
//
//     final String callerId   = (extra['callerId'] ?? '').toString();
//     final String receiverId = (extra['receiverId'] ?? '').toString();
//     final String peerName   = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();
//
//     try {
//       // 1) Prefer the context you passed
//       BuildContext? ctx = ctxOverride;
//       if (ctx != null && ctx.mounted) {
//         debugPrint("✅ using ctxOverride to push CallScreen");
//         await Navigator.of(ctx, rootNavigator: true).push(
//           MaterialPageRoute(
//             builder: (_) => CallScreen(
//               channelId: channelId,
//               callerId: callerId,
//               receiverId: receiverId,
//               peerName: peerName,
//               isCaller: false,
//             ),
//           ),
//         );
//         return;
//       }
//
//       // 2) Else try global context (app foreground)
//       ctx = navigatorKey.currentContext;
//       if (ctx == null || !ctx.mounted) {
//         debugPrint("⌛ ctx null — waiting for context...");
//         // chaho to yahan aap apna _awaitContext() use kar sakte ho
//       }
//       if (ctx != null && ctx.mounted) {
//         debugPrint("✅ got context, pushing via global context");
//         await Navigator.of(ctx, rootNavigator: true).push(
//           MaterialPageRoute(
//             builder: (_) => CallScreen(
//               channelId: channelId,
//               callerId: callerId,
//               receiverId: receiverId,
//               peerName: peerName,
//               isCaller: false,
//             ),
//           ),
//         );
//         return;
//       }
//
//       // 3) Last resort: navigatorKey.currentState
//       final nav = navigatorKey.currentState;
//       if (nav != null) {
//         debugPrint("✅ using navigatorKey.currentState to push CallScreen");
//         await nav.push(
//           MaterialPageRoute(
//             builder: (_) => CallScreen(
//               channelId: channelId,
//               callerId: callerId,
//               receiverId: receiverId,
//               peerName: peerName,
//               isCaller: false,
//             ),
//           ),
//         );
//       } else {
//         debugPrint("❌ joinCall: No Navigator available to push CallScreen!");
//       }
//     } catch (e, st) {
//       debugPrint("❌ joinCall push error: $e\n$st");
//     } finally {
//       _endOpenSoon();
//     }
//   }

  // static Future<void> joinCall(Map<String, dynamic> extra) async {
  //   final String channelId =
  //   (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
  //   if (channelId.isEmpty) return;
  //
  //   if (!_beginOpen(channelId)) return; // ✅ duplicate push stop
  //
  //
  //   final String callerId   = (extra['callerId'] ?? '').toString();
  //   final String receiverId = (extra['receiverId'] ?? '').toString();
  //   final String peerName   = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();
  //
  //   final ctx = navigatorKey.currentContext;
  //   try {
  //     if (ctx != null && ctx.mounted) {
  //       await Navigator.of(ctx, rootNavigator: true).push(
  //         MaterialPageRoute(
  //           builder: (_) =>
  //               CallScreen(
  //                 channelId: channelId,
  //                 callerId: callerId,
  //                 receiverId: receiverId,
  //                 peerName: peerName,
  //                 isCaller: false,
  //               ),
  //         ),
  //       );
  //     }
  //   } finally {
  //     _endOpenSoon(); // ✅
  //   }
  // }

  static Future<void> markAccepted({
    required String callerId,
    required String receiverId,
    String? channelId,
  }) async {
    await CallStore.instance.accept(
      callerId: callerId,
      receiverId: receiverId,
      channelId: channelId,
    );
  }

  static Future<void> endCall({
    required String callerId,
    required String receiverId,
    required String selfId, // jis device se end aaya
    String? channelId,
  }) async {
    await CallStore.instance.end(
      callerId: callerId,
      receiverId: receiverId,
      selfId: selfId,
      channelId: channelId,
    );
  }
}


























// import 'dart:convert';
// import 'dart:async';                          // ✅ FIX: added for StreamSubscription
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';
// import 'package:url_launcher/url_launcher.dart';   // 👈 added
// import '../../app_globals.dart';
// import 'call_screen.dart';
//
// class CallService {
//   static final _db = FirebaseFirestore.instance;
//
//   // ✅ FIX: Mirror listeners to sync status both sides
//   static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callerSub;
//   static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _receiverSub;
//
//   // ✅ FIX: central cleanup for listeners
//   static Future<void> _cleanupBindings() async {
//     try { await _callerSub?.cancel(); } catch (_) {}
//     try { await _receiverSub?.cancel(); } catch (_) {}
//     _callerSub = null;
//     _receiverSub = null;
//   }
//
//   // ✅ FIX: bind listeners so if either side changes status, the other mirrors it
//   static void _bindMirrorStatus({
//     required String callerId,
//     required String receiverId,
//   }) {
//     // Caller doc listener
//     _callerSub?.cancel();
//     _callerSub = _db.collection("calls").doc(callerId).snapshots().listen((snap) async {
//       final data = snap.data();
//       if (data == null) return;
//       final status = (data['status'] ?? '').toString().toLowerCase();
//       final isCalling = data['isCalling'] == true;
//
//       // Mirror to receiver
//       if (status == 'ended') {
//         await _db.collection("calls").doc(receiverId).set({
//           "status": "ended",
//           "isCalling": false,
//         }, SetOptions(merge: true));
//       } else if (status == 'accepted') {
//         await _db.collection("calls").doc(receiverId).set({
//           "status": "accepted",
//           "isCalling": false,
//         }, SetOptions(merge: true));
//       } else if (status == 'calling' && isCalling == true) {
//         // no-op, ringing phase
//       }
//     });
//
//     // Receiver doc listener
//     _receiverSub?.cancel();
//     _receiverSub = _db.collection("calls").doc(receiverId).snapshots().listen((snap) async {
//       final data = snap.data();
//       if (data == null) return;
//       final status = (data['status'] ?? '').toString().toLowerCase();
//       final isCalling = data['isCalling'] == true;
//
//       // Mirror to caller
//       if (status == 'ended') {
//         await _db.collection("calls").doc(callerId).set({
//           "status": "ended",
//           "isCalling": false,
//         }, SetOptions(merge: true));
//       } else if (status == 'accepted') {
//         await _db.collection("calls").doc(callerId).set({
//           "status": "accepted",
//           "isCalling": false,
//         }, SetOptions(merge: true));
//       } else if (status == 'outgoing' && isCalling == false) {
//         // no-op, outgoing screen
//       }
//     });
//   }
//
//
//   // CallService ke andar add karo:
//   static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> attachRemoteWatcher({
//     required String myDocId,
//     required VoidCallback onRemoteEnd,
//   }) {
//     return _db.collection("calls").doc(myDocId).snapshots().listen((snap) {
//       final d = snap.data();
//       if (d == null) return;
//       final status = (d['status'] ?? '').toString().toLowerCase();
//       if (status == "ended" || status == "rejected") {
//         onRemoteEnd();
//       }
//     });
//   }
//
//   /// helper: open phone dialer
//   static Future<void> _launchDialer(String phoneNumber) async {
//     final Uri uri = Uri(scheme: "tel", path: phoneNumber);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       throw "Could not launch dialer for $phoneNumber";
//     }
//   }
//
//   static Future<void> startCall({
//     required BuildContext context,
//     required String callerId,
//     required String callerName,
//     required String receiverId,
//     required String receiverName,
//   }) async {
//     final String channelId = const Uuid().v4(); // ✅ per-call unique id// test id
//     // final String channelId = 'great'; // test id
//
//     final base = {
//       "channelId": channelId,
//       "callerId": callerId,
//       "callerName": callerName.isEmpty ? "Caller" : callerName,
//       "receiverId": receiverId,
//       "receiverName": receiverName,
//       "timestamp": FieldValue.serverTimestamp(),
//     };
//
//     final calleeDoc = { ...base, "status": "calling", "isCalling": true };
//     final callerDoc = { ...base, "status": "outgoing", "isCalling": false };
//
//     // clear any old docs
//     await _db.collection("calls").doc(receiverId).delete().catchError((_) {});
//     await _db.collection("calls").doc(callerId).delete().catchError((_) {});
//
//     await _db.collection("calls").doc(receiverId).set(calleeDoc);
//     await _db.collection("calls").doc(callerId).set(callerDoc);
//
//     // ✅ FIX: Bind mirror after creating docs (ensures either side hangup syncs both)
//     _bindMirrorStatus(callerId: callerId, receiverId: receiverId);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final auth = prefs.getString('auth_token') ?? '';
//
//       // STEP 1: provider fetch
//       final initUri = Uri.parse("https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/calls/initialize");
//       final initPayload = { "user_id": receiverId.toString() };
//
//       final initRes = await http.post(
//         initUri,
//         headers: {
//           "Content-Type": "application/json",
//           if (auth.isNotEmpty) "Authorization": "Bearer $auth"
//         },
//         body: json.encode(initPayload),
//       );
//
//       print("📡 Init response: ${initRes.body}");
//
//       final initBody = json.decode(initRes.body);
//       final provider = initBody["provider"]?.toString() ?? "agora";
//
//       print("👉 Provider detected: $provider");
//
//       // STEP 2: make-call-notification
//       final uri = Uri.parse("https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/common/make-call-notification");
//       final payload = {
//         "user_id": receiverId.toString(),
//         "channelid": channelId,
//         "title": "Incoming Call",
//         "description": "Call from $callerName",
//         "callerName": callerName,
//         "provider": provider,
//       };
//
//       print("📡 Sending make-call-notification: $payload");
//
//       final res = await http.post(
//         uri,
//         headers: {
//           "Content-Type": "application/json",
//           if (auth.isNotEmpty) "Authorization": "Bearer $auth"
//         },
//         body: json.encode(payload),
//       );
//
//       print("📡 Make-call response: ${res.body}");
//
//       // ✅ CASE: Exotel → sirf dialer
//       if (provider.toLowerCase() == "exotel") {
//         try {
//           final body = json.decode(res.body);
//           final proxyNumber = body["PorxyNumber"]?.toString();
//
//           print("☎️ ProxyNumber: $proxyNumber");
//
//           if (proxyNumber != null && proxyNumber.isNotEmpty) {
//             await _launchDialer(proxyNumber);
//           } else {
//             print("⚠️ ProxyNumber missing in response!");
//           }
//         } catch (e) {
//           print("❌ Error parsing exotel response: $e");
//         }
//         return; // 👈 CallScreen bilkul skip
//       }
//
//       // ✅ CASE: Agora (ya others) → CallScreen open
//       if (context.mounted) {
//         Navigator.push(context, MaterialPageRoute(
//           builder: (_) => CallScreen(
//             channelId: channelId,
//             callerId: callerId,
//             receiverId: receiverId,
//             peerName: receiverName,
//             isCaller: true,
//           ),
//         ));
//       }
//     } catch (e) {
//       print("❌ Call API error: $e");
//     }
//   }
//
//   static Future<void> joinCall(Map<String, dynamic> extra) async {
//     final String channelId =
//     (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
//     if (channelId.isEmpty) return;
//
//     final String callerId   = (extra['callerId'] ?? '').toString();
//     final String receiverId = (extra['receiverId'] ?? '').toString();
//     final String peerName   = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();
//
//     // ✅ FIX: Bind mirror as soon as callee joins (so hang-up syncs both sides)
//     if (callerId.isNotEmpty && receiverId.isNotEmpty) {
//       _bindMirrorStatus(callerId: callerId, receiverId: receiverId);
//     }
//
//     final ctx = navigatorKey.currentContext;
//     if (ctx != null && ctx.mounted) {
//       Navigator.push(ctx, MaterialPageRoute(
//         builder: (_) => CallScreen(
//           channelId: channelId,
//           callerId: callerId,
//           receiverId: receiverId,
//           peerName: peerName,
//           isCaller: false,
//         ),
//       ));
//     }
//   }
//
//
//   static Future<void> markAccepted({
//     required String callerId,
//     required String receiverId,
//   }) async {
//     await _db.collection("calls").doc(callerId).update({
//       "status": "accepted", "isCalling": false,
//     }).catchError((_) {});
//     await _db.collection("calls").doc(receiverId).update({
//       "status": "accepted", "isCalling": false,
//     }).catchError((_) {});
//   }
//
//   static Future<void> endCall({
//     required String callerId,
//     required String receiverId,
//   }) async {
//     // ✅ FIX: update both docs (already doing), then cleanup listeners
//     await _db.collection("calls").doc(callerId).set({
//       "status": "ended", "isCalling": false,
//     }, SetOptions(merge: true)).catchError((_) {});
//     await _db.collection("calls").doc(receiverId).set({
//       "status": "ended", "isCalling": false,
//     }, SetOptions(merge: true)).catchError((_) {});
//
//     await _cleanupBindings(); // ✅ stop listening after end
//
//   }
// }


///exotel
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';
// import 'package:url_launcher/url_launcher.dart';   // 👈 added
// import '../../app_globals.dart';
// import 'call_screen.dart';
//
// class CallService {
//   static final _db = FirebaseFirestore.instance;
//
//   /// helper: open phone dialer
//   static Future<void> _launchDialer(String phoneNumber) async {
//     final Uri uri = Uri(scheme: "tel", path: phoneNumber);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       throw "Could not launch dialer for $phoneNumber";
//     }
//   }
//
//   static Future<void> startCall({
//     required BuildContext context,
//     required String callerId,
//     required String callerName,
//     required String receiverId,
//     required String receiverName,
//   }) async {
//     // final String channelId = const Uuid().v4();
//     final String channelId = 'great';
//
//     final base = {
//       "channelId": channelId,
//       "callerId": callerId,
//       "callerName": callerName.isEmpty ? "Caller" : callerName,
//       "receiverId": receiverId,
//       "receiverName": receiverName,
//       "timestamp": FieldValue.serverTimestamp(),
//     };
//
//     final calleeDoc = { ...base, "status": "calling", "isCalling": true };
//     final callerDoc = { ...base, "status": "outgoing", "isCalling": false };
//
//     await _db.collection("calls").doc(receiverId).delete().catchError((_) {});
//     await _db.collection("calls").doc(callerId).delete().catchError((_) {});
//
//     await _db.collection("calls").doc(receiverId).set(calleeDoc);
//     await _db.collection("calls").doc(callerId).set(callerDoc);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final auth = prefs.getString('auth_token') ?? '';
//
//       // 👇 STEP 1: Pehle provider fetch karo
//       final initUri = Uri.parse("https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/calls/initialize");
//       final initPayload = { "user_id": receiverId };   // dynamic user_id
//       final initRes = await http.post(
//         initUri,
//         headers: {
//           "Content-Type": "application/json",
//           if (auth.isNotEmpty) "Authorization": "Bearer $auth"
//         },
//         body: json.encode(initPayload),
//       );
//
//       final initBody = json.decode(initRes.body);
//       final provider = initBody["provider"]?.toString() ?? "agora";
//
//       // 👇 STEP 2: Ab make-call-notification call karo
//       final uri = Uri.parse("https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/common/make-call-notification");
//       final payload = {
//         "user_id": receiverId,
//         "channelid": channelId,
//         "title": "Incoming Call",
//         "description": "Call from $callerName",
//         "callerName": callerName,
//         "provider": provider,
//       };
//
//       print("Calling : ${payload} ");
//       final res = await http.post(
//         uri,
//         headers: {
//           "Content-Type": "application/json",
//           if (auth.isNotEmpty) "Authorization": "Bearer $auth"
//         },
//         body: json.encode(payload),
//       );
//
//       // 👇 Only if provider == exotel → open dialer with ProxyNumber
//       if (provider == "exotel") {
//         final body = json.decode(res.body);
//         final proxyNumber = body["PorxyNumber"]?.toString();
//         if (proxyNumber != null && proxyNumber.isNotEmpty) {
//           await _launchDialer(proxyNumber);
//           return; // stop here, no in-app CallScreen
//         }
//       }
//
//       // 👉 normal flow (Agora etc.)
//       if (context.mounted) {
//         Navigator.push(context, MaterialPageRoute(
//           builder: (_) => CallScreen(
//             channelId: channelId,
//             callerId: callerId,
//             receiverId: receiverId,
//             peerName: receiverName,
//             isCaller: true,
//           ),
//         ));
//       }
//     } catch (e) {
//       print("❌ Call API error: $e");
//     }
//   }
//
//   static Future<void> joinCall(Map<String, dynamic> extra) async {
//     final String channelId =
//     (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
//     if (channelId.isEmpty) return;
//
//     final String callerId   = (extra['callerId'] ?? '').toString();
//     final String receiverId = (extra['receiverId'] ?? '').toString();
//     final String peerName   = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();
//
//     final ctx = navigatorKey.currentContext;
//     if (ctx != null && ctx.mounted) {
//       Navigator.push(ctx, MaterialPageRoute(
//         builder: (_) => CallScreen(
//           channelId: channelId,
//           callerId: callerId,
//           receiverId: receiverId,
//           peerName: peerName,
//           isCaller: false,
//         ),
//       ));
//     }
//   }
//
//   static Future<void> markAccepted({
//     required String callerId,
//     required String receiverId,
//   }) async {
//     await _db.collection("calls").doc(callerId).update({
//       "status": "accepted", "isCalling": false,
//     }).catchError((_) {});
//     await _db.collection("calls").doc(receiverId).update({
//       "status": "accepted", "isCalling": false,
//     }).catchError((_) {});
//   }
//
//   static Future<void> endCall({
//     required String callerId,
//     required String receiverId,
//   }) async {
//     await _db.collection("calls").doc(callerId).update({
//       "status": "ended", "isCalling": false,
//     }).catchError((_) {});
//     await _db.collection("calls").doc(receiverId).update({
//       "status": "ended", "isCalling": false,
//     }).catchError((_) {});
//   }
// }
//



//
//
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';
// import 'package:url_launcher/url_launcher.dart';   // 👈 added
// import '../../app_globals.dart';
// import 'call_screen.dart';
//
// class CallService {
//   static final _db = FirebaseFirestore.instance;
//
//   /// helper: open phone dialer
//   static Future<void> _launchDialer(String phoneNumber) async {
//     final Uri uri = Uri(scheme: "tel", path: phoneNumber);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       throw "Could not launch dialer for $phoneNumber";
//     }
//   }
//
//   static Future<void> startCall({
//     required BuildContext context,
//     required String callerId,
//     required String callerName,
//     required String receiverId,
//     required String receiverName,
//     String provider = "agora",   // 👈 new optional param
//   }) async {
//     // final String channelId = const Uuid().v4();
//     final String channelId = 'great';
//
//     final base = {
//       "channelId": channelId,
//       "callerId": callerId,
//       "callerName": callerName.isEmpty ? "Caller" : callerName,
//       "receiverId": receiverId,
//       "receiverName": receiverName,
//       "timestamp": FieldValue.serverTimestamp(),
//     };
//
//     final calleeDoc = { ...base, "status": "calling", "isCalling": true };
//     final callerDoc = { ...base, "status": "outgoing", "isCalling": false };
//
//     await _db.collection("calls").doc(receiverId).delete().catchError((_) {});
//     await _db.collection("calls").doc(callerId).delete().catchError((_) {});
//
//     await _db.collection("calls").doc(receiverId).set(calleeDoc);
//     await _db.collection("calls").doc(callerId).set(callerDoc);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final auth = prefs.getString('auth_token') ?? '';
//       final uri = Uri.parse("https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/common/make-call-notification");
//       final payload = {
//         "user_id": receiverId,
//         "channelid": channelId,
//         "title": "Incoming Call",
//         "description": "Call from $callerName",
//         "callerName": callerName,
//         "provider": provider,   // 👈 include provider in body
//       };
//
//       final res = await http.post(
//         uri,
//         headers: {
//           "Content-Type": "application/json",
//           if (auth.isNotEmpty) "Authorization": "Bearer $auth"
//         },
//         body: json.encode(payload),
//       );
//
//       // 👇 Only if provider == exotel → open dialer with PorxyNumber
//       if (provider == "exotel") {
//         final body = json.decode(res.body);
//         final proxyNumber = body["PorxyNumber"]?.toString();
//         if (proxyNumber != null && proxyNumber.isNotEmpty) {
//           await _launchDialer(proxyNumber);
//           return; // stop here, no in-app CallScreen
//         }
//       }
//     } catch (e) {
//       print("❌ Call API error: $e");
//     }
//
//     // 👉 normal flow (Agora etc.)
//     if (context.mounted) {
//       Navigator.push(context, MaterialPageRoute(
//         builder: (_) => CallScreen(
//           channelId: channelId,
//           callerId: callerId,
//           receiverId: receiverId,
//           peerName: receiverName,
//           isCaller: true,
//         ),
//       ));
//     }
//   }
//
//   static Future<void> joinCall(Map<String, dynamic> extra) async {
//     final String channelId =
//     (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
//     if (channelId.isEmpty) return;
//
//     final String callerId   = (extra['callerId'] ?? '').toString();
//     final String receiverId = (extra['receiverId'] ?? '').toString();
//     final String peerName   = (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();
//
//     final ctx = navigatorKey.currentContext;
//     if (ctx != null && ctx.mounted) {
//       Navigator.push(ctx, MaterialPageRoute(
//         builder: (_) => CallScreen(
//           channelId: channelId,
//           callerId: callerId,
//           receiverId: receiverId,
//           peerName: peerName,
//           isCaller: false,
//         ),
//       ));
//     }
//   }
//
//   static Future<void> markAccepted({
//     required String callerId,
//     required String receiverId,
//   }) async {
//     await _db.collection("calls").doc(callerId).update({
//       "status": "accepted", "isCalling": false,
//     }).catchError((_) {});
//     await _db.collection("calls").doc(receiverId).update({
//       "status": "accepted", "isCalling": false,
//     }).catchError((_) {});
//   }
//
//   static Future<void> endCall({
//     required String callerId,
//     required String receiverId,
//   }) async {
//     await _db.collection("calls").doc(callerId).update({
//       "status": "ended", "isCalling": false,
//     }).catchError((_) {});
//     await _db.collection("calls").doc(receiverId).update({
//       "status": "ended", "isCalling": false,
//     }).catchError((_) {});
//   }
// }
