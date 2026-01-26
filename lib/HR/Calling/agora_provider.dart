///Without Ringback Code Tur Tur

// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show ValueListenable;
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/services.dart'; // <-- NEW
// import '../../Constant/constants.dart';
// import '../../app_globals.dart';
// import '../screens/WavyCircle.dart';
// import 'call_provider.dart';
// import 'calutils_helper.dart';
//
//
// enum AudioRoute { earpiece, speaker, bluetooth }
//
//
// /// ---- DTO for server token (per-UID) ----
// class AgoraTokenResponse {
//   final String appId;
//   final String channelName;
//   final int uid; // >0 => token bound to that uid
//   final String role; // "publisher"/"subscriber" (server-defined string is fine)
//   final String token;
//   final int expireAt;   // epoch seconds
//   final int serverTime; // epoch seconds (server clock)
//
//   const AgoraTokenResponse({
//     required this.appId,
//     required this.channelName,
//     required this.uid,
//     required this.role,
//     required this.token,
//     required this.expireAt,
//     required this.serverTime,
//   });
//
//   factory AgoraTokenResponse.fromJson(Map<String, dynamic> j) {
//     int _toInt(dynamic v) {
//       if (v is int) return v;
//       return int.tryParse('${v ?? 0}') ?? 0;
//     }
//
//     return AgoraTokenResponse(
//       appId: (j['appId'] ?? '').toString(),
//       channelName: (j['channelName'] ?? '').toString(),
//       uid: _toInt(j['uid']),
//       role: (j['role'] ?? '').toString(),
//       token: (j['token'] ?? '').toString(),
//       expireAt: _toInt(j['expireAt']),
//       serverTime: _toInt(j['serverTime']),
//     );
//   }
// }
//
// class AgoraProvider extends CallProvider {
//   late RtcEngine _engine;
//   bool _engineInit = false;
//
//   Completer<void>? _initBusy;
//
//
//   // NEW: current route (UI ke liye)
//   final ValueNotifier<AudioRoute> _routeVN = ValueNotifier(AudioRoute.earpiece);
//
//   // NEW: platform channel for BT control (Android/iOS)
//   static const MethodChannel _routeChannel = MethodChannel('app.audio.route');
//
//
//   // --- Call state
//   final ValueNotifier<bool> _joinedVN = ValueNotifier(false);
//   final ValueNotifier<int?> _remoteUidVN = ValueNotifier(null);
//
//   // --- UI toggles
//   final ValueNotifier<bool> _mutedVN = ValueNotifier(false);
//   final ValueNotifier<bool> _speakerOnVN = ValueNotifier(false); // default earpiece
//
//   // --- meta
//   late String _callerId;
//   late String _receiverId;
//   late bool _isCaller;
//
//   // --- channel state
//   String? _currentChannelId;
//   bool _inChannel = false;
//   int? _localUid;                 // our planned uid (non-zero, stable)
//   AgoraTokenResponse? _lastToken; // last token used
//
//   // --- timers
//   Timer? _tokenSafetyTimer;    // proactive renewal
//   Timer? _connectGuardTimer;   // optional: surface "no answer"
//
//   // ---------- Helpers ----------
//   /// Stable, positive 31-bit UID from any string (e.g., your auth user id)
//   int _deriveUid(String input) {
//     final parsed = int.tryParse(input);
//     if (parsed != null && parsed > 0) return parsed;
//     int h = 0;
//     for (final c in input.codeUnits) {
//       h = ((h * 131) + c) & 0x7fffffff;
//     }
//     return (h == 0) ? 1 : h; // avoid 0; Agora requires >0 for per-uid tokens
//   }
//
//   Future<void> _ensureLeftAndReleased() async {
//     try {
//       if (_engineInit) {
//         try { await _engine.leaveChannel(); } catch (_) {}
//         try { await _engine.release(); } catch (_) {}
//       }
//     } finally {
//       _tokenSafetyTimer?.cancel();
//       _tokenSafetyTimer = null;
//       _connectGuardTimer?.cancel();
//       _connectGuardTimer = null;
//
//       _engineInit = false;
//       _inChannel = false;
//       _currentChannelId = null;
//       _localUid = null;
//       _lastToken = null;
//
//       _joinedVN.value = false;
//       _remoteUidVN.value = null;
//       _mutedVN.value = false;
//       _speakerOnVN.value = false;
//     }
//   }
//
//   /// Hit your API to fetch a token **for a specific UID + channel**.
//   ///
//   /// Backend contract (recommended):
//   /// POST /mobile/calls/agora-token
//   /// {
//   ///   "channelName": "<string>",
//   ///   "uid": <int>,               // REQUIRED; > 0
//   ///   "ttlSeconds": "3600",       // optional
//   ///   "role": "publisher"         // optional; or infer role on server
//   /// }
//   Future<AgoraTokenResponse> _fetchAgoraToken(
//       String channelId, {
//         required int uid,
//         String ttlSeconds = '3600',
//         String role = 'publisher', // broadcaster
//       }) async {
//     final url = Uri.parse('${BASE_URL}calls/agora-token');
//
//     final headers = <String, String>{ 'Content-Type': 'application/json' };
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final auth = prefs.getString('auth_token') ?? '';
//       if (auth.isNotEmpty) headers['Authorization'] = 'Bearer $auth';
//     } catch (_) {}
//
//     final body = jsonEncode({
//       'channelName': channelId,
//       'uid': uid,             // 👈 send the client uid
//       'ttlSeconds': ttlSeconds,
//       'role': role,
//     });
//
//     final resp = await http.post(url, headers: headers, body: body);
//     if (resp.statusCode < 200 || resp.statusCode >= 300) {
//       throw Exception('Token API failed (${resp.statusCode}): ${resp.body}');
//     }
//     final res = AgoraTokenResponse.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
//     // Safety: server should echo back same uid; warn if mismatch
//     if (res.uid != uid) {
//       // Not throwing hard, but logging helps diagnose server mismatch.
//       print("⚠️ Server returned uid=${res.uid}, but client requested uid=$uid. Verify backend.");
//     }
//     return res;
//   }
//
//   void _scheduleTokenRenewal(AgoraTokenResponse tr, {required int uid}) {
//     _tokenSafetyTimer?.cancel();
//     if (tr.expireAt <= 0 || tr.serverTime <= 0) return;
//
//     final secondsLeft = tr.expireAt - tr.serverTime;
//     // renew ~60 seconds before expiry (min 20s)
//     final renewIn = Duration(
//       seconds: secondsLeft > 80 ? secondsLeft - 60 : (secondsLeft > 20 ? secondsLeft - 20 : 5),
//     );
//
//     _tokenSafetyTimer = Timer(renewIn, () async {
//       if (!_engineInit || !_inChannel || _currentChannelId == null || _localUid == null) return;
//       try {
//         final newTok = await _fetchAgoraToken(_currentChannelId!, uid: uid);
//         _lastToken = newTok;
//         await _engine.renewToken(newTok.token);
//         _scheduleTokenRenewal(newTok, uid: uid);
//         print("🔄 Token renewed (uid=$uid)");
//       } catch (e) {
//         print("⚠️ Token renew failed: $e");
//       }
//     });
//   }
//
//   Future<void> _initEngine(String appId) async {
//     _engine = createAgoraRtcEngine();
//     await _engine.initialize(
//       RtcEngineContext(
//         appId: appId,
//         channelProfile: ChannelProfileType.channelProfileCommunication,
//       ),
//     );
//     _engineInit = true;
//
//     try {
//       await _engine.setParameters(r'{"che.video.enable":0}');
//       await _engine.setLogLevel(LogLevel.logLevelInfo);
//     } catch (_) {}
//
//     _engine.registerEventHandler(
//       RtcEngineEventHandler(
//         onJoinChannelSuccess: (connection, elapsed) async {
//           _joinedVN.value = true;
//           _inChannel = true;
//           _currentChannelId = connection.channelId;
//
//
//           // Default: earpiece (phone-call style). Toggleavailable in UI.
//           try {
//             // NEW — normal phone-call jaisa: start on earpiece (speaker OFF)
//             await _engine.setDefaultAudioRouteToSpeakerphone(false); // default = earpiece
//             await _engine.setEnableSpeakerphone(false);
//             await _maybeAutoRouteOnJoin(); // speaker OFF at start
//             await _syncRouteFromNative();
//             // <-- NEW
//           } catch (e) {
//             print("⚠️ set audio route failed: $e");
//           }
//           print("✅ Joined channel ${connection.channelId} as localUid=${connection.localUid} (elapsed=${elapsed}ms)");
//         },
//
//         onUserJoined: (connection, uid, elapsed) {
//           print("👋 Remote joined: uid=$uid (${elapsed}ms)");
//           _remoteUidVN.value = uid;
//         },
//
//         onFirstRemoteAudioFrame: (connection, uid, elapsed) {
//           print("🔊 First remote audio from uid=$uid (elapsed=${elapsed}ms)");
//           _remoteUidVN.value = uid;
//         },
//
//         onRemoteAudioStateChanged: (connection, uid, state, reason, elapsed) {
//           print("🎛️ RemoteAudioState uid=$uid state=$state reason=$reason elapsed=$elapsed");
//           if (state == RemoteAudioState.remoteAudioStateDecoding) {
//             _remoteUidVN.value = uid;
//           }
//         },
//
//         onUserOffline: (connection, uid, reason) {
//           print("👋 Remote offline: uid=$uid reason=$reason");
//           _remoteUidVN.value = null;
//         },
//
//         onConnectionStateChanged: (connection, state, reason) async {
//           print("🔗 Connection state=$state reason=$reason");
//           if (state == ConnectionStateType.connectionStateFailed) {
//             // small backoff + retry join with same uid + token
//             await Future<void>.delayed(const Duration(seconds: 1));
//             if (_lastToken != null && _currentChannelId != null && _localUid != null) {
//               try {
//                 await _engine.joinChannel(
//                   token: _lastToken!.token,
//                   channelId: _currentChannelId!,
//                   uid: _localUid!,
//                   options: const ChannelMediaOptions(
//                     channelProfile: ChannelProfileType.channelProfileCommunication,
//                     clientRoleType: ClientRoleType.clientRoleBroadcaster,
//                     autoSubscribeAudio: true,
//                     publishMicrophoneTrack: true,
//                   ),
//                 );
//               } catch (e) {
//                 print("❌ Retry join failed: $e");
//               }
//             }
//           }
//         },
//
//         onTokenPrivilegeWillExpire: (connection, token) async {
//           print("⏳ Token will expire soon; renewing...");
//           try {
//             if (_currentChannelId != null && _localUid != null) {
//               final newTok = await _fetchAgoraToken(_currentChannelId!, uid: _localUid!);
//               _lastToken = newTok;
//               await _engine.renewToken(newTok.token);
//               _scheduleTokenRenewal(newTok, uid: _localUid!);
//             }
//           } catch (e) {
//             print("⚠️ Token renew (willExpire) failed: $e");
//           }
//         },
//
//         onError: (err, msg) {
//           print("❌ Agora error: $err, $msg");
//         },
//
//         onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int vad) {
//           if (_remoteUidVN.value == null && speakers.isNotEmpty) {
//             for (final spk in speakers) {
//               if (spk.uid != 0) {
//                 _remoteUidVN.value = spk.uid;
//                 break;
//               }
//             }
//           }
//         },
//       ),
//     );
//
//     await _engine.enableAudio();
//     await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
//     await _engine.setAudioScenario(AudioScenarioType.audioScenarioDefault);
//     await _engine.enableAudioVolumeIndication(interval: 500, smooth: 3, reportVad: true);
//   }
//
//   // ----------------- PUBLIC API -----------------
//   @override
//   Future<void> init(String channelId, String callerId, String receiverId, bool isCaller) async {
//     if (_initBusy != null) return _initBusy!.future;
//     _initBusy = Completer<void>();
//
//     _callerId = callerId;
//     _receiverId = receiverId;
//     _isCaller = isCaller;
//
//     print("🎙️ AgoraProvider.init() channelId=$channelId, isCaller=$isCaller");
//
//     try {
//       // 0) Mic permission
//       final mic = await Permission.microphone.request();
//       if (!mic.isGranted) {
//         print("❌ Mic permission denied");
//         _initBusy?.complete();
//         return;
//       }
//
//       // 1) If already in THIS channel, ignore
//       if (_engineInit && _inChannel && _currentChannelId == channelId) {
//         print("ℹ️ Already in same channel, skip re-init");
//         _initBusy?.complete();
//         return;
//       }
//
//       // 2) If in a different channel, clean exit
//       if (_engineInit && _inChannel && _currentChannelId != channelId) {
//         print("↩️ Leaving previous channel: $_currentChannelId");
//         await _ensureLeftAndReleased();
//       }
//
//       // 3) Decide our **own** UID (stable + non-zero)
//       //    Caller uses callerId, callee uses receiverId — this makes each device's UID unique & predictable.
//       final myUid = _deriveUid(isCaller ? callerId : receiverId);
//       _localUid = myUid;
//
//       // 4) Get per-UID token from backend
//       final tokenRes = await _fetchAgoraToken(channelId, uid: myUid, ttlSeconds: '3600', role: 'publisher');
//       if (tokenRes.appId.isEmpty || tokenRes.token.isEmpty) {
//         throw Exception('Invalid token response: appId/token empty');
//       }
//       _lastToken = tokenRes;
//       _scheduleTokenRenewal(tokenRes, uid: myUid);
//
//       // 5) Init engine
//       await _initEngine(tokenRes.appId);
//
//       // 6) Join with the **same uid** used to request token
//       try {
//         await _engine.joinChannel(
//           token: tokenRes.token,
//           channelId: channelId.trim(),
//           uid: myUid,
//           options: const ChannelMediaOptions(
//             channelProfile: ChannelProfileType.channelProfileCommunication,
//             clientRoleType: ClientRoleType.clientRoleBroadcaster,
//             autoSubscribeAudio: true,
//             publishMicrophoneTrack: true,
//           ),
//         );
//       } on AgoraRtcException catch (e) {
//         if (e.code == -17) {
//           print("⚠️ joinChannel rejected (-17). Already in channel?");
//           _inChannel = true;
//           _currentChannelId = channelId;
//           _joinedVN.value = true;
//         } else {
//           rethrow;
//         }
//       }
//
//       print("👉 joinChannel sent: channel=$channelId uid=$myUid");
//
//       // 7) Small guard for "no answer" visibility
//       _connectGuardTimer?.cancel();
//       _connectGuardTimer = Timer(const Duration(seconds: 40), () {
//         if (_remoteUidVN.value == null && _joinedVN.value) {
//           print("⏰ Remote did not join within timeout.");
//         }
//       });
//
//       _initBusy?.complete();
//     } catch (e, st) {
//       print("❌ Exception in init(): $e");
//       print(st);
//       _initBusy?.completeError(e);
//     } finally {
//       _initBusy = null;
//     }
//   }
//
//   @override
//   Future<void> dispose() async {
//     await _ensureLeftAndReleased();
//   }
//
//   // ---------------- UI ----------------
//   @override
//   Widget buildUI(
//       BuildContext context,
//       String peerName, {
//         required VoidCallback onEndCall,
//       }) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF1E1E1E),
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 12),
//             ValueListenableBuilder<int?>(
//               valueListenable: _remoteUidVN,
//               builder: (_, uid, __) {
//                 final waiting = uid == null;
//                 return Text(
//                   waiting ? "Calling" : "Connected",
//                   style: TextStyle(
//                     color: waiting ? Colors.white70 : Colors.greenAccent,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 );
//               },
//             ),
//             const Spacer(),
//             ValueListenableBuilder2<bool, int?>(
//               first: _joinedVN,
//               second: _remoteUidVN,
//               builder: (_, joined, uid) {
//                 final connected = joined && uid != null;
//                 final firstLetter = (peerName.isNotEmpty ? peerName[0].toUpperCase() : "?");
//
//                 return Column(
//                   children: [
//                     // 👇 Yeh jagah pe WavyAvatar lagao
//                     WavyAvatar(name: peerName),
//                     const SizedBox(height: 20),
//                     Text(
//                       connected ? "✅ Connected with $peerName" : "📞 Calling $peerName…",
//                       style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
//                     ),
//                   ],
//                 );
//               },
//             ),
//             const Spacer(),
//             Padding(
//               padding: const EdgeInsets.only(bottom: 36),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//
//                   // Speaker
//                   ValueListenableBuilder<AudioRoute>(
//                     valueListenable: _routeVN,
//                     builder: (_, route, __) {
//                       IconData icon;
//                       switch (route) {
//                         case AudioRoute.bluetooth: icon = Icons.bluetooth_audio; break;
//                         case AudioRoute.speaker:   icon = Icons.volume_up;       break;
//                         case AudioRoute.earpiece:  icon = Icons.phone_in_talk;   break;
//                       }
//                       final isActive = route != AudioRoute.earpiece;
//
//                       return Builder( // 👈 important fix
//                         builder: (buttonContext) {
//                           return _RoundButton(
//                             background: isActive ? Colors.redAccent : const Color(0xFF2C2C2C),
//                             icon: icon,
//                             onPressed: () {
//                               // get position of button correctly
//                               final RenderBox box = buttonContext.findRenderObject() as RenderBox;
//                               final Offset position = box.localToGlobal(Offset.zero);
//                               _showRouteSheet(buttonContext, position);
//                             },
//                           );
//                         },
//                       );
//                     },
//                   ),
//
//
//                   // End
//                   _RoundButton(
//                     big: true,
//                     background: Colors.red,
//                     icon: Icons.call_end,
//                     onPressed: () async {
//                       await CallUtils.endCall(
//                         currentUserId: _isCaller ? _callerId : _receiverId,
//                         otherUserId: _isCaller ? _receiverId : _callerId,
//                         status: "ended",
//                       );
//                       onEndCall();
//                     },
//                   ),
//                   // 3rd button: ROUTE (WhatsApp style)
//                   // Mic
//                   ValueListenableBuilder<bool>(
//                     valueListenable: _mutedVN,
//                     builder: (_, muted, __) {
//                       return _RoundButton(
//                         background: muted ? Colors.redAccent : const Color(0xFF2C2C2C),
//                         icon: muted ? Icons.mic_off : Icons.mic,
//                         onPressed: () async {
//                           if (!_engineInit) return;
//                           final next = !muted;
//                           await _engine.muteLocalAudioStream(next);
//                           _mutedVN.value = next;
//                         },
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Bluetooth , earpiece and speaker code
//   Future<bool> _isBluetoothAvailable() async {
//     try {
//       final ok = await _routeChannel.invokeMethod<bool>('isBtAvailable');
//       return ok ?? false;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   Future<void> _toSpeaker() async {
//     try { await _routeChannel.invokeMethod('toSpeaker'); } catch (_) {}
//     await _engine.setDefaultAudioRouteToSpeakerphone(true);   // <—
//     await _engine.setEnableSpeakerphone(true);
//     await Future.delayed(const Duration(milliseconds: 200));
//     await _syncRouteFromNative();
//   }
//
//   Future<void> _toEarpiece() async {
//     try { await _routeChannel.invokeMethod('toEarpiece'); } catch (_) {}
//     await _engine.setDefaultAudioRouteToSpeakerphone(false);  // <—
//     await _engine.setEnableSpeakerphone(false);
//     await Future.delayed(const Duration(milliseconds: 200));
//     await _syncRouteFromNative();
//   }
//
//   Future<void> _toBluetooth() async {
//     if (!await _isBluetoothAvailable()) {
//       final ctx = navigatorKey.currentContext;
//       if (ctx != null) {
//         ScaffoldMessenger.of(ctx).showSnackBar(
//           const SnackBar(content: Text('No Bluetooth device connected')),
//         );
//       }
//       return;
//     }
//     try { await _routeChannel.invokeMethod('toBluetooth'); } catch (_) {}
//     await _engine.setDefaultAudioRouteToSpeakerphone(false);  // <—
//     await _engine.setEnableSpeakerphone(false);
//     await Future.delayed(const Duration(milliseconds: 300));
//     await _syncRouteFromNative();
//   }
//
//   void _showRouteSheet(BuildContext context, Offset buttonPosition) async {
//     final hasBt = await _isBluetoothAvailable();
//     if (!context.mounted) return;
//
//     // Popup show karo speaker toggle ke thoda upar
//     final overlay = Overlay.of(context);
//     final renderBox = context.findRenderObject() as RenderBox?;
//     final overlaySize = overlay.context.size ?? Size.zero;
//
//     final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
//
//     showDialog(
//       context: context,
//       barrierColor: Colors.transparent,
//       builder: (ctx) {
//         return Stack(
//           children: [
//             GestureDetector(
//               onTap: () => Navigator.pop(ctx), // background tap se dismiss
//             ),
//             Positioned(
//               // toggle button ke thoda upar popup position
//               left: offset.dx + 0,
//               bottom: overlaySize.height - offset.dy + 10,
//               child: Material(
//                 color: Colors.transparent,
//                 child: Container(
//                   width: 220,
//                   padding: const EdgeInsets.symmetric(vertical: 6),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF2C2C2C),
//                     borderRadius: BorderRadius.circular(14),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.3),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       _buildRouteOption(
//                         icon: Icons.bluetooth_audio,
//                         text: "Bluetooth",
//                         enabled: hasBt,
//                         onTap: () async {
//                           Navigator.pop(ctx);
//                           await _toBluetooth();
//                         },
//                         subtitle: hasBt ? null : "No device connected",
//                       ),
//                       _divider(),
//                       _buildRouteOption(
//                         icon: Icons.volume_up,
//                         text: "Speaker",
//                         onTap: () async {
//                           Navigator.pop(ctx);
//                           await _toSpeaker();
//                         },
//                       ),
//                       _divider(),
//                       _buildRouteOption(
//                         icon: Icons.phone_in_talk,
//                         text: "Phone (earpiece)",
//                         onTap: () async {
//                           Navigator.pop(ctx);
//                           await _toEarpiece();
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _divider() => Container(height: 0.4, color: Colors.white12);
//
//   Widget _buildRouteOption({
//     required IconData icon,
//     required String text,
//     String? subtitle,
//     required VoidCallback onTap,
//     bool enabled = true,
//   }) {
//     return InkWell(
//       onTap: enabled ? onTap : null,
//       borderRadius: BorderRadius.circular(10),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         child: Row(
//           children: [
//             Icon(icon, color: enabled ? Colors.white : Colors.white38, size: 24),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     text,
//                     style: TextStyle(
//                       color: enabled ? Colors.white : Colors.white38,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (subtitle != null)
//                     Text(
//                       subtitle,
//                       style: const TextStyle(color: Colors.white54, fontSize: 11),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
// // 👇 helper for better consistent design
//   Widget _buildRouteTile({
//     required IconData icon,
//     required String title,
//     String? subtitle,
//     bool enabled = true,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       contentPadding: const EdgeInsets.symmetric(horizontal: 10),
//       dense: true,
//       leading: Icon(icon, color: enabled ? Colors.white : Colors.white24, size: 26),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: enabled ? Colors.white : Colors.white38,
//           fontSize: 15,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       subtitle: subtitle != null
//           ? Text(
//         subtitle,
//         style: const TextStyle(color: Colors.white38, fontSize: 13),
//       )
//           : null,
//       onTap: enabled ? onTap : null,
//     );
//   }
//
//
//   Future<void> _maybeAutoRouteOnJoin() async {
//     if (await _isBluetoothAvailable()) {
//       await _toBluetooth();
//     } else {
//       await _toEarpiece();
//     }
//   }
//
//
// // add this helper in class AgoraProvider
//   Future<void> _syncRouteFromNative() async {
//     try {
//       final s = await _routeChannel.invokeMethod<String>('currentRoute');
//       switch (s) {
//         case 'bluetooth': _routeVN.value = AudioRoute.bluetooth; break;
//         case 'speaker':   _routeVN.value = AudioRoute.speaker;   break;
//         default:          _routeVN.value = AudioRoute.earpiece;  break;
//       }
//     } catch (_) {}
//   }
// }
//
//
// // ---------- UI helpers ----------
// class _RoundButton extends StatelessWidget {
//   final bool big;
//   final Color background;
//   final IconData icon;
//   final VoidCallback onPressed;
//
//   const _RoundButton({
//     Key? key,
//     this.big = false,
//     required this.background,
//     required this.icon,
//     required this.onPressed,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final double radius = big ? 36 : 28;
//     final double iconSize = big ? 32 : 24;
//
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 150),
//       curve: Curves.easeInOut,
//       width: radius * 2,
//       height: radius * 2,
//       decoration: BoxDecoration(
//         color: background,
//         shape: BoxShape.circle,
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
//       ),
//       child: IconButton(
//         icon: Icon(icon, color: Colors.white, size: iconSize),
//         onPressed: onPressed,
//         splashRadius: radius,
//       ),
//     );
//   }
// }
//
// /// Listen to two ValueNotifiers together.
// class ValueListenableBuilder2<A, B> extends StatelessWidget {
//   final ValueListenable<A> first;
//   final ValueListenable<B> second;
//   final Widget Function(BuildContext, A, B) builder;
//
//   const ValueListenableBuilder2({
//     Key? key,
//     required this.first,
//     required this.second,
//     required this.builder,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<A>(
//       valueListenable: first,
//       builder: (context, a, _) {
//         return ValueListenableBuilder<B>(
//           valueListenable: second,
//           builder: (context, b, __) => builder(context, a, b),
//         );
//       },
//     );
//   }
// }
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



