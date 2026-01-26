
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Constant/constants.dart';
import '../../model/interview_bottom.dart';
import 'interviewtab_event.dart';
import 'interviewtab_state.dart';


class DiscussionBloc extends Bloc<DiscussionEvent, DiscussionState> {
  DiscussionBloc() : super(DiscussionInitial()) {
    on<LoadDiscussions>(_onLoadDiscussions);
    on<TabDeleteMeetingEvent>(_onDeleteMeeting);
    on<DeleteAttendeeEvent>(_onDeleteAttendee);
  }

  // 👇 keep track of the most recent jobId so refreshes reuse it
  String? _currentJobId;

  /// 🔵 Load Discussions (Meetings List)
  Future<void> _onLoadDiscussions(
      LoadDiscussions event, Emitter<DiscussionState> emit) async {
    emit(DiscussionLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        emit(DiscussionError('Token not found'));
        return;
      }

      // remember the jobId if one was passed
      _currentJobId = event.jobId ?? _currentJobId;

      final url = Uri.parse(
          '${BASE_URL}interview-room/list');

      // ✅ job_id is now dynamic; ✅ from is hard-set to "JobDashboard"
      final body = {
        "job_id": _currentJobId ?? "",
        "from_date": "",
        "to_date": "",
        "from": "JobDashboard",
        "interviewTitle": "",
        "sort": ""
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true && data['scheduled_meeting_list'] != null) {
        final List<dynamic> list = data['scheduled_meeting_list'];
        final discussions = list
            .map<ScheduledMeeting>((json) => ScheduledMeeting.fromJson(json))
            .toList();

        emit(DiscussionLoaded(discussions));
      } else {
        emit(DiscussionError(data['msg'] ?? 'No data found'));
      }
    } catch (e) {
      emit(DiscussionError('Failed to fetch discussions: $e'));
    }
  }

  /// 🔴 Delete Meeting Handler
  Future<void> _onDeleteMeeting(
      TabDeleteMeetingEvent event, Emitter<DiscussionState> emit) async {
    emit(MeetingDeleting());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        emit(DiscussionError("Token missing"));
        return;
      }

      final url = Uri.parse(
          "${BASE_URL}interview-room/remove");

      final body = {
        "meeting_id": event.meetingId,
        "whom": "meeting",
        "reason": event.reason,
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        emit(MeetingDeleted("Meeting deleted successfully"));
        // 👇 reload with the last-used jobId
        add(LoadDiscussions(jobId: _currentJobId));
      } else {
        emit(DiscussionError("Failed: ${response.body}"));
      }
    } catch (e) {
      emit(DiscussionError("Error: $e"));
    }
  }

  /// 🟠 Delete Attendee Handler
  Future<void> _onDeleteAttendee(
      DeleteAttendeeEvent event, Emitter<DiscussionState> emit) async {
    emit(AttendeeDeleting());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        emit(DiscussionError("Token missing"));
        return;
      }

      final url = Uri.parse(
          "${BASE_URL}interview-room/remove");

      final body = {
        "meeting_id": event.meetingId,
        "user_id": event.userId,
        "reason": event.reason,
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        emit(AttendeeDeleted("Participant removed successfully"));
        // 👇 reload with the last-used jobId
        add(LoadDiscussions(jobId: _currentJobId));
      } else {
        emit(DiscussionError("Failed: ${response.body}"));
      }
    } catch (e) {
      emit(DiscussionError("Error: $e"));
    }
  }
}
