// import 'dart:convert';
//
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:skillsconnect/TPO/TPO_Home/tpo_home_event.dart';
// import 'package:skillsconnect/TPO/TPO_Home/tpo_home_state.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../Model/tpo_home_job_model.dart';
//
//
//
// class TpoHomeBloc extends Bloc<TpoHomeEvent, TpoHomeState> {
//   TpoHomeBloc() : super(JobInitial()) {
//     on<LoadTpoJobsEvent>(_onLoadJobs);
//     on<SearchTpoJobs>(_onSearchJobs);
//     on<ApplyFilterEvent>((event, emit) {
//       emit(FilteredJobLoaded(event.filteredJobs));
//     });
//
//   }
//   List<TpoHomeJobModel> tpojobs = [];
//
//
//
//   Future<void> _onLoadJobs(LoadTpoJobsEvent event, Emitter<TpoHomeState> emit) async {
//     emit(TPOJobLoading());
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');
//       print("Token: $token");
//
//       if (token == null) {
//         emit(TpoJobError("Token not found."));
//         return;
//       }
//
//       final response = await http.post(
//         Uri.parse('https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/jobs'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         // Add body if required by API
//         body: jsonEncode({
//           "company_name": "",
//           "job_type": "",
//           "job_title": "",
//           "work_culuture": "",
//           "job_status": "",
//           "course": "",
//           "location": ""
//         }),
//       );
//
//       print('Status Code: ${response.statusCode}');
//       print('Response Body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);
//         if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
//           final List<dynamic> data = decoded['data'];
//           final jobs = data.map((jobJson) => TpoHomeJobModel.fromJson(jobJson)).toList();
//           tpojobs = jobs;
//           emit(TpoJobLoaded(jobs: jobs, hasMore: false));
//         } else {
//           emit(TpoJobError("Unexpected API response format."));
//         }
//       } else {
//         emit(TpoJobError("Failed to load jobs: ${response.statusCode}"));
//       }
//     } catch (e) {
//       print("Exception caught: $e");
//       emit(TpoJobError("Error: $e"));
//     }
//   }
//
//
//   // -------------------- Search --------------------
//   void _onSearchJobs(SearchTpoJobs event, Emitter<TpoHomeState> emit) {
//     final query = event.query.toLowerCase().trim();
//
//     if (query.isEmpty) {
//       emit(TpoJobLoaded(jobs: tpojobs, hasMore: false));
//       return;
//     }
//
//     if (tpojobs.isEmpty) {
//       print(' No data in tpojobs — did you forget to set it in LoadTpoJobs?');
//       return;
//     }
//
//
//     final filteredJobs = tpojobs.where((job) {
//       final title = job.title.toLowerCase();
//       final location = job.location.toLowerCase();
//       final status = job.status.toLowerCase();
//       final jobtype = job.jobtype.toLowerCase();
//       final jobmode = job.mode.toLowerCase();
//
//       final match = title.contains(query) ||
//           location.contains(query) ||
//           status.contains(query) ||
//           jobtype.contains(query) ||
//           jobmode.contains(query);
//
//       if (match) {
//         print(' Match: ${job.title}');
//       }
//
//       return match;
//     }).toList();
//
//     print(' Filtered Jobs Count: ${filteredJobs.length}');
//
//     emit(TpoJobLoaded(jobs: filteredJobs, hasMore: false));
//   }
//
//
// }
//

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:skillsconnect/TPO/Model/tpo_home_job_model.dart';
import '../../Constant/constants.dart';
import 'tpo_home_event.dart';
import 'tpo_home_state.dart';

class TpoHomeBloc extends Bloc<TpoHomeEvent, TpoHomeState> {
  final int _perPage = 5; // rows step
  int _currentLimit = 5; // cumulative rows requested (5,10,15...)
  bool _isFetching = false; // prevent concurrent loads

  List<TpoHomeJobModel> _allJobs = []; // full local store (cumulative)
  String _currentSearchQuery = '';

