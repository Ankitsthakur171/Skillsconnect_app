import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skillsconnect/TPO/Summary/tpo_summary_event.dart';
import 'package:skillsconnect/TPO/Summary/tpo_summary_state.dart';

import '../../Constant/constants.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  SummaryBloc() : super(SummaryInitial()) {
    on<LoadSummary>(_onLoadSummary);
  }

  Future<void> _onLoadSummary(LoadSummary event, Emitter<SummaryState> emit) async {
    emit(SummaryLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        emit(SummaryError('Token not found.'));
        return;
      }

      final response = await http.get(
        Uri.parse('${BASE_URL}job/dashboard/tpo-summary'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        emit(SummaryLoaded(
          jobs: data['jobListingCount'] ?? 0,
          selected_candidates: data['selectedUserCount'] ?? 0,
          registered_users: data['registeredUserCount'] ?? 0,
        ));
      } else {
        emit(SummaryError('Failed to load summary: ${response.statusCode}'));
      }
    } catch (e) {
      emit(SummaryError('An error occurred: $e'));
    }
  }
}
