
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/TPO/Model/tpo_applicant_details_model.dart';
import 'package:skillsconnect/TPO/TpoInterviewStudent/tpointerinnerevent.dart';
import 'package:skillsconnect/TPO/TpoInterviewStudent/tpointerinnerstate.dart';

import '../../Constant/constants.dart';


class Tpointerinnerbloc extends Bloc<Tpointerinnerevent, Tpointerinnerstate> {
  Tpointerinnerbloc()
      : super(const Tpointerinnerstate(
    applicant: null,
    isLoading: true,
    applicationStages: [],
  )) {
    on<TpoInterviewLoadApplicant>(_onLoadApplicant);
  }

  Future<void> _onLoadApplicant(
      TpoInterviewLoadApplicant event, Emitter<Tpointerinnerstate> emit) async {
    emit(const Tpointerinnerstate(
      applicant: null,
      isLoading: true,
      applicationStages: [],
    ));

    final url = Uri.parse(
        "${BASE_URL}common/student-full-details");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print(" Token not found.");
        emit(const Tpointerinnerstate(
          applicant: null,
          isLoading: false,
          applicationStages: [],
        ));
        return;
      }

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "application_id": event.applicationId,
          "job_id": event.jobId,
          "user_id": event.userId,
          "resume": "No",
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print(' Full Response: $decoded');

        if (decoded['status'] == true && decoded['data'] != null) {
          try {
            final applicant = TPOApplicant.fromJson(decoded['data']);



            emit(Tpointerinnerstate(
              applicant: applicant,
              isLoading: false,
              applicationStages: [], // Populate this from API if available
            ));
          } catch (e) {
            print(" Parsing error: $e");
            emit(const Tpointerinnerstate(
              applicant: null,
              isLoading: false,
              applicationStages: [],
            ));
          }
        } else {
          print(" Invalid applicant data: ${decoded['data']}");
          emit(const Tpointerinnerstate(
            applicant: null,
            isLoading: false,
            applicationStages: [],
          ));
        }
      } else {
        print(" Server error: ${response.statusCode} - ${response.body}");
        emit(const Tpointerinnerstate(
          applicant: null,
          isLoading: false,
          applicationStages: [],
        ));
      }
    } catch (e) {
      print(" Exception during API call: $e");
      emit(const Tpointerinnerstate(
        applicant: null,
        isLoading: false,
        applicationStages: [],
      ));
    }
  }
}