  TpoHomeBloc() : super(JobInitial()) {
    on<LoadTpoJobsEvent>(_onLoadJobs);
    on<LoadMoreTpoJobsEvent>(_onLoadMoreJobs);
    on<SearchTpoJobs>(_onSearchJobs);
    on<ApplyFilterEvent>((event, emit) {
      emit(FilteredJobLoaded(event.filteredJobs));
    });
  }

  List<TpoHomeJobModel> _cacheAll = [];
  DateTime? _cacheAt;
  final Duration _cacheTtl = const Duration(minutes: 10);

  String _norm(String s) {
    return s.toLowerCase().trim().replaceAll(
      RegExp(r'[\s_\-]+'),
      '',
    ); // remove spaces/underscores/hyphens
  }

  bool _cacheIsFresh() {
    if (_cacheAt == null) return false;
    return DateTime.now().difference(_cacheAt!) < _cacheTtl;
  }

  // ---------------- Initial load (first 5 rows) ----------------
  Future<void> _onLoadJobs(
    LoadTpoJobsEvent event,
    Emitter<TpoHomeState> emit,
  ) async {
    if (_isFetching) return;
    _isFetching = true;
    emit(TPOJobLoading());

    try {
      _currentLimit = _perPage;
      _allJobs = [];

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        emit(TpoJobError("Token not found."));
        _isFetching = false;
        return;
      }

      final body = {
        "company_name": "",
        "job_type": "",
        "job_title": "",
        "work_culuture": "",
        "job_status": "",
        "course": "",
        "location": "",
        "page": 1,
        "rows": _currentLimit,
      };

      final response = await http.post(
        Uri.parse('${BASE_URL}jobs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];

        final jobs = data.map((j) => TpoHomeJobModel.fromJson(j)).toList();

        _allJobs = jobs; // store cumulative
        final bool hasMore =
            data.length >=
            _currentLimit; // if returned >= requested then maybe more

        emit(
          TpoJobLoaded(
            jobs: List<TpoHomeJobModel>.from(_allJobs),
            hasMore: hasMore,
          ),
        );
      }
    } catch (e) {
      emit(TpoJobError("Error: $e"));
    } finally {
      _isFetching = false;
    }
  }

  // ---------------- Load more (scroll) ----------------
  Future<void> _onLoadMoreJobs(
    LoadMoreTpoJobsEvent event,
    Emitter<TpoHomeState> emit,
  ) async {
    // only proceed when we already have loaded some jobs
    if (state is! TpoJobLoaded) return;
    final currentState = state as TpoJobLoaded;

    // if already fetching or no more items -> skip
    if (_isFetching) return;
    if (!(currentState.hasMore)) return;

    // if user is searching via SearchTpoJobs (local search active), disable load more
    if (_currentSearchQuery.isNotEmpty) return;

    _isFetching = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        emit(TpoJobError("Token not found."));
        _isFetching = false;
        return;
      }

      final nextLimit = _currentLimit + _perPage; // cumulative: 10, 15, 20...
      final body = {
        "company_name": "",
        "job_type": "",
        "job_title": "",
        "work_culuture": "",
        "job_status": "",
        "course": "",
        "location": "",
        "page": 1,
        "rows": nextLimit,
      };