import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // <-- NEW
import '../../Constant/constants.dart';
import '../../app_globals.dart';
import '../screens/WavyCircle.dart';
import 'call_provider.dart';
import 'calutils_helper.dart';


enum AudioRoute { earpiece, speaker, bluetooth }


/// ---- DTO for server token (per-UID) ----
class AgoraTokenResponse {
  final String appId;
  final String channelName;
  final int uid; // >0 => token bound to that uid
  final String role; // "publisher"/"subscriber" (server-defined string is fine)
  final String token;
  final int expireAt;   // epoch seconds
  final int serverTime; // epoch seconds (server clock)

  const AgoraTokenResponse({
    required this.appId,
    required this.channelName,
    required this.uid,
    required this.role,
    required this.token,
    required this.expireAt,
    required this.serverTime,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse('${v ?? 0}') ?? 0;
    }

    return AgoraTokenResponse(
      appId: (j['appId'] ?? '').toString(),
      channelName: (j['channelName'] ?? '').toString(),
      uid: _toInt(j['uid']),
      role: (j['role'] ?? '').toString(),
      token: (j['token'] ?? '').toString(),
      expireAt: _toInt(j['expireAt']),
      serverTime: _toInt(j['serverTime']),
    );
  }
}

class AgoraProvider extends CallProvider {
  late RtcEngine _engine;
  bool _engineInit = false;

