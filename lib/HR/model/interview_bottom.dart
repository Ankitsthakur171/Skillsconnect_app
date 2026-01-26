
import 'dart:convert';

import 'package:intl/intl.dart';

/// ---- Attendee ----
class Attendee {
  final String platform;
  final String meetingName;
  final int? jobId;
  final int meetingId;
  final String isAttended;
  final String isSeen;
  final int sendNotificationCount;
  final int meetingAttendeesId;
  final String userAccess;
  final int userId;
  final String fullName;
  final String email;
  final int userType;
  final int? masterCollegeId;
  final int? applicationId;
  final String? collegeName;
  final int? collegeId;
  final String rolesName;
  final int? applicantApplicationId;
    String? applicationStatusName;
  final String? applicationStatusNameColor;
  final String? applicationStatusTextColor;

  Attendee({
    required this.platform,
    required this.meetingName,
    this.jobId,
    required this.meetingId,
    required this.isAttended,
    required this.isSeen,
    required this.sendNotificationCount,
    required this.meetingAttendeesId,
    required this.userAccess,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.userType,
    this.masterCollegeId,
    this.applicationId,
    this.collegeName,
    this.collegeId,
    required this.rolesName,
    this.applicantApplicationId,
    this.applicationStatusName,
    this.applicationStatusNameColor,
    this.applicationStatusTextColor,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      platform: json['platform'] ?? "",
      meetingName: json['meeting_name'] ?? "",
      jobId: json['job_id'],
      meetingId: json['meeting_id'] ?? 0,
      isAttended: json['is_attended'] ?? "",
      isSeen: json['is_seen'] ?? "",
      sendNotificationCount: json['send_notification_count'] ?? 0,
      meetingAttendeesId: json['meeting_attendes_id'] ?? 0,
      userAccess: json['user_access'] ?? "",
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? "",
      email: json['email'] ?? "",
      userType: json['user_type'] ?? 0,
      masterCollegeId: json['master_college_id'],
      applicationId: json['application_id'],
      collegeName: json['college_name'],
      collegeId: json['college_id'],
      rolesName: json['roles_name'] ?? "",
      applicantApplicationId: json['applicant_application_id'],
      applicationStatusName: json['application_status_name'],
      applicationStatusNameColor: json['application_status_name_color'],
      applicationStatusTextColor: json['application_status_text_color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "platform": platform,
      "meeting_name": meetingName,
      "job_id": jobId,
      "meeting_id": meetingId,
      "is_attended": isAttended,
      "is_seen": isSeen,
      "send_notification_count": sendNotificationCount,
      "meeting_attendes_id": meetingAttendeesId,
      "user_access": userAccess,
      "user_id": userId,
      "full_name": fullName,
      "email": email,
      "user_type": userType,
      "master_college_id": masterCollegeId,
      "application_id": applicationId,
      "college_name": collegeName,
      "college_id": collegeId,
      "roles_name": rolesName,
      "applicant_application_id": applicantApplicationId,
      "application_status_name": applicationStatusName,
      "application_status_name_color": applicationStatusNameColor,
      "application_status_text_color": applicationStatusTextColor,
    };
  }
}

/// ---- ScheduledMeeting ----
class ScheduledMeeting {
  final int id;
  final int? jobId;
  final int? processId;
  final String platform;
  final String meetingType;
  final String? meetingLink;
  final String interviewName;
  final String interviewDate;
  final String startTime;
  final String endTime;
  final String? meetingMode;
  final String? meetingAddress;
  final String? meetingmaplink;
  final String? contactPerson;
  final String status;
  final String isDeleted;
  final String? email;
  final int userType;
  final String jobTitle;
  final String companyName;
  final String companyLogo;
  final String? moderatoremail;
  final int liveattendee;



  final List<Attendee> students;
  final List<Attendee> allAttendees;
  final List<Attendee> moderators;

  /// 👇 counts
  int get studentCount => students.length;
  int get attendeeCount => allAttendees.length;

  String get formattedStartTime => _formatTime(startTime);
  String get formattedEndTime => _formatTime(endTime);

  // 👇 formatted date getter
  String get formattedInterviewDate {
    try {
      final dateTime = DateTime.parse(interviewDate);
      final day = dateTime.day;
      final suffix = _getDaySuffix(day);
      final formatted =
      DateFormat("MMM, yyyy").format(dateTime); // Sep, 2025
      return "$day$suffix $formatted"; // e.g. 9th Sep, 2025
    } catch (e) {
      return interviewDate; // fallback if parsing fails
    }
  }

