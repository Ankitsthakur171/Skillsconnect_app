// call_provider.dart
import 'package:flutter/material.dart';

abstract class CallProvider {
  Future<void> init(String channelId, String callerId, String receiverId, bool isCaller);
  Future<void> dispose();
  Widget buildUI(BuildContext context, String peerName, {required VoidCallback onEndCall});
}