  Completer<void>? _initBusy;


  // NEW: current route (UI ke liye)
  final ValueNotifier<AudioRoute> _routeVN = ValueNotifier(AudioRoute.earpiece);

  // NEW: platform channel for BT control (Android/iOS)
  static const MethodChannel _routeChannel = MethodChannel('app.audio.route');


  // --- Call state
  final ValueNotifier<bool> _joinedVN = ValueNotifier(false);
  final ValueNotifier<int?> _remoteUidVN = ValueNotifier(null);

  // --- UI toggles
  final ValueNotifier<bool> _mutedVN = ValueNotifier(false);
  final ValueNotifier<bool> _speakerOnVN = ValueNotifier(false); // default earpiece

  // --- Ringback tone (caller side)
  // Plays a looping "ringing" sound locally while waiting for the remote user to join.
  // Stops automatically when remote audio starts / remote joins.
  AudioPlayer? _ringbackPlayer;
  bool _ringbackPlaying = false;

  // --- meta
  late String _callerId;
  late String _receiverId;
  late bool _isCaller;

  // --- channel state
  String? _currentChannelId;
  bool _inChannel = false;
  int? _localUid;                 // our planned uid (non-zero, stable)
  AgoraTokenResponse? _lastToken; // last token used

  // --- timers
  Timer? _tokenSafetyTimer;    // proactive renewal
  Timer? _connectGuardTimer;   // optional: surface "no answer"

