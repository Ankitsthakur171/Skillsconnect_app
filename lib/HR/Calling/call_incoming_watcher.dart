// // // lib/HR/Calling/call_incoming_watcher.dart
// // import 'dart:async';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:skillsconnect/HR/Calling/call_kit.dart'; // CallkitService
// //
// // /// Listens to Firestore doc: calls/{userId}
// // /// Jaise hi "isCalling": true && "status": "calling" dikhe, CallKit popup show.
// // class CallIncomingWatcher {
// //   static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
// //   static String? _lastShownCallId;
// //
// //   static void start(String userId) {
// //     stop(); // ensure single subscription
// //     _sub = FirebaseFirestore.instance
// //         .collection('calls')
// //         .doc(userId)
// //         .snapshots()
// //         .listen((snap) async {
// //       if (!snap.exists) return;
// //       final data = snap.data() ?? {};
// //
// //       final bool isCalling = data['isCalling'] == true;
// //       final String status = (data['status'] ?? '').toString();
// //       final String channelId = (data['channelId'] ??
// //           data['channelid'] ??
// //           data['channel'] ??
// //           '')
// //           .toString();
// //
// //       print('[Watcher] snapshot exists=${snap.exists}');
// //       print('[Watcher] data=$data');
// //
// //       print('[Watcher] isCalling=$isCalling status=$status channelId=$channelId');
// //
// //       if (isCalling && status == 'calling' && channelId.isNotEmpty) {
// //         print('[Watcher] SHOW POPUP for callId=$channelId');
// //         // de-dupe: same callId par baar-baar popup mat dikhao
// //         if (_lastShownCallId == channelId) return;
// //         _lastShownCallId = channelId;
// //
// //         // Merge Firestore fields → CallKit payload
// //         // NOTE: callerId/receiverId pass kar do taaki Accept par UI open ho sake
// //         await CallkitService.showIncomingCall({
// //           'type': 'incoming_call',
// //           'callId': channelId,
// //           'channel': channelId,
// //           'channelid': channelId,
// //           'callerName': (data['callerName'] ?? 'Caller').toString(),
// //           'callerId': (data['callerId'] ?? '').toString(),
// //           'receiverId': (data['receiverId'] ?? '').toString(),
// //           // 'isVideo': data['isVideo'] == true,
// //         });
// //       }
// //
// //       // Agar call end ho gayi ho to reset de-dupe key
// //       if (!isCalling || status == 'ended') {
// //         _lastShownCallId = null;
// //       }
// //     });
// //   }
// //
// //   static void stop() {
// //     _sub?.cancel();
// //     _sub = null;
// //     _lastShownCallId = null;
// //   }
// // }
//
//
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:skillsconnect/HR/Calling/call_kit.dart'; // CallkitService
//
// class CallIncomingWatcher {
//   static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
//   static String? _lastShownCallId;
//
//   static void start(String userId) {
//     stop();
//     final ref = FirebaseFirestore.instance.collection('calls').doc(userId);
//
//     _sub = ref.snapshots().listen((snap) async {
//       if (!snap.exists) return;
//       final data = snap.data() ?? {};
//
//       final bool isCalling = data['isCalling'] == true;
//       final String status = (data['status'] ?? '').toString();
//       final String channelId = (data['channelId'] ?? data['channelid'] ?? data['channel'] ?? '').toString();
//
//       final String docId = snap.id; // 👈 current doc id (ye hi userId hai jise start() me diya)
//       final String receiverId = (data['receiverId'] ?? '').toString();
//
//       // 👇 NEW: sirf callee ka doc popup trigger kare
//       if (docId != receiverId) {
//         // ye outgoing (caller) side ka doc hoga → ignore
//         return;
//       }
//
//       if (isCalling && status == 'calling' && channelId.isNotEmpty) {
//         if (_lastShownCallId == channelId) return; // de-dupe
//         _lastShownCallId = channelId;
//
//         await CallkitService.showIncomingCall({
//           'type': 'incoming_call',
//           'callId': channelId,
//           'channel': channelId,
//           'channelid': channelId,
//           'callerName': (data['callerName'] ?? 'Caller').toString(),
//           'callerId': (data['callerId'] ?? '').toString(),
//           'receiverId': receiverId,
//         });
//       }
//
//       if (!isCalling || status == 'ended') {
//         _lastShownCallId = null;
//       }
//     });
//   }
//
//   static void stop() { _sub?.cancel(); _sub = null; _lastShownCallId = null; }
// }


