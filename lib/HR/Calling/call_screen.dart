// call_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/splash_screen.dart';
import 'Firebase_store.dart';
import 'agora_provider.dart';
import 'call_service.dart';

class CallScreen extends StatefulWidget {
  final String channelId;
  final String callerId;
  final String receiverId;
  final String peerName;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.channelId,
    required this.callerId,
    required this.receiverId,
    required this.peerName,
    required this.isCaller,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {

  StreamSubscription? _actChanSub;
  StreamSubscription? _peerDocSub;

  Future<void> _handleRemoteEnd() async {
    // sticky guard: pehle 3s me aaya to thoda wait karke confirm
    if (DateTime.now().isBefore(_stickyCloseGuardUntil)) {
      debugPrint('[CALLSCREEN] remote-end within sticky window; rechecking...');
      await Future.delayed(const Duration(milliseconds: 800));
      if (DateTime.now().isBefore(_stickyCloseGuardUntil)) return;
    }
    if (_isClosing) return;
    _isClosing = true;

    try { await _remoteWatcher?.cancel(); } catch (_) {}
    try { await _actChanSub?.cancel(); } catch (_) {}
    try { await _peerDocSub?.cancel(); } catch (_) {}

    try { await _provider.dispose(); } catch (_) {}

    final p = await SharedPreferences.getInstance();
    await p.setBool('call_join_active', false);
    await p.remove('pending_join');
    await p.remove('pending_join_at');

    _closeSelf();
  }


  late AgoraProvider _provider;
  StreamSubscription? _remoteWatcher;
  // 👇 re-entrancy guard: ek hi dafa close karein
  bool _isClosing = false;
  DateTime _stickyCloseGuardUntil = DateTime.fromMillisecondsSinceEpoch(0);


// _CallScreenState ke andar:
  String get _selfId => widget.isCaller ? widget.callerId : widget.receiverId;
  String get _peerId => widget.isCaller ? widget.receiverId : widget.callerId;


  @override
  void initState() {
    _stickyCloseGuardUntil = DateTime.now().add(const Duration(seconds: 3));

    super.initState();
    debugPrint('[CALLSCREEN] mounted ${DateTime.now()}');
    () async {
      final prefs = await SharedPreferences.getInstance();
      // CallScreen UI lock: ab se pump band ho jayega
      await prefs.setBool('call_join_active', true);

      // ✅ consume immediately so app reopen pe dubara na khule
      await prefs.remove('pending_join');
      await prefs.remove('pending_join_at');
    }();
    print("📞 CallScreen initState called");
    // pending_join clear so app reopen par dubara CallScreen na aaye
    // SharedPreferences.getInstance()
    //     .then((p) => p.remove('pending_join'))
    //     .catchError((_) {});
    _provider = AgoraProvider();
    _provider.init(
      widget.channelId, widget.callerId, widget.receiverId, widget.isCaller,
    );


    // 1) active_calls/{channelId}
    _actChanSub = FirebaseFirestore.instance
        .collection('active_calls').doc(widget.channelId)
        .snapshots().listen((snap) {
      final st = (snap.data()?['status'] ?? '').toString().toLowerCase();
      if (st == 'ended' || st == 'rejected' || st == 'timeout') {
        _handleRemoteEnd();
      }
    });

// 2) calls/{selfId} (sirf same channel events)
    _peerDocSub = FirebaseFirestore.instance
        .collection('calls').doc(_selfId)
        .snapshots().listen((snap) {
      final d = snap.data();
      if (d == null) return;
      final ch = (d['channelId'] ?? d['channel'] ?? '').toString();
      if (ch != widget.channelId) return;
      final st = (d['status'] ?? '').toString().toLowerCase();
      if (st == 'ended' || st == 'rejected' || st == 'timeout') {
        _handleRemoteEnd();
      }
    });



    _remoteWatcher = CallStore.instance.bindCloseWatcher(

      selfId: _selfId,
      peerId: _peerId,
      channelId: widget.channelId,
      onRemoteEnd: () {
        // Early-close guard: pehle 3s tak remote-end ko ignore/recheck
        if (DateTime.now().isBefore(_stickyCloseGuardUntil)) {
          debugPrint('[CALLSCREEN] early remote-end ignored (sticky window)');
          // optional: thoda delay karke confirm
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted || _isClosing) return;
            // yahan optional: dobara status read kar sakte ho agar CallStore expose karta ho
          });
          return;
        }
        if (_isClosing) return;
        _isClosing = true;
        try { _provider.dispose(); } catch (_) {}
        if (mounted) {
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) {
            nav.pop(); // sirf CallScreen close
          } else {
            // fallback → SplashScreen dikhado, warna black screen
            nav.pushReplacement(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
            );
          }
        }

      },
    );
  }



  void _closeSelf() {
    if (!mounted) return;

    // always use the root navigator you used to open CallScreen
    final nav = Navigator.of(context, rootNavigator: true);

    // if we can pop -> just pop this CallScreen
    if (nav.canPop()) {
      try {
        nav.pop();
        return;
      } catch (_) { /* ignore */ }
    }

    // nothing underneath? go to your home/splash instead of black screen
    nav.pushReplacement(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

// call_screen.dart

  Future<void> _endCall() async {
    if (_isClosing) return;
    _isClosing = true;

    try { await _remoteWatcher?.cancel(); } catch (_) {}
    _remoteWatcher = null;

    try {
      await CallStore.instance.end(
        callerId: widget.callerId,
        receiverId: widget.receiverId,
        selfId: _selfId,
        channelId: widget.channelId,
      );
    } catch (e) { debugPrint("❌ endCall error: $e"); }

    try { await _provider.dispose(); } catch (_) {}
    // if (mounted) {
    //   Navigator.of(context, rootNavigator: true).pop(); // ✅ close only this screen
    // }
    _closeSelf();
  }



  /// - warna -> pushReplacement to Splash/Home
  // void _safeClose() {
  //   if (!mounted) return;
  //   SchedulerBinding.instance.addPostFrameCallback((_) async {
  //     try {
  //       final p = await SharedPreferences.getInstance();
  //       await p.remove('pending_join');
  //     } catch (_) {}
  //
  //     if (!mounted) return;
  //     Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
  //       MaterialPageRoute(builder: (_) => const SplashScreen()),
  //           (_) => false,
  //     );
  //   });
  // }

  void _safeClose() {
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try { final p = await SharedPreferences.getInstance(); await p.remove('pending_join'); } catch (_) {}
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
            (_) => false,
      );
    });
  }


  @override
  void dispose() {

    _isClosing = true;

    // 🔥 Remote watcher cancel
    try { _remoteWatcher?.cancel(); } catch (_) {}
    _remoteWatcher = null;
    // _provider.dispose();
    try { _provider.dispose(); } catch (_) {}


    debugPrint('[CALLSCREEN] disposed ${DateTime.now()}');
    () async {
      final p = await SharedPreferences.getInstance();
      await p.setBool('call_join_active', false);
      await p.remove('pending_join');

      try { await _remoteWatcher?.cancel(); } catch (_) {}
    try { await _actChanSub?.cancel(); } catch (_) {}
    try { await _peerDocSub?.cancel(); } catch (_) {}
    try { _provider.dispose(); } catch (_) {}
    await p.setBool('call_join_active', false);
    await p.remove('pending_join');
    await p.remove('pending_join_at');
    }();






    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    // return _provider.buildUI(context, widget.peerName, onEndCall: _endCall);
    return WillPopScope(
      // onWillPop: () async { await _endCall(); return false; },
      onWillPop: () async => false,  // ❌ yahan _endCall() mat bulana
      child: _provider.buildUI(context, widget.peerName, onEndCall: _endCall),
    );
  }
}
