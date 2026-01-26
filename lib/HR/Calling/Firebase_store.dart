// lib/core/calling/call_store.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CallStore {
  CallStore._();
  static final CallStore instance = CallStore._();

  final _db = FirebaseFirestore.instance;

  /// Collections
  CollectionReference<Map<String, dynamic>> get _calls => _db.collection('calls');
  CollectionReference<Map<String, dynamic>> get _channels => _db.collection('active_calls');

  /// Create (or overwrite) both user docs + channel doc. Returns channelId.
  Future<String> createCall({
    required String channelId,
    required String callerId,
    required String callerName,
    required String receiverId,
    required String receiverName,
  }) async {
    final now = FieldValue.serverTimestamp();

    // clear any old call docs for these users
    try { await _calls.doc(receiverId).delete(); } catch (_) {}
    try { await _calls.doc(callerId).delete(); } catch (_) {}

    final base = {
      "channelId": channelId,
      "callerId": callerId,
      "callerName": callerName.isEmpty ? "Caller" : callerName,
      "receiverId": receiverId,
      "receiverName": receiverName,
      "timestamp": now,
    };

    final calleeDoc = { ...base, "status": "calling",  "isCalling": true  };
    final callerDoc = { ...base, "status": "outgoing", "isCalling": false };

    final batch = _db.batch();
    batch.set(_calls.doc(receiverId), calleeDoc);
    batch.set(_calls.doc(callerId),   callerDoc);
    batch.set(_channels.doc(channelId), {"status": "calling", "timestamp": now}, SetOptions(merge: true));
    await batch.commit();

    return channelId;
  }

  /// Mark both sides accepted + channel accepted (optional)
  Future<void> accept({
    required String callerId,
    required String receiverId,
    String? channelId,
  }) async {
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    batch.set(_calls.doc(callerId),   {"status": "accepted", "isCalling": false, "timestamp": now}, SetOptions(merge: true));
    batch.set(_calls.doc(receiverId), {"status": "accepted", "isCalling": false, "timestamp": now}, SetOptions(merge: true));
    if (channelId != null && channelId.isNotEmpty) {
      batch.set(_channels.doc(channelId), {"status": "accepted", "timestamp": now}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// End call (fault-tolerant): always set self + channel, try peer.
  Future<void> end({
    required String callerId,
    required String receiverId,
    required String selfId,       // jis device se end aaya
    String? channelId,
  }) async {
    final now = FieldValue.serverTimestamp();
    final me = selfId;
    final peer = (me == callerId) ? receiverId : callerId;

    // self
    try {
      await _calls.doc(me).set({"status":"ended","isCalling":false,"timestamp":now}, SetOptions(merge:true));
    } catch (e) { debugPrint("CallStore.end self write failed: $e"); }

    // channel
    if (channelId != null && channelId.isNotEmpty) {
      try { await _channels.doc(channelId).set({"status":"ended","timestamp":now}, SetOptions(merge:true)); }
      catch (e) { debugPrint("CallStore.end channel write failed: $e"); }
    }

    // peer (best-effort)
    try {
      await _calls.doc(peer).set({"status":"ended","isCalling":false,"timestamp":now}, SetOptions(merge:true));
    } catch (e) {
      debugPrint("CallStore.end peer write blocked (rules?): $e");
    }
  }

  Future<void> reject({
    required String callerId,
    required String receiverId,
    required String selfId,
    String? channelId,
  }) async {
    final now = FieldValue.serverTimestamp();
    final me = selfId;
    final peer = (me == callerId) ? receiverId : callerId;

    try { await _calls.doc(me).set({"status":"rejected","isCalling":false,"timestamp":now}, SetOptions(merge:true)); } catch (_) {}
    if (channelId != null && channelId.isNotEmpty) {
      try { await _channels.doc(channelId).set({"status":"rejected","timestamp":now}, SetOptions(merge:true)); } catch (_) {}
    }
    try { await _calls.doc(peer).set({"status":"rejected","isCalling":false,"timestamp":now}, SetOptions(merge:true)); } catch (_) {}
  }

  /// Generic: set both docs to status (accepted/rejected/ended) — batch
  Future<void> setBoth({
    required String callerId,
    required String receiverId,
    required String status,
    String? channelId,
  }) async {
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    batch.set(_calls.doc(callerId),   {"status": status, "isCalling": false, "timestamp": now}, SetOptions(merge: true));
    batch.set(_calls.doc(receiverId), {"status": status, "isCalling": false, "timestamp": now}, SetOptions(merge: true));
    if (channelId != null && channelId.isNotEmpty) {
      batch.set(_channels.doc(channelId), {"status": status, "timestamp": now}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Watcher: self + peer + channel — fires once on end/reject
  StreamSubscription bindCloseWatcher({
    required String selfId,
    required String peerId,
    required String channelId,
    required VoidCallback onRemoteEnd,
  }) {
    bool fired = false;
    void fire() { if (!fired) { fired = true; onRemoteEnd(); } }

    final s1 = _calls.doc(peerId).snapshots().listen((snap) {
      final d = snap.data();
      if (d == null) return;
      final st = (d['status'] ?? '').toString().toLowerCase();
      if (st == 'ended' || st == 'rejected') fire();
    });

    final s2 = _calls.doc(selfId).snapshots().listen((snap) {
      final d = snap.data();
      if (d == null) return;
      final st = (d['status'] ?? '').toString().toLowerCase();
      if (st == 'ended' || st == 'rejected') fire();
    });

    final s3 = _channels.doc(channelId).snapshots().listen((snap) {
      final d = snap.data();
      if (d == null) return;
      final st = (d['status'] ?? '').toString().toLowerCase();
      if (st == 'ended' || st == 'rejected') fire();
    });

    return _Combined([s1, s2, s3]);
  }
}

/// Combines subs
class _Combined implements StreamSubscription<void> {
  final List<StreamSubscription> _subs;
  _Combined(this._subs);

  @override Future<void> cancel() async { for (final s in _subs) { try { await s.cancel(); } catch (_) {} } }
  @override void onData(void Function(void data)? handleData) {}
  @override void onDone(void Function()? handleDone) {}
  @override void onError(Function? handleError) {}
  @override void pause([Future<void>? resumeSignal]) {}
  @override void resume() {}
  @override bool get isPaused => false;
  @override Future<E> asFuture<E>([E? futureValue]) async => (futureValue as E);
}
