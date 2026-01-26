import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Constant/constants.dart';
import '../../model/applicant_details_model.dart';
import 'applicant_deatils_event.dart';
import 'applicant_details_state.dart';

class ApplicanDetailBloc extends Bloc<ApplicantEvent, ApplicantState> {
  ApplicanDetailBloc()
      : super(const ApplicantState(
          applicant: null,
          isLoading: true,
          applicationStages: [],
        )) {
    on<LoadApplicant>(_onLoadApplicant);
  }

  Future<void> _onLoadApplicant(
      LoadApplicant event, Emitter<ApplicantState> emit) async {
    emit(const ApplicantState(
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
        emit(const ApplicantState(
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

        if (decoded['status'] == true && decoded['data'] != null) {
          try {
            final applicant = Applicant.fromJson(decoded['data']);

            emit(ApplicantState(
              applicant: applicant,
              isLoading: false,
              applicationStages: [], // Populate this from API if available
            ));
          } catch (e) {
            emit(const ApplicantState(
              applicant: null,
              isLoading: false,
              applicationStages: [],
            ));
          }
        } else {
          emit(const ApplicantState(
            applicant: null,
            isLoading: false,
            applicationStages: [],
          ));
        }
      } else {
        emit(const ApplicantState(
          applicant: null,
          isLoading: false,
          applicationStages: [],
        ));
      }
    } catch (e) {
      emit(const ApplicantState(
        applicant: null,
        isLoading: false,
        applicationStages: [],
      ));
    }
  }
}