  // ---------- Helpers ----------
  /// Stable, positive 31-bit UID from any string (e.g., your auth user id)
  int _deriveUid(String input) {
    final parsed = int.tryParse(input);
    if (parsed != null && parsed > 0) return parsed;
    int h = 0;
    for (final c in input.codeUnits) {
      h = ((h * 131) + c) & 0x7fffffff;
    }
    return (h == 0) ? 1 : h; // avoid 0; Agora requires >0 for per-uid tokens
  }

  Future<void> _restartRingbackIfPlaying() async {
    if (!_ringbackPlaying) return;
    try {
      await _ringbackPlayer?.stop();
      await _ringbackPlayer?.play(
        AssetSource('audio/ringback.mp3'),
        volume: 1.0,
      );
    } catch (_) {}
  }


  /// Starts a looping ringback tone for the caller while waiting for the other side.
  ///
  /// Requires an asset at: assets/audio/ringback.mp3
  /// (and listed in pubspec.yaml under flutter/assets).
  ///
  // Future<void> _startRingback() async {
  //   if (!_isCaller) return;
  //   if (_ringbackPlaying) return;
  //   _ringbackPlaying = true;
  //
  //   try {
  //     _ringbackPlayer ??= AudioPlayer();
  //     await _ringbackPlayer!.setReleaseMode(ReleaseMode.loop);
  //     await _ringbackPlayer!.play(
  //        AssetSource('audio/ringback.mp3'),
  //       volume: 1.0,
  //     );
  //   } catch (e) {
  //     // If asset/dependency isn't configured, don't crash the call.
  //     _ringbackPlaying = false;
  //     try { SystemSound.play(SystemSoundType.alert); } catch (_) {}
  //     print('⚠️ Ringback start failed: $e');
  //   }
  // }