import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'call_kit.dart';

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'call_kit.dart';  // ❌ popup ke liye ab is file me zarurat nahi

class CallIncomingWatcher {
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  static String? _lastSeenChannel; // sirf de-dupe ke liye

  static void start(String userId) {
    stop();
    final ref = FirebaseFirestore.instance.collection('calls').doc(userId);

    _sub = ref.snapshots().listen((snap) async {
      if (!snap.exists) return;
      final data = snap.data() ?? {};

      final bool isCalling = data['isCalling'] == true;
      final String status   = (data['status'] ?? '').toString(); // calling/accepted/ended...
      final String channel  = (data['channelId'] ?? data['channelid'] ?? data['channel'] ?? '').toString();
      final String receiver = (data['receiverId'] ?? '').toString();

      // 👉 Sirf callee doc par react karo
      if (snap.id != receiver) return;

      // 🧹 Old ringing de-dupe marker
      if (!isCalling || status == 'ended' || status == 'rejected') {
        _lastSeenChannel = null;
        return;
      }

      // 🔔 RINGING state par kuch show NAHIN karna (popup FCM dikhayega)
      if (status == 'calling' && channel.isNotEmpty) {
        // sirf de-dupe/diagnostic
        if (_lastSeenChannel != channel) {
          _lastSeenChannel = channel;
          // print('[Watcher] ringing seen for $channel (popup via FCM only)');
        }
      }

      // ✅ accepted/ended par UI navigation aapka `CallListener` handle karega.
      // yahan aur kuch karne ki zarurat nahi.
    }, onError: (_) {});
  }

  static void stop() {
    try { _sub?.cancel(); } catch (_) {}
    _sub = null;
    _lastSeenChannel = null;
  }
}


// class CallIncomingWatcher {
//   static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
//   static String? _lastShown;
//
//   static void start(String userId) {
//     stop();
//     final ref = FirebaseFirestore.instance.collection('calls').doc(userId);
//
//     _sub = ref.snapshots().listen((snap) async {
//       if (!snap.exists) return;
//       final data = snap.data() ?? {};
//
//       final bool isCalling = data['isCalling'] == true;
//       final String status = (data['status'] ?? '').toString();
//       final String channelId = (data['channelId'] ?? data['channelid'] ?? data['channel'] ?? '').toString();
//       final String receiverId = (data['receiverId'] ?? '').toString();
//
//       // 👉 Only callee’s doc should trigger popup
//       if (snap.id != receiverId) return;
//
//       // ❄️ Freshness gate (avoid old popups after login)
//       DateTime? ts;
//       try {
//         final rawTs = data['timestamp'];
//         if (rawTs is Timestamp) ts = rawTs.toDate();
//       } catch (_) {}
//       final bool isFresh = ts == null ? true : DateTime.now().difference(ts).inSeconds <= 45;
//
//       if (isCalling && status == 'calling' && channelId.isNotEmpty && isFresh) {
//         if (_lastShown == channelId) return; // de-dupe
//         _lastShown = channelId;
//
//         await CallkitService.showIncomingCall({
//           'type': 'incoming_call',
//           'callId': channelId,
//           'channel': channelId,
//           'channelid': channelId,
//           'callerName': (data['callerName'] ?? 'Caller').toString(),
//           'callerId': (data['callerId'] ?? '').toString(),
//           'receiverId': receiverId,
//         });
//       }
//
//       if (!isCalling || status == 'ended') _lastShown = null;
//     }, onError: (_) {});
//   }
//
//   static void stop() {
//     _sub?.cancel();
//     _sub = null;
//     _lastShown = null;
//   }
// }
