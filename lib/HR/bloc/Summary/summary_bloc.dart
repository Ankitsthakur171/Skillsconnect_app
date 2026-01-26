import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Constant/constants.dart';
import 'summary_event.dart';
import 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  SummaryBloc() : super(SummaryInitial()) {
    on<LoadSummary>(_onLoadSummary);
  }

  Future<void> _onLoadSummary(
      LoadSummary event,
      Emitter<SummaryState> emit,
      ) async {
    emit(SummaryLoading());

    try {
      // 1) token lao
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        emit(SummaryError('Auth token not found.'));
        return;
      }

      // 2) API hit (job_id as query param)
      final uri = Uri.parse(
        '${BASE_URL}job/dashboard/dashboard-summary',
      ).replace(queryParameters: {});

      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        emit(SummaryError('Failed: ${res.statusCode}'));
        return;
      }

      // 3) Safe JSON parsing
      final Map<String, dynamic> root = json.decode(res.body) as Map<String, dynamic>;
      final Map<String, dynamic> data = (root['data'] ?? {}) as Map<String, dynamic>;

      int asInt(dynamic v) {
        if (v is int) return v;
        if (v is String) return int.tryParse(v) ?? 0;
        if (v is double) return v.toInt();
        return 0;
      }

      // Invited -> InvitedCollegeCount
      final int invited = asInt(data['InvitedCollegeCount']);

      int applications = 0;
      int selected = 0;
      int rejected = 0;

      // 4) jobs[] me se dhoondo
      final List<Map<String, dynamic>>? jobs =
      (data['jobs'] as List?)?.cast<Map<String, dynamic>>();
      if (jobs != null && jobs.isNotEmpty) {
        final Map<String, dynamic> match = jobs.firstWhere(
              (j) => asInt(j['id']) == event,
          orElse: () => <String, dynamic>{},
        );
        if (match.isNotEmpty) {
          applications = asInt(match['total_application']);
          selected = asInt(match['selected_candidate']);
          rejected = asInt(match['rejected_candidate']);
        }
      }

      // 5) Fallback -> candidateCounts[] (agar jobs se na mila)
      if (applications == 0 && selected == 0 && rejected == 0) {
        final List<Map<String, dynamic>>? cands =
        (data['candidateCounts'] as List?)?.cast<Map<String, dynamic>>();
        if (cands != null && cands.isNotEmpty) {
          // same job_id match; na mile to first item
          final Map<String, dynamic> cmatch = cands.firstWhere(
                (c) => asInt(c['job_id']) == event,
            orElse: () => cands.first,
          );
          applications = asInt(cmatch['total_applications']);
          selected = asInt(cmatch['selected_candidate']);
          rejected = asInt(cmatch['rejected_candidate']);
        }
      }

      // 6) UI ko emit
      emit(SummaryLoaded(
        applications: applications,
        invited: invited,
        selected: selected,
        rejected: rejected,
      ));
    } catch (e) {
      emit(SummaryError('Error: $e'));
    }
  }
}
