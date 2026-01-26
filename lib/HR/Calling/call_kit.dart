// import 'package:flutter_callkit_incoming/entities/android_params.dart';
// import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
//
// class CallkitService {
//   static Future<void> showIncomingCall(Map<String, dynamic> data) async {
//
//     final String callId =
//     (data['callId'] ?? data['channelid'] ?? data['channel'] ??
//         DateTime.now().millisecondsSinceEpoch).toString();
//
//
//     final params = CallKitParams(
//       id: callId,
//       nameCaller: (data['callerName'] ?? 'Incoming call').toString(),
//       appName: 'SkillsConnect',
//       avatar: (data['avatar'] ?? '').toString(),
//       handle: (data['handle'] ?? '').toString(),
//       type: (data['isVideo'] == true) ? 1 : 0, // 0=audio, 1=video
//       duration: 30000,
//       textAccept: 'Accept',
//       textDecline: 'Reject',
//       extra: Map<String, dynamic>.from(data),
//       android: AndroidParams(
//         isCustomNotification: true,
//         isShowLogo: false,
//         ringtonePath: 'system_ringtone_default',
//         backgroundColor: '#2C2C2C',
//         actionColor: '#FFFFFF',
//         incomingCallNotificationChannelName: 'Incoming Calls',
//         missedCallNotificationChannelName: 'Missed Calls',
//         isShowCallID: true,
//       ),
//     );
//
//     // Android 14+ (optional but helpful)
//     // final ok = await FlutterCallkitIncoming.canUseFullScreenIntent();
//     // if (!ok) await FlutterCallkitIncoming.requestFullIntentPermission();
//
//     await FlutterCallkitIncoming.showCallkitIncoming(params);
//   }
//
//   static Future<void> setConnected(String id) async {
//     await FlutterCallkitIncoming.setCallConnected(id);
//   }
//
//   static Future<void> end(String id) async {
//     await FlutterCallkitIncoming.endCall(id);
//   }
// }






// call_kit.dart (ya jahan tumhara CallkitService hai)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class CallkitService {
  static Future<void> showIncomingCall(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // current logged-in user ko receiverId ki tarah set karo (safety)
    final selfId = (prefs.getString('user_id') ?? '').trim();

    final String callId =
    (data['callId'] ?? data['channelid'] ?? data['channel'] ?? DateTime.now().millisecondsSinceEpoch)
        .toString();

    // --- Normalize once ---
    final normalized = <String, dynamic>{
      'callId': callId,
      'channel': (data['channel'] ?? data['channelid'] ?? callId).toString(),
      'receiverId': (data['receiverId'] ?? selfId).toString(),
      'callerId': (data['callerId'] ?? data['from_user_id'] ?? data['from'] ?? data['handle'] ?? '').toString(),
      'callerName': (data['callerName'] ?? data['title'] ?? 'Caller').toString(),
      'isVideo': data['isVideo'] == true,
      // jo bhi aur fields chaho
    };

    // ❗ assert: callerId required
    // agar abhi bhi empty hai to best effort (mat block karo, but log karo)
    if ((normalized['callerId'] as String).isEmpty) {
      // optional: server payload/Firestore fix required
      // filhal handle fallback me bhi set kar denge
      normalized['callerId'] = (data['handle'] ?? '').toString();
    }

    // --- Persist backup for native (used by Kotlin on ACCEPT) ---
    await prefs.setString('last_callkit_extra', jsonEncode(normalized));


    // ✅ convert Flutter Color -> hex string (e.g. Colors.red.shade600 → "#E53935")
    String _toHex(Color c) => '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

    // --- Build CallKit params ---
    final params = CallKitParams(
      id: normalized['callId'] as String,
      nameCaller: normalized['callerName'] as String,
      appName: 'SkillsConnect',
      avatar: (data['avatar'] ?? '').toString(),
      // ✅ handle me wahi callerId bhejo
      handle: (normalized['callerId'] as String),
      type: (normalized['isVideo'] == true) ? 1 : 0, // 0=audio, 1=video
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Reject',
      extra: Map<String, dynamic>.from(normalized),
      android:  AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        // custom full-screen UI colors
        backgroundColor: _toHex(Colors.teal.shade900,), // deep navy/Dark
        actionColor: _toHex(Colors.red.shade600),      // 🔹 red action tint
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
        isShowCallID: false,
      ),
      // ✅ iOS look (clean + hide handle)
      ios: IOSParams(
        handleType: '',              // hide phone number/ID
        supportsVideo: true,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        ringtonePath: 'system_ringtone_default',
        iconName: 'AppIcon',         // app icon name from iOS bundle
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static Future<void> setConnected(String id) async {
    await FlutterCallkitIncoming.setCallConnected(id);
  }

  static Future<void> end(String id) async {
    await FlutterCallkitIncoming.endCall(id);
  }
}
