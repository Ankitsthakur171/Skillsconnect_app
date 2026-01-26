// // call_listener.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'incoming_call_screen.dart';
// import 'call_screen.dart';
//
// class CallListener extends StatefulWidget {
//   final String currentUserId;
//   final Widget child;
//   const CallListener({super.key, required this.currentUserId, required this.child});
//
//   @override
//   State<CallListener> createState() => _CallListenerState();
// }
//
// class _CallListenerState extends State<CallListener> {
//   String? _lastChannelId;
//   String? _lastStatus;
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//       stream: FirebaseFirestore.instance
//           .collection("calls")
//           .doc(widget.currentUserId)
//           .snapshots(),
//       builder: (context, snap) {
//         if (!snap.hasData || snap.data?.data() == null) return widget.child;
//         final d = snap.data!.data()!;
//         final ch = d['channelId'] as String?;
//         final status = d['status'] as String?;
//         final isCalling = d['isCalling'] == true;
//         if (ch == null) return widget.child;
//
//         final changed = (ch != _lastChannelId) || (status != _lastStatus);
//         _lastChannelId = ch;
//         _lastStatus = status;
//
//         if (!changed) return widget.child;
//
//         // Incoming ringing
//         // Incoming ringing → सिर्फ receiver के लिए
//         if (status == 'calling' && isCalling && d['receiverId'] == widget.currentUserId) {
//           return IncomingCallScreen(
//             channelId: ch,
//             callerId: d['callerId'],
//             callerName: d['callerName'],
//             currentUserId: widget.currentUserId,
//           );
//         }
//
// // Accepted → दोनों में CallScreen खुले
//         if (status == 'accepted') {
//           final isCaller = d['callerId'] == widget.currentUserId;
//           final peerName = isCaller ? d['receiverName'] : d['callerName'];
//           return CallScreen(
//             channelId: ch,
//             callerId: d['callerId'],
//             receiverId: d['receiverId'],
//             peerName: peerName,
//             isCaller: isCaller,
//           );
//         }
//
// // Rejected/Ended → सिर्फ receiver side pe band karo
//         if (status == 'rejected' || status == 'ended') {
//           if (Navigator.canPop(context)) {
//             Navigator.popUntil(context, (route) => route.isFirst);
//           }
//           return widget.child;
//         }
//
//
//
//
//         // // Rejected/Ended → दोनों को बंद करना है
//         // if (status == 'rejected' || status == 'ended') {
//         //   return widget.child;
//         // }
//
//
//
//         return widget.child;
//       },
//     );
//   }
// }














import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'call_kit.dart';
import 'incoming_call_screen.dart';
import 'call_screen.dart';

class CallListener extends StatefulWidget {
  final String currentUserId;
  final Widget child;
  const CallListener({
    super.key,
    required this.currentUserId,
    required this.child,
  });

  @override
  State<CallListener> createState() => _CallListenerState();
}

class _CallListenerState extends State<CallListener> {
  String? _lastChannelId;
  String? _lastStatus;
  bool _coldHandled = false; // cold-start accept handled guard

  late final DateTime _sessionStart;
  static const Duration _freshWindow = Duration(seconds: 25); // adjust if needed
  bool _resumeTried = false;      // avoid duplicate resumes
  bool _identityReady = false;    // user_id + auth_token ready?

  bool _navigating = false;      // avoid double push/pop
  bool _showingIncoming = false; // avoid double CallKit

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chanSub;