  Future<void> _startRingback() async {
    if (!_isCaller) return;
    if (_ringbackPlaying) return;
    _ringbackPlaying = true;

    try {
      _ringbackPlayer ??= AudioPlayer();
      await _ringbackPlayer!.setReleaseMode(ReleaseMode.loop);

      await _ringbackPlayer!.play(
        AssetSource('audio/ringback.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      _ringbackPlaying = false;
      try { SystemSound.play(SystemSoundType.alert); } catch (_) {}
      debugPrint('⚠️ Ringback start failed: $e');
    }
  }


  Future<void> _stopRingback() async {
    if (!_ringbackPlaying) return;
    _ringbackPlaying = false;
    try { await _ringbackPlayer?.stop(); } catch (_) {}
  }

  Future<void> _ensureLeftAndReleased() async {
    try {
      if (_engineInit) {
        await _stopRingback();
        try { await _engine.leaveChannel(); } catch (_) {}
        try { await _engine.release(); } catch (_) {}
      }
    } finally {
      _tokenSafetyTimer?.cancel();
      _tokenSafetyTimer = null;
      _connectGuardTimer?.cancel();
      _connectGuardTimer = null;

      _engineInit = false;
      _inChannel = false;
      _currentChannelId = null;
      _localUid = null;
      _lastToken = null;

      _joinedVN.value = false;
      _remoteUidVN.value = null;
      _mutedVN.value = false;
      _speakerOnVN.value = false;
    }
  }

  /// Hit your API to fetch a token **for a specific UID + channel**.
  ///
  /// Backend contract (recommended):
  /// POST /mobile/calls/agora-token
  /// {
  ///   "channelName": "<string>",
  ///   "uid": <int>,               // REQUIRED; > 0
  ///   "ttlSeconds": "3600",       // optional
  ///   "role": "publisher"         // optional; or infer role on server
  /// }
  Future<AgoraTokenResponse> _fetchAgoraToken(
      String channelId, {
        required int uid,
        String ttlSeconds = '3600',
        String role = 'publisher', // broadcaster
      }) async {
    final url = Uri.parse('${BASE_URL}calls/agora-token');

    final headers = <String, String>{ 'Content-Type': 'application/json' };
    try {
      final prefs = await SharedPreferences.getInstance();
      final auth = prefs.getString('auth_token') ?? '';
      if (auth.isNotEmpty) headers['Authorization'] = 'Bearer $auth';
    } catch (_) {}

    final body = jsonEncode({
      'channelName': channelId,
      'uid': uid,             // 👈 send the client uid
      'ttlSeconds': ttlSeconds,
      'role': role,
    });

    final resp = await http.post(url, headers: headers, body: body);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Token API failed (${resp.statusCode}): ${resp.body}');
    }
    final res = AgoraTokenResponse.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    // Safety: server should echo back same uid; warn if mismatch
    if (res.uid != uid) {
      // Not throwing hard, but logging helps diagnose server mismatch.
      print("⚠️ Server returned uid=${res.uid}, but client requested uid=$uid. Verify backend.");
    }
    return res;
  }

  void _scheduleTokenRenewal(AgoraTokenResponse tr, {required int uid}) {
    _tokenSafetyTimer?.cancel();
    if (tr.expireAt <= 0 || tr.serverTime <= 0) return;

    final secondsLeft = tr.expireAt - tr.serverTime;
    // renew ~60 seconds before expiry (min 20s)
    final renewIn = Duration(
      seconds: secondsLeft > 80 ? secondsLeft - 60 : (secondsLeft > 20 ? secondsLeft - 20 : 5),
    );

    _tokenSafetyTimer = Timer(renewIn, () async {
      if (!_engineInit || !_inChannel || _currentChannelId == null || _localUid == null) return;
      try {
        final newTok = await _fetchAgoraToken(_currentChannelId!, uid: uid);
        _lastToken = newTok;
        await _engine.renewToken(newTok.token);
        _scheduleTokenRenewal(newTok, uid: uid);
        print("🔄 Token renewed (uid=$uid)");
      } catch (e) {
        print("⚠️ Token renew failed: $e");
      }
    });
  }

  Future<void> _initEngine(String appId) async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    _engineInit = true;

    try {
      await _engine.setParameters(r'{"che.video.enable":0}');
      await _engine.setLogLevel(LogLevel.logLevelInfo);
    } catch (_) {}

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) async {
          _joinedVN.value = true;
          _inChannel = true;
          _currentChannelId = connection.channelId;


          // Default: earpiece (phone-call style). Toggleavailable in UI.
          try {
            // NEW — normal phone-call jaisa: start on earpiece (speaker OFF)
            await _engine.setDefaultAudioRouteToSpeakerphone(false); // default = earpiece
            await _engine.setEnableSpeakerphone(false);
            await _maybeAutoRouteOnJoin(); // speaker OFF at start
            await _syncRouteFromNative();
            // <-- NEW
          } catch (e) {
            print("⚠️ set audio route failed: $e");
          }
          print("✅ Joined channel ${connection.channelId} as localUid=${connection.localUid} (elapsed=${elapsed}ms)");
          // Caller-side ringback: start after we have joined, until remote joins.
          if (_isCaller && _remoteUidVN.value == null) {
            await _startRingback();
          }
        },

