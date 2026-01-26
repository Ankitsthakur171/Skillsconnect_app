
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/TPO/Model/student_model.dart';
import '../../Constant/constants.dart';
import 'tpoinnerapplicants_event.dart';
import 'tpoinnerapplicants_state.dart';

class StudentBloc extends Bloc<StudentEvent, StudentState> {
  StudentBloc() : super(StudentInitial()) {
    on<StudentLoadApplicants>(_onLoad);
    on<StudentSearchEvent>(_onSearch);
    on<StudentApplyFilterEvent>(_onApplyFilter);
    on<StudentLoadMoreEvent>(_onLoadMore);
  }


  // ✅ small cooldown to avoid 429 on rapid scroll
  DateTime _lastLoadMoreAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _loadMoreCooldown = Duration(milliseconds: 900);

  Future<Map<String, String>> _headers() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<StudentModel>> _fetch({
    required int jobId,
    required int limit,
    required StudentQuery q,
    int offset = 0, // 👈 added
  }) async {
    final resp = await http.post(
      Uri.parse('${BASE_URL}job/dashboard/application-listing'),
      headers: await _headers(),
      body: jsonEncode({
        "job_id": jobId,

        // 👇 IMPORTANT: use the passed offset
        "offset": "0",    // was 0 earlier
        "limit": limit,

        "search": q.search,
        "filter": {
          "name": q.search,
          "college_name": q.search.isNotEmpty ? q.search : (q.collegeId ?? ""),
          "college_state": q.stateId ?? "",
          "college_city": q.cityId ?? "",
          "process_name": "",
          "application_status_name": "",
          "current_degree": "",
          "current_course_name": "",
          "current_specialization_name": "",
          "current_passing_year": "",
          "perfered_location1": "",
          "current_location": "",
          "remarks": "",
          "state": "",
          "gender": "",
          "assessment_status": ""
        },
        "date": "",
        "email_id": "",
        "process_id": q.processId == null ? "" : q.processId.toString(),
        "status_id": q.statusId == null ? "" : q.statusId.toString(),
      }),
    );

    print("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    print("[StudentBloc] request: offset=$offset, limit=$limit, search='${q.search}'");

    if (resp.statusCode != 200) {
      throw Exception('Failed with status ${resp.statusCode}');
    }

    final data = json.decode(resp.body);
    if (data['status'] == true && data['studentListing'] != null) {
      return (data['studentListing'] as List)
          .map((e) => StudentModel.fromJson(e))
          .toList();
    } else {
      return <StudentModel>[];
    }
  }


  Future<void> _onLoad(StudentLoadApplicants e, Emitter<StudentState> emit) async {
    try {
      emit(StudentLoading());
      final list = await _fetch(jobId: e.jobId, limit: e.limit, q: e.query);
      emit(StudentLoaded(
        student: list,
        limit: e.limit,
        hasMore: list.length >= e.limit,
        query: e.query,
      ));
    } catch (err) {
      emit(StudentError('Exception: $err'));
    }
  }

// helper: local filter by name/college (case-insensitive)
  List<StudentModel> _localFilter(List<StudentModel> list, String term) {
    final q = term.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((s) {
      final n = (s.name ?? '').toLowerCase();
      final u = (s.university ?? '').toLowerCase();
      return n.contains(q) || u.contains(q);
    }).toList();
  }

  Future<void> _onSearch(StudentSearchEvent e, Emitter<StudentState> emit) async {
    try {
      // current filters ko preserve karo (search hi bas change hoga)
      StudentQuery base;
      if (state is StudentLoaded) {
        final cur = (state as StudentLoaded).query;
        base = cur.copyWith(search: e.search.trim());
      } else {
        base = StudentQuery(search: e.search.trim());
      }

      // 1) Try API search (limit 5)
      var list = await _fetch(jobId: e.jobId, limit: 5, q: base);

      // 2) Fallback: agar API 0 de rahi to raw list lao aur client-side filter lagao
      if (list.isEmpty && base.search.isNotEmpty) {
        final raw = await _fetch(jobId: e.jobId, limit: 50, q: base.copyWith(search: ""));
        list = _localFilter(raw, base.search);
      }

      emit(StudentLoaded(
        student: list,
        limit: 5,
        hasMore: list.length >= 5,
        query: base,
      ));
    } catch (err) {
      emit(StudentError('Exception: $err'));
    }
  }

  Future<void> _onApplyFilter(StudentApplyFilterEvent e, Emitter<StudentState> emit) async {
    try {
      final list = await _fetch(jobId: e.jobId, limit: 5, q: e.query);
      emit(StudentLoaded(student: list, limit: 5, hasMore: list.length >= 5, query: e.query));
    } catch (err) {
      emit(StudentError('Exception: $err'));
    }
  }



  Future<void> _onLoadMore(StudentLoadMoreEvent e, Emitter<StudentState> emit) async {
    final cur = state;
    if (cur is! StudentLoaded) return;

    // already fetching? ya aur data hi nahi? => return
    if (!cur.hasMore || cur.isLoadingMore) return;

    // throttle to avoid 429 on rapid scroll
    final now = DateTime.now();
    if (now.difference(_lastLoadMoreAt) < _loadMoreCooldown) return;
    _lastLoadMoreAt = now;

    // flip loadingMore ON
    emit(cur.copyWith(isLoadingMore: true));

    // ✅ offset = 0 hi rahega; limit ko 5-5 badhao
    final int newLimit = cur.limit + 5;

    try {
      // server se first N (newLimit) laao — offset = 0
      final list = await _fetch(
        jobId: e.jobId,
        limit: newLimit,
        q: cur.query,
        // offset parameter pass NAHIN kar rahe—by default 0 hi use hoga
      );

      // ✅ REPLACE, not append (kyunki list ab pehle N items laati hai)
      final bool hasMore = list.length >= newLimit;

      emit(cur.copyWith(
        student: list,            // replace cumulative list
        limit: newLimit,          // track current window size
        hasMore: hasMore,
        isLoadingMore: false,     // loader OFF
      ));
    } catch (err) {
      final msg = err.toString();
      if (msg.contains('429') || msg.contains('Too many requests')) {
        emit(cur.copyWith(isLoadingMore: false));
        return;
      }
      emit(StudentError('Exception: $err'));
    }
  }

// Future<void> _onLoadMore(StudentLoadMoreEvent e, Emitter<StudentState> emit) async {
  //   final cur = state;
  //   if (cur is! StudentLoaded) return;
  //   final newLimit = cur.limit + 5;
  //   try {
  //     final list = await _fetch(jobId: e.jobId, limit: newLimit, q: cur.query);
  //     emit(cur.copyWith(
  //       student: list,
  //       limit: newLimit,
  //       hasMore: list.length >= newLimit,
  //     ));
  //   } catch (err) {
  //     emit(StudentError('Exception: $err'));
  //   }
  // }
}


