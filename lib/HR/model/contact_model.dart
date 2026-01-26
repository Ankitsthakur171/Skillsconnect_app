// class Contact {
//   final String name;
//   final String location;
//   final String time;
//   final String role;
//   final String imageUrl;
//
//   Contact({
//     required this.name,
//     required this.location,
//     required this.time,
//     required this.role,
//     required this.imageUrl,
//   });
// }



import 'package:intl/intl.dart';

class Contact {
  final String id;
  final int callerId;
  final String callerName;
  final int calleeId;
  final String calleeName;
  final String channelId;
  final String status;
  final DateTime initiatedAt;
  final int durationSec;
  final DateTime createdAt;
  final String callType;
  final String calleeBelonging;
  final String callerBelonging;

  Contact({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.calleeId,
    required this.calleeName,
    required this.channelId,
    required this.status,
    required this.initiatedAt,
    required this.durationSec,
    required this.createdAt,
    required this.callType,
    required this.calleeBelonging,
    required this.callerBelonging,

  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['_id'] ?? '',
      callerId: json['callerId'] ?? 0,
      callerName: json['callerName'] ?? '',
      calleeId: json['calleeId'] ?? 0,
      calleeName: json['calleeName'] ?? '',
      channelId: json['channelId'] ?? '',
      status: json['status'] ?? '',
      initiatedAt: DateTime.parse(json['initiatedAt']),
      durationSec: json['durationSec'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      callType: json['callType'] ?? '',
      calleeBelonging: json['calleeBelonging'] ?? 'College name',
      callerBelonging: json['callerBelonging'] ?? 'College name',

    );
  }

  /// 👇 yeh method readable date/time return karega
  String get formattedInitiatedAt {
    return DateFormat('dd MMM yyyy, hh:mm a').format(initiatedAt.toLocal());
  }

  String get formattedCreatedAt {
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal());
  }
}
