// import 'dart:convert';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../model/interview_bottom.dart';
// import 'interviewtab_state.dart';
// import 'interviewtab_event.dart';
//
// class DiscussionBloc extends Bloc<DiscussionEvent, DiscussionState> {
//   DiscussionBloc() : super(DiscussionInitial()) {
//     on<LoadDiscussions>(_onLoadDiscussions);
//     on<DeleteMeetingEvent>(_onDeleteMeeting);
//     on<DeleteAttendeeEvent>(_onDeleteAttendee);
//
//
//   }
//
//   Future<void> _onLoadDiscussions(
//       LoadDiscussions event, Emitter<DiscussionState> emit) async {
//     emit(DiscussionLoading());
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');
//
//       if (token == null || token.isEmpty) {
//         emit(DiscussionError('Token not found'));
//         return;
//       }
//
//       final url = Uri.parse('https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/interview-room/list');
//
//       final body = {
//         "job_id": "",
//         "from_date": "",
//         "to_date": "",
//         "from": "",
//         "interviewTitle": "",
//         "sort": ""
//       };
//
//       final response = await http.post(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(body),
//       );
//
//       final data = jsonDecode(response.body);
//
//       if (data['status'] == true && data['scheduled_meeting_list'] != null) {
//         final List<dynamic> list = data['scheduled_meeting_list'];
//         final discussions = list
//             .map<ScheduledMeeting>((json) => ScheduledMeeting.fromJson(json))
//             .toList();
//
//         emit(DiscussionLoaded(discussions));
//       } else {
//         emit(DiscussionError(data['msg'] ?? 'No data found'));
//       }
//     } catch (e) {
//       emit(DiscussionError('Failed to fetch discussions: $e'));
//     }
//   }
//
//   // 🔴 Delete Meeting Handler
//   Future<void> _onDeleteMeeting(
//       DeleteMeetingEvent event, Emitter<DiscussionState> emit) async {
//     emit(MeetingDeleting());
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("auth_token");
//
//       if (token == null) {
//         emit(DiscussionError("Token missing"));
//         return;
//       }
//
//       final url = Uri.parse(
//           "https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/interview-room/remove");
//
//       final response = await http.post(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode({
//           "meeting_id": event.meetingId,
//           "whom": "meeting",
//           "reason": event.reason,
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         emit(MeetingDeleted("Meeting deleted successfully"));
//         add(LoadDiscussions()); // reload list
//       } else {
//         emit(DiscussionError("Failed: ${response.body}"));
//       }
//     } catch (e) {
//       emit(DiscussionError("Error: $e"));
//     }
//   }
//
//
//   Future<void> _onDeleteAttendee(
//       DeleteAttendeeEvent event, Emitter<DiscussionState> emit) async {
//     emit(AttendeeDeleting());
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("auth_token");
//
//       if (token == null) {
//         emit(DiscussionError("Token missing"));
//         return;
//       }
//
//       final url = Uri.parse(
//           "https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/interview-room/remove");
//
//       final response = await http.post(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode({
//           "meeting_id": event.meetingId,
//           "user_id": event.userId,
//           "reason": event.reason,
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         emit(AttendeeDeleted("Participant removed successfully"));
//         add(LoadDiscussions()); // reload meetings list after removal
//       } else {
//         emit(DiscussionError("Failed: ${response.body}"));
//       }
//     } catch (e) {
//       emit(DiscussionError("Error: $e"));
//     }
//   }
// }

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Constant/constants.dart';
import '../../model/interview_bottom.dart';
import 'inetrview_state.dart';
import 'interview_event.dart';

class DiscussionBloc extends Bloc<DiscussionEvent, DiscussionState> {
  DiscussionBloc() : super(DiscussionInitial()) {
    on<LoadDiscussions>(_onLoadDiscussions);
    on<DeleteMeetingEvent>(_onDeleteMeeting);
    on<DeleteAttendeeEvent>(_onDeleteAttendee);
  }

  /// 🔵 Load Discussions (Meetings List)
  Future<void> _onLoadDiscussions(
      LoadDiscussions event, Emitter<DiscussionState> emit) async {
    emit(DiscussionLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      print("🔎 [_onLoadDiscussions] token = $token");

      if (token == null || token.isEmpty) {
        emit(DiscussionError('Token not found'));
        return;
      }

      final url = Uri.parse(
          '${BASE_URL}interview-room/list');

      final body = {
        "job_id": "",
        "from_date": "",
        "to_date": "",
        "from": "",
        "interviewTitle": "",
        "sort": ""
      };

      print("➡️ POST $url");
      print("   Headers: {Authorization: Bearer $token}");
      print("   Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("⬅️ Status: ${response.statusCode}");
      print("⬅️ Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (data['status'] == true && data['scheduled_meeting_list'] != null) {
        final List<dynamic> list = data['scheduled_meeting_list'];
        final discussions = list
            .map<ScheduledMeeting>((json) => ScheduledMeeting.fromJson(json))
            .toList();

        print("✅ Meetings loaded: ${discussions.length}");
        emit(DiscussionLoaded(discussions));
      } else {
        print("⚠️ No data found or status=false");
        // 🔹 Extract API message
        final apiMessage = data['message'] ?? data['msg'] ?? 'No data found';

        // 🔹 Emit DiscussionError with actual status code
        emit(DiscussionError(apiMessage, response.statusCode));
      }
    } catch (e, st) {
      print("💥 [_onLoadDiscussions] Error: $e\n$st");
      emit(DiscussionError('Failed to fetch discussions: $e'));
    }
  }

  /// 🔴 Delete Meeting Handler
  Future<void> _onDeleteMeeting(
      DeleteMeetingEvent event, Emitter<DiscussionState> emit) async {
    emit(MeetingDeleting());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      print("🔎 [_onDeleteMeeting] meetingId=${event.meetingId}, reason=${event.reason}");
      print("🔎 token=$token");

      if (token == null) {
        emit(DiscussionError("Token missing"));
        return;
      }

      final url = Uri.parse(
          "https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/interview-room/remove");

      final body = {
        "meeting_id": event.meetingId,
        "whom": "meeting",
        "reason": event.reason,
      };

      print("➡️ POST $url");
      print("   Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("⬅️ Status: ${response.statusCode}");
      print("⬅️ Body: ${response.body}");

      if (response.statusCode == 200) {
        emit(MeetingDeleted("Meeting deleted successfully"));
        add(LoadDiscussions()); // reload list
      } else {
        emit(DiscussionError("Failed: ${response.body}"));
      }
    } catch (e, st) {
      print("💥 [_onDeleteMeeting] Error: $e\n$st");
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

      print("🔎 [_onDeleteAttendee] meetingId=${event.meetingId}, userId=${event.userId}, reason=${event.reason}");
      print("🔎 token=$token");

      if (token == null) {
        emit(DiscussionError("Token missing"));
        return;
      }

      final url = Uri.parse(
          "https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/interview-room/remove");

      final body = {
        "meeting_id": event.meetingId,
        "user_id": event.userId,
        "reason": event.reason,
      };

      print("➡️ POST $url");
      print("   Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("⬅️ Status: ${response.statusCode}");
      print("⬅️ Body: ${response.body}");

      if (response.statusCode == 200) {
        emit(AttendeeDeleted("Participant removed successfully"));
        add(LoadDiscussions()); // reload meetings list after removal
      } else {
        emit(DiscussionError("Failed: ${response.body}"));
      }
    } catch (e, st) {
      print("💥 [_onDeleteAttendee] Error: $e\n$st");
      emit(DiscussionError("Error: $e"));
    }
  }
}
