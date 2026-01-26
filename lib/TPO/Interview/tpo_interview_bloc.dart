// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:skillsconnect/TPO/Interview/tpo_interview_event.dart';
// import 'package:skillsconnect/TPO/Interview/tpo_interview_state.dart';
//
//
// class Discussion {
//   final String title;
//   final String time;
//   final String date;
//   final int invitedCount;
//   final List<String> participantImages;
//   final String meetingId;
//
//   Discussion({
//     required this.title,
//     required this.time,
//     required this.date,
//     required this.invitedCount,
//     required this.participantImages,
//     required this.meetingId,
//   });
// }
//
//
// class DiscussionBloc extends Bloc<DiscussionEvent, DiscussionState> {
//   DiscussionBloc() : super(DiscussionInitial()) {
//     on<LoadDiscussions>((event, emit) async {
//       // 👇 Static mock data using Discussion model
//       final discussions = [
//         Discussion(
//           title: "Group Discussion | Social Media Di...",
//           time: "12:00 PM to 01:00 PM",
//           date: "15th March, 2025",
//           invitedCount: 15,
//           participantImages: [
//             'assets/user.png',
//             'assets/user.png',
//             'assets/user.png',
//           ],
//           meetingId: '0',
//         ),
//         Discussion(
//           title: "Group Discussion | Technology Trends",
//           time: "03:00 PM to 05:00 PM",
//           date: "20th March, 2026",
//           invitedCount: 3,
//           participantImages: [
//             'assets/user.png',
//             'assets/user.png',
//             'assets/user.png',
//           ],
//           meetingId: '0',
//         ),
//         Discussion(
//           title: "Group Discussion | Future of AI",
//           time: "12:00 PM to 01:00 PM",
//           date: "25th March, 2025",
//           invitedCount: 10,
//           participantImages: [
//             'assets/user.png',
//             'assets/user.png',
//             'assets/user.png',
//           ],
//           meetingId: '0',
//         ),
//       ];
//
//       emit(DiscussionLoaded(discussions));
//     });
//   }
// }








import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Constant/constants.dart';
import '../../HR/model/interview_bottom.dart';
import 'tpo_interview_event.dart';
import 'tpo_interview_state.dart';

class DiscussionBloc extends Bloc<DiscussionEvent, DiscussionState> {
  DiscussionBloc() : super(DiscussionInitial()) {
    on<LoadDiscussions>(_onLoadDiscussions);
  }

  Future<void> _onLoadDiscussions(
      LoadDiscussions event, Emitter<DiscussionState> emit) async {
    try {
      emit(DiscussionLoading());

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final url = Uri.parse(
          "${BASE_URL}interview-room/list");

      final body = {
        "job_id": "",
        "from_date": "",
        "to_date": "",
        "from": "",
        "interviewTitle": "",
        "sort": ""
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true && data['scheduled_meeting_list'] != null) {
        final List<dynamic> list = data['scheduled_meeting_list'];
        final discussions =
        list.map((json) => ScheduledMeeting.fromJson(json)).toList();

        emit(DiscussionLoaded(discussions));
      } else {
        emit(DiscussionError(data['msg'] ?? 'No data found'));
      }
    } catch (e) {
      emit(DiscussionError('Failed to fetch discussions: $e'));
    }
  }
}