  ScheduledMeeting({
    required this.id,
    this.jobId,
    this.processId,
    required this.platform,
    required this.meetingType,
    this.meetingLink,
    required this.interviewName,
    required this.interviewDate,
    required this.startTime,
    required this.endTime,
    this.meetingMode,
    this.meetingAddress,
    this.meetingmaplink,
    this.contactPerson,
    required this.status,
    required this.isDeleted,
    this.email,
    required this.userType,
    required this.jobTitle,
    required this.companyName,
    required this.companyLogo,
    required this.moderatoremail,
    required this.students,
    required this.allAttendees,
    required this.moderators,
    required this.liveattendee
  });

  factory ScheduledMeeting.fromJson(Map<String, dynamic> json) {
    return ScheduledMeeting(
      id: json['id'] ?? 0,
      jobId: json['job_id'],
      processId: json['process_id'],
      platform: json['platform'] ?? "",
      meetingType: json['meeting_type'] ?? "",
      meetingLink: json['meeting_link'],
      interviewName: json['interview_name'] ?? "",
      interviewDate: json['interview_date'] ?? "",
      startTime: json['start_time'] ?? "",
      endTime: json['end_time'] ?? "",
      meetingMode: json['meeting_mode'],
      meetingAddress: json['meeting_address'],
      meetingmaplink: json['meeting_map_link'],
      contactPerson: json['contact_person'],
      status: json['status'] ?? "",
      isDeleted: json['is_deleted'] ?? "",
      email: json['email'],
      userType: json['user_type'] ?? 0,
      jobTitle: json['job_title'] ?? "",
      companyName: json['company_name'] ?? "",
      companyLogo: json['company_logo'] ?? "",
      moderatoremail: json['moderator_email'],
      liveattendee: json['liveAttendees'] ?? 0,
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) => Attendee.fromJson(e))
          .toList(),
      allAttendees: (json['allAttendees'] as List<dynamic>? ?? [])
          .map((e) => Attendee.fromJson(e))
          .toList(),
      moderators: (json['moderator'] as List<dynamic>? ?? [])
          .map((e) => Attendee.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "job_id": jobId,
      "process_id": processId,
      "platform": platform,
      "meeting_type": meetingType,
      "meeting_link": meetingLink,
      "interview_name": interviewName,
      "interview_date": interviewDate,
      "start_time": startTime,
      "end_time": endTime,
      "meeting_mode": meetingMode,
      "meeting_address": meetingAddress,
      "contact_person": contactPerson,
      "status": status,
      "is_deleted": isDeleted,
      "email": email,
      "user_type": userType,
      "job_title": jobTitle,
      "company_name": companyName,
      "company_logo": companyLogo,
      "moderator_email":moderatoremail,
      "liveAttendees":liveattendee,
      "students": students.map((e) => e.toJson()).toList(),
      "allAttendees": allAttendees.map((e) => e.toJson()).toList(),
      "moderator": moderators.map((e) => e.toJson()).toList(),
      // 👇 send counts too
      "student_count": studentCount,
      "attendee_count": attendeeCount,
    };
  }

  /// helper function for suffix (st, nd, rd, th)
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return "th";
    }
    switch (day % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }

  /// Helper function
  String _formatTime(String time24) {
    try {
      final parsedTime = DateFormat("HH:mm").parse(time24); // 24-hour input
      return DateFormat("hh:mm a").format(parsedTime); // 12-hour output
    } catch (e) {
      return time24; // fallback agar parse fail ho
    }
  }}

/// ---- Response Wrapper ----
class ScheduledMeetingResponse {
  final bool status;
  final String msg;
  final List<ScheduledMeeting> scheduledMeetings;

  ScheduledMeetingResponse({
    required this.status,
    required this.msg,
    required this.scheduledMeetings,
  });

  factory ScheduledMeetingResponse.fromJson(Map<String, dynamic> json) {
    return ScheduledMeetingResponse(
      status: json['status'] ?? false,
      msg: json['msg'] ?? "",
      scheduledMeetings: (json['scheduled_meeting_list'] as List<dynamic>? ?? [])
          .map((e) => ScheduledMeeting.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "msg": msg,
      "scheduled_meeting_list":
      scheduledMeetings.map((e) => e.toJson()).toList(),
    };
  }
}