        onUserJoined: (connection, uid, elapsed) {
          print("👋 Remote joined: uid=$uid (${elapsed}ms)");
          _remoteUidVN.value = uid;
          _stopRingback();

        },

        onFirstRemoteAudioFrame: (connection, uid, elapsed) {
          print("🔊 First remote audio from uid=$uid (elapsed=${elapsed}ms)");
          _remoteUidVN.value = uid;
          _stopRingback();

        },

        onRemoteAudioStateChanged: (connection, uid, state, reason, elapsed) {
          print("🎛️ RemoteAudioState uid=$uid state=$state reason=$reason elapsed=$elapsed");
          if (state == RemoteAudioState.remoteAudioStateDecoding) {
            _remoteUidVN.value = uid;
            _stopRingback();

          }
        },

        onUserOffline: (connection, uid, reason) {
          print("👋 Remote offline: uid=$uid reason=$reason");
          _remoteUidVN.value = null;
          // If remote dropped while caller is still in call screen, we can resume ringback.
          if (_isCaller) {
            _startRingback();
          }
        },

        onConnectionStateChanged: (connection, state, reason) async {
          print("🔗 Connection state=$state reason=$reason");
          if (state == ConnectionStateType.connectionStateFailed) {
            // small backoff + retry join with same uid + token
            await Future<void>.delayed(const Duration(seconds: 1));
            if (_lastToken != null && _currentChannelId != null && _localUid != null) {
              try {
                await _engine.joinChannel(
                  token: _lastToken!.token,
                  channelId: _currentChannelId!,
                  uid: _localUid!,
                  options: const ChannelMediaOptions(
                    channelProfile: ChannelProfileType.channelProfileCommunication,
                    clientRoleType: ClientRoleType.clientRoleBroadcaster,
                    autoSubscribeAudio: true,
                    publishMicrophoneTrack: true,
                  ),
                );
              } catch (e) {
                print("❌ Retry join failed: $e");
              }
            }
          }
        },