      final response = await http.post(
        Uri.parse('${BASE_URL}jobs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        emit(TpoJobError("Failed to load jobs: ${response.statusCode}"));

        _isFetching = false;
        return;
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];
      final cumulative = data.map((j) => TpoHomeJobModel.fromJson(j)).toList();

      // pick only new ones (avoid duplicates)
      final uniqueNew = cumulative.where((newJob) {
        return !_allJobs.any(
          (existing) => existing.jobId.toString() == newJob.jobId.toString(),
        );
      }).toList();

      // update local cumulative store
      if (uniqueNew.isNotEmpty) {
        _allJobs.addAll(uniqueNew);
      }

      final reachedEnd =
          cumulative.length <
          nextLimit; // if server returned fewer than requested cumulative -> end
      _currentLimit = nextLimit;

      emit(
        TpoJobLoaded(
          jobs: List<TpoHomeJobModel>.from(_allJobs),
          hasMore: !reachedEnd,
        ),
      );
    } catch (e) {
      emit(TpoJobError("Load more failed: $e"));
    } finally {
      _isFetching = false;
    }
  }

  // ---------------- Search (local filter on _allJobs) ----------------

  // ---------------- Search (fetch ALL from server, then filter locally) ----------------
  //   Future<void> _onSearchJobs(SearchTpoJobs event, Emitter<TpoHomeState> emit) async {
  //     final query = event.query.toLowerCase().trim();
  //     _currentSearchQuery = query;
  //
  //     // query empty => normal cumulative list + scrolling allowed
  //     if (query.isEmpty) {
  //       emit(TpoJobLoaded(jobs: List<TpoHomeJobModel>.from(_allJobs), hasMore: true));
  //       return;
  //     }
  //
  //     try {
  //       emit(TPOJobLoading()); // optional: show spinner during full fetch
  //
  //       final prefs = await SharedPreferences.getInstance();
  //       final token = prefs.getString('auth_token');
  //       if (token == null) {
  //         emit(TpoJobError("Token not found."));
  //         return;
  //       }
  //
  //       // ⚠️ Pagination disable: rows/page blank => server se ALL jobs
  //       final body = {
  //         "company_name": "",
  //         "job_type": "",
  //         "job_title": "",
  //         "work_culuture": "",
  //         "job_status": "",
  //         "course": "",
  //         "location": "",
  //         "page": "",
  //         "rows": "",   // 👈 ALL DATA
  //       };
  //
  //       final response = await http.post(
  //         Uri.parse('${BASE_URL}jobs'),
  //         headers: {
  //           'Authorization': 'Bearer $token',
  //           'Content-Type': 'application/json',
  //         },
  //         body: jsonEncode(body),
  //       );
  //
  //       if (response.statusCode != 200) {
  //         if (response.statusCode == 404) {
  //           // 404 => force logout
  //           emit(TpoJobForceLogout('User not Found')); // message optional hai
  //         } else {
  //           emit(TpoJobError("Failed to load jobs: ${response.statusCode}"));
  //         }
  //         return;
  //       }
  //
  //       final decoded = jsonDecode(response.body);
  //       final List<dynamic> data = decoded['data'] ?? [];
  //
  //       // server se ALL jobs -> ab wahi purana local filter lagao
  //       final all = data.map((j) => TpoHomeJobModel.fromJson(j)).toList();
  //
  //       final filtered = all.where((job) {
  //         final title    = job.title.toString().toLowerCase();
  //         final location = job.location.toString().toLowerCase();
  //         final status   = job.status.toString().toLowerCase();
  //         final jobtype  = job.jobtype.toString().toLowerCase();
  //         final jobmode  = job.mode.toString().toLowerCase();
  //         final companyname  = job.companyname.toString().toLowerCase();
  //         return title.contains(query) ||
  //             location.contains(query) ||
  //             status.contains(query) ||
  //             jobtype.contains(query) ||
  //             jobmode.contains(query) ||
  //             companyname.contains(query);
  //       }).toList();
  //
  //       // search mode me hasMore=false (sab dikh chuka)
  //       emit(TpoJobLoaded(jobs: filtered, hasMore: false));
  //     } catch (e) {
  //       emit(TpoJobError("Search failed: $e"));
  //     }
  //   }

  Future<void> _onSearchJobs(
    SearchTpoJobs event,
    Emitter<TpoHomeState> emit,
  ) async {
    final raw = event.query;
    final query = raw.toLowerCase().trim();
    _currentSearchQuery = query;

    // Empty query => normal list (allow pagination again)
    if (query.isEmpty) {
      emit(
        TpoJobLoaded(jobs: List<TpoHomeJobModel>.from(_allJobs), hasMore: true),
      );
      return;
    }

    try {
      // Step 1: ensure cache is present
      if (_cacheAll.isEmpty || !_cacheIsFresh()) {
        emit(TPOJobLoading()); // brief spinner only when we fetch ALL
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token == null) {
          emit(TpoJobError("Token not found."));
          return;
        }

        final body = {
          "company_name": "",
          "job_type": "",
          "job_title": "",
          "work_culuture": "",
          "job_status": "",
          "course": "",
          "location": "",
          "page": "", // ALL
          "rows": "", // ALL
        };

        final resp = await http.post(
          Uri.parse('${BASE_URL}jobs'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );

        if (resp.statusCode != 200) {
          emit(TpoJobError("Failed to load jobs: ${resp.statusCode}"));
          return;
        }

        final decoded = jsonDecode(resp.body);
        final List<dynamic> data = decoded['data'] ?? [];
        _cacheAll = data.map((j) => TpoHomeJobModel.fromJson(j)).toList();
        _cacheAt = DateTime.now();
      }

      // Step 2: normalize & filter locally (fast)
      final qn = _norm(query);

      // synonyms mapping (optional, helps users)
      final bool wantsOnsite = [
        'inoffice',
        'onsite',
        'on-site',
        'office',
      ].map(_norm).contains(qn);
      final bool wantsRemote = [
        'remote',
        'wfh',
        'workfromhome',
      ].map(_norm).contains(qn);

      final filtered = _cacheAll.where((job) {
        final title = job.title.toString();
        final location = job.location.toString();
        final status = job.status.toString();
        final jobtype = job.jobtype.toString();
        final jobmode = job.mode.toString();
        final companyname = job.companyname.toString();

        // normalized
        final nTitle = _norm(title);
        final nLocation = _norm(location);
        final nStatus = _norm(status);
        final nJobtype = _norm(jobtype);
        final nJobmode = _norm(jobmode);
        final nCompanyname = _norm(companyname);

        final baseMatch =
            nTitle.contains(qn) ||
            nLocation.contains(qn) ||
            nStatus.contains(qn) ||
            nJobtype.contains(qn) ||
            nJobmode.contains(qn) ||
            nCompanyname.contains(qn);

        // handle synonyms for in-office/onsite and remote
        final onsiteMatch =
            wantsOnsite &&
            (nJobmode.contains('onsite') ||
                nJobmode.contains('inoffice') ||
                nJobtype.contains('onsite') ||
                nJobtype.contains('inoffice'));

        final remoteMatch =
            wantsRemote &&
            (nJobmode.contains('remote') ||
                nJobmode.contains('wfh') ||
                nJobtype.contains('remote') ||
                nJobtype.contains('wfh'));

        return baseMatch || onsiteMatch || remoteMatch;
      }).toList();

      // Search mode => no pagination
      emit(TpoJobLoaded(jobs: filtered, hasMore: false));
    } catch (e) {
      emit(TpoJobError("Search failed: $e"));
    }
  }

  // void _onSearchJobs(SearchTpoJobs event, Emitter<TpoHomeState> emit) {
  //   final query = event.query.toLowerCase().trim();
  //   _currentSearchQuery = query;
  //
  //   // if no query -> return full list
  //   if (query.isEmpty) {
  //     emit(TpoJobLoaded(jobs: List<TpoHomeJobModel>.from(_allJobs), hasMore: true));
  //     return;
  //   }
  //
  //   if (_allJobs.isEmpty) {
  //     // No local data yet — you can either trigger a fresh load or return empty
  //     emit(TpoJobLoaded(jobs: [], hasMore: false));
  //     return;
  //   }
  //
  //   final filtered = _allJobs.where((job) {
  //     final title = job.title.toString().toLowerCase();
  //     final location = job.location.toString().toLowerCase();
  //     final status = job.status.toString().toLowerCase();
  //     final jobtype = job.jobtype.toString().toLowerCase();
  //     final jobmode = job.mode.toString().toLowerCase();
  //     return title.contains(query) ||
  //         location.contains(query) ||
  //         status.contains(query) ||
  //         jobtype.contains(query) ||
  //         jobmode.contains(query);
  //   }).toList();
  //
  //   emit(TpoJobLoaded(jobs: filtered, hasMore: false));
  // }
}
