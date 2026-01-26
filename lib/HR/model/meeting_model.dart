import 'package:skillsconnect/HR/model/meeting_student_model.dart';

class Meeting {
  final String title;
  final String company;
  final String date;
  final String time;
  final String hrManagers;
  final String moderator;
  final int meeting_id;
  final List<Student> students;

  Meeting({
    required this.title,
    required this.company,
    required this.date,
    required this.time,
    required this.hrManagers,
    required this.moderator,
    required this.students,
    required this.meeting_id,
  });
}


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
//
//
//
//
//
// //
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// // -------------------- MODEL --------------------
// class Applicant {
//   final int applicationId;
//   final String name;
//   final String college;
//
//   Applicant({
//     required this.applicationId,
//     required this.name,
//     required this.college,
//   });
//
//   factory Applicant.fromJson(Map<String, dynamic> json) {
//     return Applicant(
//       applicationId: int.tryParse(json['application_id'].toString()) ?? 0,
//       name: json['full_name'] ?? "No Name",
//       college: json['college_name'] ?? "Not Specified",
//     );
//   }
// }
//
// // -------------------- EVENTS --------------------
// abstract class ApplicantEvent {}
//
// class LoadApplicants extends ApplicantEvent {
//   final int page;
//   LoadApplicants({this.page = 1});
// }
//
// // -------------------- STATES --------------------
// abstract class ApplicantState {}
//
// class ApplicantInitial extends ApplicantState {}
//
// class ApplicantLoading extends ApplicantState {}
//
// class ApplicantLoaded extends ApplicantState {
//   final List<Applicant> applicants;
//   final bool hasReachedMax;
//   final int currentPage;
//
//   ApplicantLoaded({
//     required this.applicants,
//     required this.hasReachedMax,
//     required this.currentPage,
//   });
// }
//
// class ApplicantError extends ApplicantState {
//   final String message;
//   ApplicantError(this.message);
// }
//
// // -------------------- BLOC --------------------
// class ApplicantBloc extends Bloc<ApplicantEvent, ApplicantState> {
//   final int perPage = 5;
//   final int jobId = 255;
//
//   ApplicantBloc() : super(ApplicantInitial()) {
//     on<LoadApplicants>(_onLoadApplicants);
//   }
//
//   Future<void> _onLoadApplicants(
//       LoadApplicants event, Emitter<ApplicantState> emit) async {
//     try {
//       final currentState = state;
//       int page = event.page;
//
//       if (currentState is ApplicantLoaded && currentState.hasReachedMax) {
//         print("⚠️ Already reached max, no more data");
//         return;
//       }
//
//       if (page == 1) {
//         emit(ApplicantLoading());
//       }
//
//       // 👉 offset हमेशा 0 रहेगा
//       final offset = 0;
//       // 👉 limit बढ़ेगा हर page के साथ
//       final limit = page * perPage;
//
//       print("📤 Requesting page=$page, offset=$offset, limit=$limit");
//
//       final body = {
//         "job_id": jobId,
//         "offset": offset,
//         "limit": limit,
//         "filter": {
//           "name": "",
//           "college_name": "",
//           "process_name": "",
//           "application_status_name": "",
//           "current_degree": "",
//           "current_course_name": "",
//           "current_specialization_name": "",
//           "current_passing_year": "",
//           "perfered_location1": "",
//           "current_location": "",
//           "remarks": "",
//           "state": "",
//           "gender": "",
//           "college_city": "",
//           "college_state": "",
//           "assessment_status": ""
//         },
//         "date": "",
//         "email_id": "",
//         "process_id": "",
//         "status_id": ""
//       };
//
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');
//
//       final response = await http.post(
//         Uri.parse(
//             "https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/job/dashboard/application-listing"),
//         headers: {
//           "Content-Type": "application/json",
//           if (token != null) "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(body),
//       );
//
//       print("⬅️ API Status: ${response.statusCode}");
//       print("⬅️ API Response: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<dynamic> list = data['studentListing'] ?? [];
//
//         final applicants =
//         list.map((e) => Applicant.fromJson(e)).toList();
//
//         emit(ApplicantLoaded(
//           applicants: applicants,
//           hasReachedMax: applicants.length < limit, // अगर कम आया तो max
//           currentPage: page,
//         ));
//
//         print("✅ Loaded total count=${applicants.length}");
//       } else {
//         emit(ApplicantError("API Error: ${response.statusCode}"));
//       }
//     } catch (e, st) {
//       emit(ApplicantError("Exception: $e"));
//       print("❌ Exception: $e\n$st");
//     }
//   }
// }
//
// // -------------------- UI --------------------
// class ApplicantsScreen extends StatefulWidget {
//   const ApplicantsScreen({super.key});
//
//   @override
//   State<ApplicantsScreen> createState() => _ApplicantsScreenState();
// }
//
// class _ApplicantsScreenState extends State<ApplicantsScreen> {
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     context.read<ApplicantBloc>().add(LoadApplicants(page: 1));
//
//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels >=
//           _scrollController.position.maxScrollExtent - 200) {
//         final state = context.read<ApplicantBloc>().state;
//         if (state is ApplicantLoaded && !state.hasReachedMax) {
//           context
//               .read<ApplicantBloc>()
//               .add(LoadApplicants(page: state.currentPage + 1));
//         }
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Applicants Pagination")),
//       body: BlocBuilder<ApplicantBloc, ApplicantState>(
//         builder: (context, state) {
//           if (state is ApplicantInitial || state is ApplicantLoading) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (state is ApplicantError) {
//             return Center(child: Text(state.message));
//           } else if (state is ApplicantLoaded) {
//             return ListView.builder(
//               controller: _scrollController,
//               itemCount: state.hasReachedMax
//                   ? state.applicants.length
//                   : state.applicants.length + 1,
//               itemBuilder: (context, index) {
//                 if (index < state.applicants.length) {
//                   final applicant = state.applicants[index];
//                   return ListTile(
//                     leading: Text(applicant.applicationId.toString()),
//                     title: Text(applicant.name),
//                     subtitle: Text(applicant.college),
//                   );
//                 } else {
//                   return const Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Center(child: CircularProgressIndicator()),
//                   );
//                 }
//               },
//             );
//           }
//           return const SizedBox();
//         },
//       ),
//         floatingActionButton: FloatingActionButton(
//         onPressed: () {
//       final state = context.read<ApplicantBloc>().state;
//       if (state is ApplicantLoaded && !state.hasReachedMax) {
//         context.read<ApplicantBloc>()
//             .add(LoadApplicants(page: state.currentPage + 1));
//       }
//     },
//     child: const Icon(Icons.add),
//     ),
//
//     );
//   }
// }
//
// // -------------------- MAIN --------------------
// void main() {
//   runApp(
//     MaterialApp(
//       home: BlocProvider(
//         create: (_) => ApplicantBloc(),
//         child: const ApplicantsScreen(),
//       ),
//     ),
//   );
// }
