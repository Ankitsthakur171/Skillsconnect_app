import 'dart:convert';
import 'package:intl/intl.dart';

class ModeratorModel {
  final String platform;
  final String meetingName;
  final int? jobId;
  final int? meetingId;
  final String? isAttended;
  final String? isSeen;
  final int? meetingAttendesId;
  final String? userAccess;
  final int? userId;
  final String? fullName;

  ModeratorModel({
    required this.platform,
    required this.meetingName,
    this.jobId,
    this.meetingId,
    this.isAttended,
    this.isSeen,
    this.meetingAttendesId,
    this.userAccess,
    this.userId,
    this.fullName,
  });

  factory ModeratorModel.fromJson(Map<String, dynamic> json) {
    return ModeratorModel(
      platform: json['platform']?.toString() ?? '',
      meetingName: json['meeting_name']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      jobId: json['job_id'] is int
          ? json['job_id'] as int
          : int.tryParse('${json['job_id'] ?? ''}'),
      meetingId: json['meeting_id'] is int
          ? json['meeting_id'] as int
          : int.tryParse('${json['meeting_id'] ?? ''}'),
      isAttended: json['is_attended']?.toString(),
      isSeen: json['is_seen']?.toString(),
      meetingAttendesId: json['meeting_attendes_id'] is int
          ? json['meeting_attendes_id'] as int
          : int.tryParse('${json['meeting_attendes_id'] ?? ''}'),
      userAccess: json['user_access']?.toString(),
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse('${json['user_id'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'meeting_name': meetingName,
    'full_name': fullName,
    'job_id': jobId,
    'meeting_id': meetingId,
    'is_attended': isAttended,
    'is_seen': isSeen,
    'meeting_attendes_id': meetingAttendesId,
    'user_access': userAccess,
    'user_id': userId,
  };
}

class InterviewModel {
  final String jobTitle;
  final String company;
  final String date;
  final String startTime;
  final String endTime;
  final List<ModeratorModel> moderator;
  final String meetingMode;
  final bool isActive;

  final String? meetingLink;
  final String? meetingMapLink;
  final String? meetingAddress;
  final String? contactPerson;

  InterviewModel({
    required this.jobTitle,
    required this.company,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.moderator,
    required this.meetingMode,
    required this.isActive,

    // NEW
    this.meetingLink,
    this.meetingMapLink,
    this.meetingAddress,
    this.contactPerson,
  });

  factory InterviewModel.fromJson(Map<String, dynamic> json) {
    String formattedDate = '';
    final rawIso = (json['interview_date'] ?? '').toString();
    if (rawIso.isNotEmpty) {
      try {
        final utc = DateTime.parse(rawIso);
        final local = utc.toLocal();
        formattedDate = DateFormat('dd MMM yyyy').format(local);
      } catch (_) {
        formattedDate = rawIso.contains('T') ? rawIso.split('T')[0] : rawIso;
      }
    }

    String _formatTime(String raw) {
      raw = (raw ?? '').toString();
      if (raw.isEmpty) return '';
      try {
        final dt = DateFormat('HH:mm').parse(raw);
        return DateFormat('hh:mm a').format(dt);
      } catch (_) {
        return raw;
      }
    }

    final start = _formatTime(json['start_time']?.toString() ?? '');
    final end   = _formatTime(json['end_time']?.toString() ?? '');

    final jobTitle = (json['interview_name'] ?? json['job_title'] ?? '').toString();
    final company  = (json['company_name'] ?? json['company'] ?? '').toString();

    List<ModeratorModel> moderators = [];
    final rawModerator = json['moderator'];
    try {
      if (rawModerator is List) {
        moderators = rawModerator
            .whereType<Map<String, dynamic>>()
            .map((m) => ModeratorModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      } else if (rawModerator is Map) {
        moderators = [ModeratorModel.fromJson(Map<String, dynamic>.from(rawModerator))];
      } else if (rawModerator is String) {
        try {
          final parsed = jsonDecode(rawModerator);
          if (parsed is List) {
            moderators = parsed
                .whereType<Map<String, dynamic>>()
                .map((m) => ModeratorModel.fromJson(Map<String, dynamic>.from(m)))
                .toList();
          } else if (parsed is Map) {
            moderators = [ModeratorModel.fromJson(Map<String, dynamic>.from(parsed))];
          }
        } catch (_) {}
      }
    } catch (_) {}

    return InterviewModel(
      jobTitle: jobTitle,
      company: company,
      date: formattedDate,
      startTime: start,
      endTime: end,
      moderator: moderators,
      meetingMode: json['meeting_mode']?.toString() ?? '',
      isActive: (json['status']?.toString() ?? '').toLowerCase() == 'active',

      meetingLink: (json['meeting_link'] ?? '').toString().isNotEmpty
          ? json['meeting_link'].toString()
          : null,
      meetingMapLink: (json['meeting_map_link'] ?? '').toString().isNotEmpty
          ? json['meeting_map_link'].toString()
          : null,
      meetingAddress: (json['meeting_address'] ?? '').toString().isNotEmpty
          ? json['meeting_address'].toString()
          : null,
      contactPerson: (json['contact_person'] ?? '').toString().isNotEmpty
          ? json['contact_person'].toString()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'interview_name': jobTitle,
    'company_name': company,
    'interview_date': date,
    'start_time': startTime,
    'end_time': endTime,
    'moderator': moderator.map((m) => m.toJson()).toList(),
    'meeting_mode': meetingMode,
    'status': isActive ? 'Active' : 'Inactive',

    'meeting_link': meetingLink,
    'meeting_map_link': meetingMapLink,
    'meeting_address': meetingAddress,
    'contact_person': contactPerson,
  };

  @override
  String toString() =>
      'Interview(jobTitle: $jobTitle, date: $date, start: $startTime, moderators: ${moderator.length})';
}

