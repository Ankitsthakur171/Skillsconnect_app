import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Constant/constants.dart';
import 'c_inner_event.dart';
import 'c_inner_state.dart';
import '../../model/c_innerpage_model.dart';

class CollegeBloc extends Bloc<CollegeEvent, CollegeState> {
  CollegeBloc() : super(CollegeInitial()) {
    on<FetchCollegeDetails>(_onFetchCollegeDetails);
  }

  Future<void> _onFetchCollegeDetails(
      FetchCollegeDetails event,
      Emitter<CollegeState> emit,
      ) async {
    emit(CollegeLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.post(
        Uri.parse(
          "${BASE_URL}colleges/college-details",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "college_id": event.collegeId,
          "job_id": event.jobId,
        }),
      );

      if (response.statusCode == 200) {
        final root = jsonDecode(response.body);
        if (root["status"] == true && root["data"] != null) {
          final data = root["data"] as Map<String, dynamic>;

          // collegeDetails[0] -> CollegeInfo
          final cd = (data["collegeDetails"] as List?) ?? [];
          if (cd.isEmpty) {
            emit(const CollegeError("No college details found"));
            return;
          }
          // final college = CollegeInfo.fromJson(cd.first as Map<String, dynamic>);
          // ✅ Parse using fromApi (whole data map, not just cd.first)
          final college = CollegeInfo.fromApi(data);


          // collegeCourseDetails -> List<CourseInfo>
          final rawCourses = (data["collegeCourseDetails"] as List?) ?? [];
          final courses = rawCourses
              .map((e) => CourseInfo.fromApi(e as Map<String, dynamic>))
              .toList();

          emit(CollegeLoaded(college, courses));
        } else {
          emit(CollegeError(root["msg"]?.toString() ?? "Invalid response"));
        }
      } else {
        emit(CollegeError("Failed with status ${response.statusCode}"));
      }
    } catch (e) {
      emit(CollegeError("Error: $e"));
    }
  }
}