  Future<bool> _waitIdentityReady({int ms = 5000}) async {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < ms) {
      try {
        final p = await SharedPreferences.getInstance();
        final uid = (p.getString('user_id') ?? '').trim();
        final tok = (p.getString('auth_token') ?? '').trim();
        _identityReady = uid.isNotEmpty && tok.isNotEmpty;
        if (_identityReady) return true;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 120));
    }
    return _identityReady;
  }

  Future<BuildContext?> _waitNavContext({int ms = 5000}) async {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < ms) {
      final ctx = context;
      if (mounted && ctx.mounted) return ctx;
      await Future.delayed(const Duration(milliseconds: 60));
    }
    return mounted ? context : null;
  }

  /// Try to resume call using pending_join saved by CallKit accept
  Future<bool> _resumeFromPendingJoin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_join');
      if (raw == null || raw.isEmpty) return false;

      final extra = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final ch  = (extra['channel'] ?? extra['channelid'] ?? extra['callId'] ?? '').toString();
      final cid = (extra['callerId'] ?? '').toString();
      final rid = (extra['receiverId'] ?? '').toString();
      final name= (extra['callerName'] ?? extra['title'] ?? 'Caller').toString();

      if (ch.isEmpty || cid.isEmpty || rid.isEmpty) return false;

      // Receiver guard: is this device the receiver?
      if (widget.currentUserId.isNotEmpty && widget.currentUserId != rid) {
        // different account loaded → don't navigate
        await prefs.remove('pending_join');
        return false;
      }

      // Navigate
      if (!_navigating) {
        _navigating = true;
        final navCtx = await _waitNavContext(ms: 6000);
        if (navCtx != null) {
          Navigator.of(navCtx, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => CallScreen(
                channelId: ch,
                callerId: cid,
                receiverId: rid,
                peerName: name,
                isCaller: false,
              ),
            ),
                (_) => false,
          );
        }
        _navigating = false;
      }

      await prefs.remove('pending_join');
      return true;
    } catch (_) {
      return false;
    }
  }




  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now(); // yahi se “fresh” ka cutoff hoga

    // _ensureDocExists();
    _ensureDocExists().then((_) {
      // 🔴 Add this:
      _resumeIfAcceptedFromTerminated();
      _checkColdStartAccepted(); // 👈 NEW
      setState(() {}); // force rebuild after ensuring doc
    });
  }



  Future<bool> _resumeFromFirestoreAccepted() async {
    try {
      if (widget.currentUserId.isEmpty) return false;

      final ref = FirebaseFirestore.instance.collection('calls').doc(widget.currentUserId);
      final snap = await ref.get();
      final d = snap.data();
      if (d == null) return false;

      final status = (d['status'] ?? '').toString();
      final ch     = (d['channelId'] ?? '').toString();
      final isCaller = d['callerId'] == widget.currentUserId;

      if (status == 'accepted' && ch.isNotEmpty && !isCaller) {
        final callerId = (d['callerId'] ?? '').toString();
        final receiverId = (d['receiverId'] ?? '').toString();
        final peerName = (d['callerName'] ?? 'User').toString();

        _attachChannelWatcher(ch); // so end/reject auto closes

        if (!_navigating) {
          _navigating = true;
          final navCtx = await _waitNavContext(ms: 6000);
          if (navCtx != null) {
            Navigator.of(navCtx, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  channelId: ch,
                  callerId: callerId,
                  receiverId: receiverId,
                  peerName: peerName,
                  isCaller: false,
                ),
              ),
                  (_) => false,
            );
          }
          _navigating = false;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }



  Future<void> _resumeIfAcceptedFromTerminated() async {
    if (_resumeTried) return;
    _resumeTried = true;

    // 1) Identity wait (max ~5s). Even if not ready, pending_join path may still work,
    //    but having user_id/auth_token avoids guard failures.
    await _waitIdentityReady(ms: 5000);

    // 2) Try pending_join first (fastest)
    if (await _resumeFromPendingJoin()) return;

    // 3) Else fall back to Firestore 'accepted' (receiver side)
    await _resumeFromFirestoreAccepted();
  }


  Future<void> _ensureDocExists() async {
    try {
      final ref = FirebaseFirestore.instance.collection('calls').doc(widget.currentUserId);
      final s = await ref.get();
      if (!s.exists) {
        await ref.set({
          "status": "idle",
          "channelId": null,
          "callerId": null,
          "receiverId": null,
          "isCalling": false,
          "timestamp": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  void _postFrame(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fn();
    });
  }

  void _attachChannelWatcher(String channelId) {
    // change channel -> rebind
    _chanSub?.cancel();
    if (channelId.isEmpty) return;

    _chanSub = FirebaseFirestore.instance
        .collection('active_calls')
        .doc(channelId)
        .snapshots()
        .listen((snap) {
      final x = snap.data();
      if (x == null) return;
      final st = (x['status'] ?? '').toString().toLowerCase();
      if (st == 'ended' || st == 'rejected') {
        // shared channel says call over -> close UI
        _postFrame(() {
          if (!_navigating) {
            _navigating = true;
            Navigator.of(context, rootNavigator: true)
                .popUntil((r) => r.isFirst);
            _navigating = false;
          }
        });
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    try { _chanSub?.cancel(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("calls")
          .doc(widget.currentUserId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data?.data() == null) {
          return widget.child;
        }

        final d = snap.data!.data()!;
        final String ch = (d['channelId'] ?? '').toString();
        final String status = (d['status'] ?? 'idle').toString();
        final bool isCalling = d['isCalling'] == true;

        // 🔹 UPDATED: server timestamp padho
        final DateTime? updatedAt = (d['timestamp'] is Timestamp)
            ? (d['timestamp'] as Timestamp).toDate()
            : null;

        // bind channel watcher (also works if we never get peer doc writes)
        if (ch.isNotEmpty && ch != _lastChannelId) {
          _attachChannelWatcher(ch);
        }

        // 🔹 sirf recent updates handle karo
        final bool isFreshUpdate = updatedAt != null &&
            updatedAt.isAfter(_sessionStart.subtract(_freshWindow));

        // Agar fresh nahi hai → ignore (login pe purana “calling/accepted” UI nahi khulega)
        if (!isFreshUpdate) {
          return widget.child;
        }

        final changed = (ch != _lastChannelId) || (status != _lastStatus);
        _lastChannelId = ch;
        _lastStatus = status;

        if (!changed) return widget.child;

        // 1) INCOMING RING (receiver only)
        // 1) INCOMING RING (receiver only)
        if (status == 'calling' && isCalling && d['receiverId'] == widget.currentUserId) {

          final appState = WidgetsBinding.instance.lifecycleState;
          final isForeground = appState == AppLifecycleState.resumed;

          // // ❌ Foreground me CallKit popup NA dikhana
          // // ✅ Background/terminated me hi CallKit popup dikhana
          // if (!isForeground) {
          //   if (!_showingIncoming) {
          //     _showingIncoming = true;
          //     CallkitService.showIncomingCall({
          //       'type': 'incoming_call',
          //       'callId': ch,
          //       'channel': ch,
          //       'channelid': ch,
          //       'callerName': (d['callerName'] ?? 'Caller').toString(),
          //       'callerId': (d['callerId'] ?? '').toString(),
          //       'receiverId': widget.currentUserId,
          //     }).whenComplete(() => _showingIncoming = false);
          //   }
          // }

          // ✅ Foreground me sirf in-app Incoming UI dikhao
          // if (isForeground) {
          //   _postFrame(() {
          //     if (_navigating) return;
          //     _navigating = true;
          //     Navigator.of(context, rootNavigator: true).push(
          //       MaterialPageRoute(
          //         builder: (_) => IncomingCallScreen(
          //           channelId: ch,
          //           callerId: d['callerId'],
          //           callerName: d['callerName'],
          //           currentUserId: widget.currentUserId,
          //         ),
          //       ),
          //     ).whenComplete(() => _navigating = false);
          //   });
          // }

          return widget.child;
        }

        // 2) ACCEPTED -> open CallScreen (both sides)



        // 2) ACCEPTED -> open CallScreen (only receiver side)
        if (status == 'accepted' && ch.isNotEmpty) {
          final isCaller = d['callerId'] == widget.currentUserId;
          final peerName = isCaller
              ? (d['receiverName'] ?? 'User').toString()
              : (d['callerName'] ?? 'User').toString();

          // ✅ Sirf receiver (jisko call aaya) ke liye CallScreen khule
          if (!isCaller) {
            _postFrame(() {
              if (_navigating) return;
              _navigating = true;

              // close any intermediate screen
              Navigator.of(context, rootNavigator: true)
                  .popUntil((r) => r.isFirst);

              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    channelId: ch,
                    callerId: (d['callerId'] ?? '').toString(),
                    receiverId: (d['receiverId'] ?? '').toString(),
                    peerName: peerName,
                    isCaller: false, // Receiver side
                  ),
                ),
              ).whenComplete(() => _navigating = false);
            });
          }

          return widget.child;
        }


        // if (status == 'accepted' && ch.isNotEmpty) {
        //   final isCaller = d['callerId'] == widget.currentUserId;
        //   final peerName = isCaller
        //       ? (d['receiverName'] ?? 'User').toString()
        //       : (d['callerName'] ?? 'User').toString();
        //
        //   _postFrame(() {
        //     if (_navigating) return;
        //     _navigating = true;
        //
        //     // close any intermediate screen
        //     Navigator.of(context, rootNavigator: true)
        //         .popUntil((r) => r.isFirst);
        //
        //     Navigator.of(context, rootNavigator: true).pushReplacement(
        //       MaterialPageRoute(
        //         builder: (_) => CallScreen(
        //           channelId: ch,
        //           callerId: (d['callerId'] ?? '').toString(),
        //           receiverId: (d['receiverId'] ?? '').toString(),
        //           peerName: peerName,
        //           isCaller: isCaller,
        //         ),
        //       ),
        //     ).whenComplete(() => _navigating = false);
        //   });
        //   return widget.child;
        // }

        // 3) ENDED / REJECTED -> close everywhere
        if (status == 'ended' || status == 'rejected') {
          _postFrame(() {
            if (!_navigating) {
              _navigating = true;
              Navigator.of(context, rootNavigator: true)
                  .popUntil((r) => r.isFirst);
              _navigating = false;
            }
          });
          return widget.child;
        }

        return widget.child;
      },
    );
  }

  Future<void> _checkColdStartAccepted() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.currentUserId);

      // 1) First snapshot (instant)
      final doc = await ref.get();
      Map<String, dynamic>? d = doc.data();
      if (d != null) {
        final String ch = (d['channelId'] ?? '').toString();
        final String status = (d['status'] ?? 'idle').toString();
        final bool isCaller = d['callerId'] == widget.currentUserId;

        if (status == 'accepted' && ch.isNotEmpty && !isCaller && !_coldHandled) {
          _coldHandled = true;
          _attachChannelWatcher(ch);
          _postFrame(() {
            if (_navigating) return;
            _navigating = true;
            Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
            Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  channelId: ch,
                  callerId: (d['callerId'] ?? '').toString(),
                  receiverId: (d['receiverId'] ?? '').toString(),
                  peerName: (d['callerName'] ?? 'User').toString(),
                  isCaller: false,
                ),
              ),
            ).whenComplete(() => _navigating = false);
          });
          return;
        }
      }

      // 2) If still not accepted (mostly 'calling'), do a short live listen
      //    so race-condition cover ho jaye (accept write aa jaaye to turant open)
      if (_coldHandled) return;
      StreamSubscription? sub;
      Timer? stopper;

      void closeListener() {
        try { sub?.cancel(); } catch (_) {}
        try { stopper?.cancel(); } catch (_) {}
      }

      sub = ref.snapshots().listen((snap) {
        final x = snap.data();
        if (x == null) return;
        final String ch = (x['channelId'] ?? '').toString();
        final String status = (x['status'] ?? 'idle').toString();
        final bool isCaller = x['callerId'] == widget.currentUserId;

        if (status == 'accepted' && ch.isNotEmpty && !isCaller && !_coldHandled) {
          _coldHandled = true;
          closeListener();
          _attachChannelWatcher(ch);
          _postFrame(() {
            if (_navigating) return;
            _navigating = true;
            Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
            Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  channelId: ch,
                  callerId: (x['callerId'] ?? '').toString(),
                  receiverId: (x['receiverId'] ?? '').toString(),
                  peerName: (x['callerName'] ?? 'User').toString(),
                  isCaller: false,
                ),
              ),
            ).whenComplete(() => _navigating = false);
          });
        }

        // agar call khatam ho gayi to listener bandh
        if (status == 'ended' || status == 'rejected') {
          closeListener();
        }
      });

      // 6–8 sec ka guard: agar itne me accept update na aaya to chhod do
      stopper = Timer(const Duration(seconds: 8), () {
        closeListener();
      });
    } catch (_) {}
  }
}



