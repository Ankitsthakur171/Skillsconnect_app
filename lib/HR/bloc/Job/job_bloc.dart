import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Constant/constants.dart';
import '../../model/job_model.dart';
import 'job_event.dart';
import 'job_state.dart';





// -------------------- BLOC --------------------
class JobBloc extends Bloc<JobEvent, JobState> {
  JobBloc() : super(JobInitial()) {
    on<LoadJobsEvent>(_onLoadJobs);
    on<SearchJobsEvent>(_onSearchJobs);
    on<FetchJobsEvent>(_onFetchJobs);
    on<ApplyFilterEvent>((event, emit) {
      emit(FilteredJobLoaded(event.filteredJobs));
    });
//  Add this line!
  }
  List<JobModel> allJobs = [];
// pagination state
  final List<JobModel> _paginatedJobs = [];
  bool _inFlight = false;
  int _page = 1;         // 1-based
  final int _rows = 5;   // per-page size (5)


  // -------------------- Load All (Not used for paginated view directly) --------------------
  Future<void> _onLoadJobs(LoadJobsEvent event, Emitter<JobState> emit) async {
    if (_inFlight) return;
    _inFlight = true;

    emit(JobLoading());
    _paginatedJobs.clear();
    _page = 1;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        emit(JobError("Token not found."));
        _inFlight = false;
        return;
      }

      final resp = await http.post(
        Uri.parse('${BASE_URL}jobs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        // ⚠️ body parameters (page/rows) — 1-based page, 5 rows
        body: jsonEncode({
          "company_name": "",
          "job_type": "",
          "job_title": "",
          "work_culuture": "",
          "job_status": "",
          "course": "",
          "location": "",
          "page": _page,      // 1
          "rows": _rows,      // 5
        }),
      );

      if (resp.statusCode != 200) {
        emit(JobError("Failed to load jobs: ${resp.statusCode}"));
        return;
      }

      final decoded = jsonDecode(resp.body);
      final List<dynamic> data = decoded['data'] ?? [];
      final newJobs = data.map((j) => JobModel.fromJson(j)).toList();

      _paginatedJobs.addAll(newJobs);
      final hasMore = newJobs.length == _rows;

      emit(JobLoaded(jobs: List<JobModel>.from(_paginatedJobs), hasMore: hasMore));
    } catch (e) {
      emit(JobError("Error: $e"));
    } finally {
      _inFlight = false;
    }
  }


  // -------------------- Search --------------------
// -------------------- Search (ALL data from server, then filter) --------------------
  Future<void> _onSearchJobs(SearchJobsEvent event, Emitter<JobState> emit) async {
    final query = event.query.toLowerCase().trim();

    // Query empty => normal paginated list par wapas (jo abhi tak load hua hai)
    if (query.isEmpty) {
      final hasMore = _paginatedJobs.length == _rows; // per-page size 5
      emit(JobLoaded(jobs: List<JobModel>.from(_paginatedJobs), hasMore: hasMore));
      return;
    }

    try {
      // Token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        emit(JobError("Token not found."));
        return;
      }

      // ⚠️ Pagination OFF: ALL data mango (body params se page/rows blank)
      final resp = await http.post(
        Uri.parse('${BASE_URL}jobs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "company_name": "",
          "job_type": "",
          "job_title": "",
          "work_culuture": "",
          "job_status": "",
          "course": "",
          "location": "",
          "page": "",   // <- all
          "rows": "",   // <- all
        }),
      );



      if (resp.statusCode != 200) {
        emit(JobError("Failed to load jobs: ${resp.statusCode}"));
        return;
      }



      final decoded = jsonDecode(resp.body);
      final List<dynamic> data = decoded['data'] ?? [];
      final all = data.map((j) => JobModel.fromJson(j)).toList();

      // Local filter on ALL data
      final filtered = all.where((job) {
        final title    = job.title.toLowerCase();
        final location = job.location.toLowerCase();
        final status   = job.status.toLowerCase();
        return title.contains(query) || location.contains(query) || status.contains(query);
      }).toList();

      // Search mode: pagination OFF
      emit(JobLoaded(jobs: filtered, hasMore: false));
    } catch (e) {
      emit(JobError("Error: $e"));
    }
  }


  // -------------------- Fetch with Pagination --------------------
  Future<void> _onFetchJobs(FetchJobsEvent event, Emitter<JobState> emit) async {
    // guard: already fetching or no more?
    final st = state;
    if (_inFlight || st is! JobLoaded || !st.hasMore) return;

    _inFlight = true;

    // UI ko bottom loader dikhane ke liye interim state chahiye?
    // Agar tumhare JobLoaded me isFetchingMore nahi hai, skip karo.
    // (Yeh optional hai; agar state me flag hai to yahan emit(...) kar do.)

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        emit(JobError("Token not found."));
        _inFlight = false;
        return;
      }

      // 👇 page + 1 (1-based) — per page rows = 5
      _page += 1;

      final resp = await http.post(
        Uri.parse('${BASE_URL}jobs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "company_name": "",
          "job_type": "",
          "job_title": "",
          "work_culuture": "",
          "job_status": "",
          "course": "",
          "location": "",
          "page": _page,   // 2, 3, ...
          "rows": _rows,   // 5 (fixed per page)
        }),
      );

      if (resp.statusCode != 200) {
        emit(JobError("Failed to load jobs: ${resp.statusCode}"));
        return;
      }

      final decoded = jsonDecode(resp.body);
      final List<dynamic> data = decoded['data'] ?? [];
      final newJobs = data.map((j) => JobModel.fromJson(j)).toList();

      // append to existing
      _paginatedJobs.addAll(newJobs);
      final hasMore = newJobs.length == _rows;

      emit(JobLoaded(jobs: List<JobModel>.from(_paginatedJobs), hasMore: hasMore));
    } catch (e) {
      emit(JobError("Error: $e"));
    } finally {
      _inFlight = false;
    }
  }

  bool _isUserNotFound404(http.Response resp) {
    if (resp.statusCode != 404) return false;
    try {
      final body = jsonDecode(resp.body);
      final msg = (body['error'] ?? body['message'] ?? body['msg'] ?? '').toString();
      return msg.toLowerCase().contains('user not found');
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearAuth() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('auth_token');
    await sp.remove('user_data');
    await sp.remove('user_id');
  }


  JobState _fail(String msg) => JobError(msg); // syntactic sugar (optional)
}
