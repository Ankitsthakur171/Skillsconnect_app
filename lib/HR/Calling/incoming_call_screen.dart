// // // incoming_call_screen.dart
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter/material.dart';
// // import 'call_screen.dart';
// //
// // class IncomingCallScreen extends StatelessWidget {
// //   final String channelId;
// //   final String callerId;
// //   final String callerName;
// //   final String currentUserId; // receiverId
// //
// //   const IncomingCallScreen({
// //     super.key,
// //     required this.channelId,
// //     required this.callerId,
// //     required this.callerName,
// //     required this.currentUserId,
// //   });
// //
// //   Future<void> _accept(BuildContext context) async {
// //     final db = FirebaseFirestore.instance;
// //     // दोनों docs update
// //     await db.collection("calls").doc(currentUserId).update({
// //       "status": "accepted", "isCalling": false,
// //     });
// //     await db.collection("calls").doc(callerId).update({
// //       "status": "accepted", "isCalling": false,
// //     });
// //
// //     if (context.mounted) {
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) => CallScreen(
// //             channelId: channelId,
// //             callerId: callerId,
// //             receiverId: currentUserId,
// //             peerName: callerName,
// //             isCaller: false,
// //           ),
// //         ),
// //       );
// //     }
// //   }
// //
// //
// //
// //   Future<void> _reject(BuildContext context) async {
// //     final db = FirebaseFirestore.instance;
// //     await db.collection("calls").doc(currentUserId).update({
// //       "status": "rejected", "isCalling": false,
// //     });
// //     await db.collection("calls").doc(callerId).update({
// //       "status": "rejected", "isCalling": false,
// //     });
// //     if (context.mounted) Navigator.pop(context);
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Center(
// //         child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
// //           const Icon(Icons.ring_volume, size: 92, color: Colors.green),
// //           const SizedBox(height: 12),
// //           Text("Incoming Call from $callerName",
// //               style: const TextStyle(fontSize: 18)),
// //           const SizedBox(height: 24),
// //           Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
// //             ElevatedButton(
// //               onPressed: () => _reject(context),
// //               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
// //               child: const Text("Reject"),
// //             ),
// //             ElevatedButton(
// //               onPressed: () => _accept(context),
// //               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
// //               child: const Text("Accept"),
// //             ),
// //           ]),
// //         ]),
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
//
//
//
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:vibration/vibration.dart';
// import 'package:skillsconnect/HR/Calling/call_service.dart';
// import 'call_screen.dart';
//
// class IncomingCallScreen extends StatefulWidget {
//   final String channelId;
//   final String callerId;
//   final String callerName;
//   final String currentUserId;
//
//   const IncomingCallScreen({
//     super.key,
//     required this.channelId,
//     required this.callerId,
//     required this.callerName,
//     required this.currentUserId,
//   });
//
//   @override
//   State<IncomingCallScreen> createState() => _IncomingCallScreenState();
// }
//
// class _IncomingCallScreenState extends State<IncomingCallScreen> {
//   StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chanSub;
//   StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _selfDocSub;
//   bool _closing = false;
//   Timer? _vibrateTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _startVibration();
//
//     _chanSub = FirebaseFirestore.instance
//         .collection('active_calls')
//         .doc(widget.channelId)
//         .snapshots()
//         .listen((snap) {
//       final data = snap.data();
//       final st = (data?['status'] ?? 'ended').toString().toLowerCase();
//       if (st == 'ended' || st == 'rejected') {
//         _safeClose();
//       }
//     }, onError: (_) {});
//
//     _selfDocSub = FirebaseFirestore.instance
//         .collection('calls')
//         .doc(widget.currentUserId)
//         .snapshots()
//         .listen((snap) {
//       final d = snap.data();
//       if (d == null) return;
//       final st = (d['status'] ?? '').toString().toLowerCase();
//       if (st == 'ended' || st == 'rejected') {
//         _safeClose();
//       }
//     }, onError: (_) {});
//   }
//
//   void _startVibration() async {
//     if (await Vibration.hasVibrator() ?? false) {
//       _vibrateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
//         Vibration.vibrate(duration: 1000, amplitude: 128);
//       });
//     }
//   }
//
//   void _stopVibration() {
//     _vibrateTimer?.cancel();
//     Vibration.cancel();
//   }
//
//   void _safeClose() {
//     if (_closing) return;
//     _closing = true;
//     _stopVibration();
//     if (!mounted) return;
//     Navigator.of(context, rootNavigator: true).maybePop();
//   }
//
//   @override
//   void dispose() {
//     try {
//       _chanSub?.cancel();
//       _selfDocSub?.cancel();
//       _vibrateTimer?.cancel();
//       Vibration.cancel();
//     } catch (_) {}
//     super.dispose();
//   }
//
//   Future<void> _accept(BuildContext context) async {
//     _stopVibration();
//
//     final db = FirebaseFirestore.instance;
//     final batch = db.batch();
//     final selfRef = db.collection("calls").doc(widget.currentUserId);
//     final callerRef = db.collection("calls").doc(widget.callerId);
//
//     batch.set(selfRef, {"status": "accepted", "isCalling": false}, SetOptions(merge: true));
//     batch.set(callerRef, {"status": "accepted", "isCalling": false}, SetOptions(merge: true));
//     await batch.commit();
//
//     final extra = {
//       "channel": widget.channelId,
//       "callerId": widget.callerId,
//       "receiverId": widget.currentUserId,
//       "callerName": widget.callerName,
//       "title": widget.callerName,
//     };
//     await CallService.joinCall(extra, ctxOverride: context);
//   }
//
//   Future<void> _reject(BuildContext context) async {
//     _stopVibration();
//
//     final db = FirebaseFirestore.instance;
//     final batch = db.batch();
//     final selfRef = db.collection("calls").doc(widget.currentUserId);
//     final callerRef = db.collection("calls").doc(widget.callerId);
//
//     batch.set(selfRef, {"status": "rejected", "isCalling": false}, SetOptions(merge: true));
//     batch.set(callerRef, {"status": "rejected", "isCalling": false}, SetOptions(merge: true));
//     await batch.commit();
//
//     if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     return Scaffold(
//       backgroundColor: Colors.teal.shade900,
//       body: SafeArea(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.call, size: 100, color: Colors.white),
//               const SizedBox(height: 20),
//               Text(
//                 "Incoming Call",
//                 style: const TextStyle(fontSize: 22, color: Colors.white70, letterSpacing: 1),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 widget.callerName,
//                 style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
//               ),
//               const SizedBox(height: 50),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _actionButton(
//                     icon: Icons.call_end,
//                     color: Colors.red.shade600,
//                     label: "Reject",
//                     onTap: () => _reject(context),
//                   ),
//                   _actionButton(
//                     icon: Icons.call,
//                     color: Colors.green.shade600,
//                     label: "Accept",
//                     onTap: () => _accept(context),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _actionButton({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       children: [
//         InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(50),
//           child: Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(color: color.withOpacity(0.6), blurRadius: 15, spreadRadius: 3)
//               ],
//             ),
//             child: Icon(icon, color: Colors.white, size: 40),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
//       ],
//     );
//   }
// }