        onTokenPrivilegeWillExpire: (connection, token) async {
          print("⏳ Token will expire soon; renewing...");
          try {
            if (_currentChannelId != null && _localUid != null) {
              final newTok = await _fetchAgoraToken(_currentChannelId!, uid: _localUid!);
              _lastToken = newTok;
              await _engine.renewToken(newTok.token);
              _scheduleTokenRenewal(newTok, uid: _localUid!);
            }
          } catch (e) {
            print("⚠️ Token renew (willExpire) failed: $e");
          }
        },

        onError: (err, msg) {
          print("❌ Agora error: $err, $msg");
        },

        onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int vad) {
          if (_remoteUidVN.value == null && speakers.isNotEmpty) {
            for (final spk in speakers) {
              if (spk.uid != 0) {
                _remoteUidVN.value = spk.uid;
                break;
              }
            }
          }
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.setAudioScenario(AudioScenarioType.audioScenarioDefault);
    await _engine.enableAudioVolumeIndication(interval: 500, smooth: 3, reportVad: true);
  }

  // ----------------- PUBLIC API -----------------
  @override
  Future<void> init(String channelId, String callerId, String receiverId, bool isCaller) async {
    if (_initBusy != null) return _initBusy!.future;
    _initBusy = Completer<void>();

    _callerId = callerId;
    _receiverId = receiverId;
    _isCaller = isCaller;

    print("🎙️ AgoraProvider.init() channelId=$channelId, isCaller=$isCaller");

    try {
      // 0) Mic permission
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        print("❌ Mic permission denied");
        _initBusy?.complete();
        return;
      }

      // 1) If already in THIS channel, ignore
      if (_engineInit && _inChannel && _currentChannelId == channelId) {
        print("ℹ️ Already in same channel, skip re-init");
        _initBusy?.complete();
        return;
      }

      // 2) If in a different channel, clean exit
      if (_engineInit && _inChannel && _currentChannelId != channelId) {
        print("↩️ Leaving previous channel: $_currentChannelId");
        await _ensureLeftAndReleased();
      }

      // 3) Decide our **own** UID (stable + non-zero)
      //    Caller uses callerId, callee uses receiverId — this makes each device's UID unique & predictable.
      final myUid = _deriveUid(isCaller ? callerId : receiverId);
      _localUid = myUid;

      // 4) Get per-UID token from backend
      final tokenRes = await _fetchAgoraToken(channelId, uid: myUid, ttlSeconds: '3600', role: 'publisher');
      if (tokenRes.appId.isEmpty || tokenRes.token.isEmpty) {
        throw Exception('Invalid token response: appId/token empty');
      }
      _lastToken = tokenRes;
      _scheduleTokenRenewal(tokenRes, uid: myUid);

      // 5) Init engine
      await _initEngine(tokenRes.appId);

      // 6) Join with the **same uid** used to request token
      try {
        await _engine.joinChannel(
          token: tokenRes.token,
          channelId: channelId.trim(),
          uid: myUid,
          options: const ChannelMediaOptions(
            channelProfile: ChannelProfileType.channelProfileCommunication,
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            autoSubscribeAudio: true,
            publishMicrophoneTrack: true,
          ),
        );
      } on AgoraRtcException catch (e) {
        if (e.code == -17) {
          print("⚠️ joinChannel rejected (-17). Already in channel?");
          _inChannel = true;
          _currentChannelId = channelId;
          _joinedVN.value = true;
        } else {
          rethrow;
        }
      }

      print("👉 joinChannel sent: channel=$channelId uid=$myUid");

      // 7) Small guard for "no answer" visibility
      _connectGuardTimer?.cancel();
      _connectGuardTimer = Timer(const Duration(seconds: 40), () {
        if (_remoteUidVN.value == null && _joinedVN.value) {
          print("⏰ Remote did not join within timeout.");
        }
      });

      _initBusy?.complete();
    } catch (e, st) {
      print("❌ Exception in init(): $e");
      print(st);
      _initBusy?.completeError(e);
    } finally {
      _initBusy = null;
    }
  }

  @override
  Future<void> dispose() async {
    await _ensureLeftAndReleased();
  }

  // ---------------- UI ----------------
  @override
  Widget buildUI(
      BuildContext context,
      String peerName, {
        required VoidCallback onEndCall,
      }) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            ValueListenableBuilder<int?>(
              valueListenable: _remoteUidVN,
              builder: (_, uid, __) {
                final waiting = uid == null;
                return Text(
                  waiting ? "Calling" : "Connected",
                  style: TextStyle(
                    color: waiting ? Colors.white70 : Colors.greenAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
            const Spacer(),
            ValueListenableBuilder2<bool, int?>(
              first: _joinedVN,
              second: _remoteUidVN,
              builder: (_, joined, uid) {
                final connected = joined && uid != null;
                final firstLetter = (peerName.isNotEmpty ? peerName[0].toUpperCase() : "?");

                return Column(
                  children: [
                    // 👇 Yeh jagah pe WavyAvatar lagao
                    WavyAvatar(name: peerName),
                    const SizedBox(height: 20),
                    Text(
                      connected ? "✅ Connected with $peerName" : "📞 Calling $peerName…",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  // Speaker
                  ValueListenableBuilder<AudioRoute>(
                    valueListenable: _routeVN,
                    builder: (_, route, __) {
                      IconData icon;
                      switch (route) {
                        case AudioRoute.bluetooth: icon = Icons.bluetooth_audio; break;
                        case AudioRoute.speaker:   icon = Icons.volume_up;       break;
                        case AudioRoute.earpiece:  icon = Icons.phone_in_talk;   break;
                      }
                      final isActive = route != AudioRoute.earpiece;

                      return Builder( // 👈 important fix
                        builder: (buttonContext) {
                          return _RoundButton(
                            background: isActive ? Colors.redAccent : const Color(0xFF2C2C2C),
                            icon: icon,
                            onPressed: () {
                              // get position of button correctly
                              final RenderBox box = buttonContext.findRenderObject() as RenderBox;
                              final Offset position = box.localToGlobal(Offset.zero);
                              _showRouteSheet(buttonContext, position);
                            },
                          );
                        },
                      );
                    },
                  ),


                  // End
                  _RoundButton(
                    big: true,
                    background: Colors.red,
                    icon: Icons.call_end,
                    onPressed: () async {
                      await CallUtils.endCall(
                        currentUserId: _isCaller ? _callerId : _receiverId,
                        otherUserId: _isCaller ? _receiverId : _callerId,
                        status: "ended",
                      );
                      onEndCall();
                    },
                  ),
                  // 3rd button: ROUTE (WhatsApp style)
                  // Mic
                  ValueListenableBuilder<bool>(
                    valueListenable: _mutedVN,
                    builder: (_, muted, __) {
                      return _RoundButton(
                        background: muted ? Colors.redAccent : const Color(0xFF2C2C2C),
                        icon: muted ? Icons.mic_off : Icons.mic,
                        onPressed: () async {
                          if (!_engineInit) return;
                          final next = !muted;
                          await _engine.muteLocalAudioStream(next);
                          _mutedVN.value = next;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bluetooth , earpiece and speaker code
  Future<bool> _isBluetoothAvailable() async {
    try {
      final ok = await _routeChannel.invokeMethod<bool>('isBtAvailable');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _toSpeaker() async {
    try { await _routeChannel.invokeMethod('toSpeaker'); } catch (_) {}
    await _engine.setDefaultAudioRouteToSpeakerphone(true);   // <—
    await _engine.setEnableSpeakerphone(true);
    await Future.delayed(const Duration(milliseconds: 200));
    await _syncRouteFromNative();
    await _restartRingbackIfPlaying();


  }

  Future<void> _toEarpiece() async {
    try { await _routeChannel.invokeMethod('toEarpiece'); } catch (_) {}
    await _engine.setDefaultAudioRouteToSpeakerphone(false);  // <—
    await _engine.setEnableSpeakerphone(false);
    await Future.delayed(const Duration(milliseconds: 200));
    await _syncRouteFromNative();
    await _restartRingbackIfPlaying();

  }

  Future<void> _toBluetooth() async {
    if (!await _isBluetoothAvailable()) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('No Bluetooth device connected')),
        );
      }
      return;
    }
    try { await _routeChannel.invokeMethod('toBluetooth'); } catch (_) {}
    await _engine.setDefaultAudioRouteToSpeakerphone(false);  // <—
    await _engine.setEnableSpeakerphone(false);
    await Future.delayed(const Duration(milliseconds: 300));
    await _syncRouteFromNative();
    await _restartRingbackIfPlaying();

  }

  void _showRouteSheet(BuildContext context, Offset buttonPosition) async {
    final hasBt = await _isBluetoothAvailable();
    if (!context.mounted) return;

    // Popup show karo speaker toggle ke thoda upar
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlaySize = overlay.context.size ?? Size.zero;

    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx), // background tap se dismiss
            ),
            Positioned(
              // toggle button ke thoda upar popup position
              left: offset.dx + 0,
              bottom: overlaySize.height - offset.dy + 10,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRouteOption(
                        icon: Icons.bluetooth_audio,
                        text: "Bluetooth",
                        enabled: hasBt,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _toBluetooth();
                        },
                        subtitle: hasBt ? null : "No device connected",
                      ),
                      _divider(),
                      _buildRouteOption(
                        icon: Icons.volume_up,
                        text: "Speaker",
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _toSpeaker();
                        },
                      ),
                      _divider(),
                      _buildRouteOption(
                        icon: Icons.phone_in_talk,
                        text: "Phone (earpiece)",
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _toEarpiece();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _divider() => Container(height: 0.4, color: Colors.white12);

  Widget _buildRouteOption({
    required IconData icon,
    required String text,
    String? subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: enabled ? Colors.white : Colors.white38, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.white38,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// 👇 helper for better consistent design
  Widget _buildRouteTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      dense: true,
      leading: Icon(icon, color: enabled ? Colors.white : Colors.white24, size: 26),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white38,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      )
          : null,
      onTap: enabled ? onTap : null,
    );
  }


  Future<void> _maybeAutoRouteOnJoin() async {
    if (await _isBluetoothAvailable()) {
      await _toBluetooth();
    } else {
      await _toEarpiece();
    }
  }


// add this helper in class AgoraProvider
  Future<void> _syncRouteFromNative() async {
    try {
      final s = await _routeChannel.invokeMethod<String>('currentRoute');
      switch (s) {
        case 'bluetooth': _routeVN.value = AudioRoute.bluetooth; break;
        case 'speaker':   _routeVN.value = AudioRoute.speaker;   break;
        default:          _routeVN.value = AudioRoute.earpiece;  break;
      }
    } catch (_) {}
  }
}


// ---------- UI helpers ----------
class _RoundButton extends StatelessWidget {
  final bool big;
  final Color background;
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundButton({
    Key? key,
    this.big = false,
    required this.background,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double radius = big ? 36 : 28;
    final double iconSize = big ? 32 : 24;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: iconSize),
        onPressed: onPressed,
        splashRadius: radius,
      ),
    );
  }
}

/// Listen to two ValueNotifiers together.
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B) builder;

  const ValueListenableBuilder2({
    Key? key,
    required this.first,
    required this.second,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, __) => builder(context, a, b),
        );
      },
    );
  }
}










