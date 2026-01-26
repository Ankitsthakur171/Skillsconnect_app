import 'package:cloud_firestore/cloud_firestore.dart';

class CallUtils {
  static Future<void> endCall({
    required String currentUserId, // jisne cut/reject kiya
    required String otherUserId,   // dusra banda
    String status = "ended",       // default ended, lekin reject bhi bhej sakte ho
  }) async {
    final db = FirebaseFirestore.instance;

    // Dono user ke docs update
    await db.collection("calls").doc(currentUserId).update({
      "status": status,
      "isCalling": false,
    });

    await db.collection("calls").doc(otherUserId).update({
      "status": status,
      "isCalling": false,
    });
  }
}
