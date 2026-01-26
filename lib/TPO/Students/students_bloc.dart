
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Constant/constants.dart';
import 'students_event.dart';
import 'students_state.dart';
import '../Model/c_model.dart';

class InstituteBloc extends Bloc<InstituteEvent, InstituteState> {
  InstituteBloc() : super(const InstituteInitial()) {
    // Legacy -> map to new path (1-based)
    on<LoadInstitutes>(_onLoadLegacy);
    // NEW: search event
    on<InstituteSearchEvent>(_onSearch);
    // New events
    on<ResetInstitutes>(_onReset);
    on<FetchInstitutes>(_onFetchPaginated);
  }

  // Aggregated list for pagination
  final List<InstituteModel> _paginatedInstitutes = [];

  // Re-entrancy guard
  bool _inFlight = false;
  // 🔢 latest request tracker (stale response ignore karne ke liye)
  int _requestId = 0;

  // Last known paging
  int _lastPage = 1;   // 1-based
  int _lastLimit = 5;

  // Active filters
  String _collegeName = '';
  String _courseId = '';
  String _passoutYear = '';
  String _studentName = '';
  String _status = '';

  // ------- Handlers -------

  // Backward-compat: LoadInstitutes (strings) -> FetchInstitutes (1-based int)
  Future<void> _onLoadLegacy(
      LoadInstitutes event,
      Emitter<InstituteState> emit,
      ) async {
    final limitInt  = int.tryParse(event.limit)  ?? 5;
    final offsetInt = int.tryParse(event.offset) ?? -1;

    int pageOne;
    if (offsetInt >= 0 && limitInt > 0) {
      pageOne = (offsetInt ~/ limitInt) + 1;           // 1-based
    } else {
      final parsed = int.tryParse(event.page) ?? 1;
      pageOne = parsed <= 0 ? 1 : parsed;              // never below 1
    }

    add(FetchInstitutes(
      collegeName: event.collegeName,
      courseId: event.courseId,
      passoutYear: event.passoutYear,
      studentName: event.studentName,
      status: event.status,
      page: pageOne,        // 1-based
      limit: limitInt,
    ));
  }

  Future<void> _onReset(
      ResetInstitutes event,
      Emitter<InstituteState> emit,
      ) async {
    _paginatedInstitutes.clear();
    _lastPage = 1;
    _lastLimit = 5;

    _collegeName = event.collegeName;
    _courseId    = event.courseId;
    _passoutYear = event.passoutYear;
    _studentName = event.studentName;
    _status      = event.status;

    emit(const InstituteLoading());

    // First page = 1 (1-based)
    add(FetchInstitutes(
      collegeName: _collegeName,
      courseId: _courseId,
      passoutYear: _passoutYear,
      studentName: _studentName,
      status: _status,
      page: 1,
      limit: _lastLimit,
    ));
  }

  // Future<void> _onFetchPaginated(
  //     FetchInstitutes event,
  //     Emitter<InstituteState> emit,
  //     ) async {
  //   if (_inFlight) return;
  //   _inFlight = true;
  //
  //   // ✅ page kabhi 0 se niche nahi
  //   final int pageOne = event.page <= 0 ? 1 : event.page;
  //
  //   // Active filters + paging remember
  //   _collegeName = event.collegeName;
  //   _courseId    = event.courseId;
  //   _passoutYear = event.passoutYear;
  //   _studentName = event.studentName;
  //   _status      = event.status;
  //   _lastPage    = pageOne;
  //   _lastLimit   = event.limit;
  //
  //   // 🔑 StudentBloc jaisa pattern:
  //   // page 1 => limit 5
  //   // page 2 => limit 10  (pehle 10 records)
  //   // page 3 => limit 15  (pehle 15 records) ...
  //   final int effectiveLimit = pageOne * event.limit;
  //
  //   final bool isNextPage = pageOne > 1;
  //
  //   // Bottom loader ke liye
  //   if (state is InstituteLoaded && isNextPage) {
  //     emit((state as InstituteLoaded).copyWith(isFetchingMore: true));
  //   } else if (state is! InstituteLoading) {
  //     emit(const InstituteLoading());
  //   }
  //
  //   final startedAt   = DateTime.now();
  //   const minSpinner  = Duration(seconds: 1);
  //
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('auth_token');
  //     if (token == null || token.isEmpty) {
  //       emit(const InstituteError('Token not found'));
  //       return;
  //     }
  //
  //     final url = Uri.parse('${BASE_URL}tpo/student-listing');
  //
  //     final body = {
  //       "college_name": _collegeName,
  //       "course_id": _courseId,
  //       "passout_year": _passoutYear,
  //       "student_name": _studentName,
  //       "status": _status,
  //
  //       // ⬇️ BACKEND ko hamesha "pehle N records" maang rahe hain
  //       "limit":  effectiveLimit.toString(),
  //       "offset": "0",      // ❗ important: offset 0 hi rakho
  //       "page":   "1",      // optional, but safe
  //     };
  //
  //     final resp = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //         'Accept': 'application/json',
  //       },
  //       body: jsonEncode(body),
  //     );
  //
  //     if (resp.statusCode != 200) {
  //       emit(InstituteError('Failed with ${resp.statusCode}'));
  //       return;
  //     }
  //
  //     final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
  //     final parsed  = InstituteListingResponse.fromJson(jsonMap);
  //
  //     if (!parsed.success) {
  //       emit(const InstituteError('API returned success=false'));
  //       return;
  //     }
  //
  //     final List<InstituteModel> newFullList = parsed.data;
  //
  //
  //     // thoda spinner time maintain karo next pages pe
  //     if (isNextPage) {
  //       final elapsed = DateTime.now().difference(startedAt);
  //       if (elapsed < minSpinner) {
  //         await Future.delayed(minSpinner - elapsed);
  //       }
  //     }
  //
  //     // 🧠 IMPORTANT:
  //     // ab append nahi, hamesha REPLACE karna hai
  //     _paginatedInstitutes
  //       ..clear()
  //       ..addAll(newFullList);
  //
  //     final bool hasMore = newFullList.length == effectiveLimit;
  //
  //     emit(InstituteLoaded(
  //       institutes:     List.unmodifiable(_paginatedInstitutes),
  //       meta:           parsed.meta,
  //       hasMore:        hasMore,
  //       isFetchingMore: false,
  //     ));
  //   } catch (e) {
  //     emit(InstituteError(e.toString()));
  //   } finally {
  //     _inFlight = false;
  //   }
  // }

  Future<void> _onFetchPaginated(
      FetchInstitutes event,
      Emitter<InstituteState> emit,
      ) async {
    // ✅ NEW:
    // - Agar next page (page > 1) hai → guard with _inFlight (infinite scroll ke liye)
    // - Agar page == 1 hai (search / filter reset) → hamesha allow karo
    if (_inFlight && event.page > 1) return;

    _inFlight = true;
    final int currentRequestId = ++_requestId; // is request ka unique id

    // ✅ page kabhi 0 se niche nahi
    final int pageOne = event.page <= 0 ? 1 : event.page;

    // Active filters + paging remember
    _collegeName = event.collegeName;
    _courseId    = event.courseId;
    _passoutYear = event.passoutYear;
    _studentName = event.studentName;
    _status      = event.status;
    _lastPage    = pageOne;
    _lastLimit   = event.limit;

    // 🔑 StudentBloc jaisa pattern:
    // page 1 => limit 5
    // page 2 => limit 10  (pehle 10 records)
    // page 3 => limit 15  (pehle 15 records) ...
    final int effectiveLimit = pageOne * event.limit;

    final bool isNextPage = pageOne > 1;

    // Bottom loader ke liye
    if (state is InstituteLoaded && isNextPage) {
      emit((state as InstituteLoaded).copyWith(isFetchingMore: true));
    } else if (state is! InstituteLoading) {
      emit(const InstituteLoading());
    }

    final startedAt   = DateTime.now();
    const minSpinner  = Duration(seconds: 1);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        // stale check
        if (currentRequestId != _requestId) return;
        emit(const InstituteError('Token not found'));
        return;
      }

      final url = Uri.parse('${BASE_URL}tpo/student-listing');

      final body = {
        "college_name": _collegeName,
        "course_id": _courseId,
        "passout_year": _passoutYear,
        "student_name": _studentName,
        "status": _status,

        // ⬇️ BACKEND ko hamesha "pehle N records" maang rahe hain
        "limit":  effectiveLimit.toString(),
        "offset": "0",      // ❗ important: offset 0 hi rakho
        "page":   "1",      // optional, but safe
      };

      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode != 200) {
        if (currentRequestId != _requestId) return; // stale => ignore
        emit(InstituteError('Failed with ${resp.statusCode}'));
        return;
      }

      final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
      final parsed  = InstituteListingResponse.fromJson(jsonMap);

      if (!parsed.success) {
        if (currentRequestId != _requestId) return;
        emit(const InstituteError('API returned success=false'));
        return;
      }

      final List<InstituteModel> newFullList = parsed.data;

      // thoda spinner time maintain karo next pages pe
      if (isNextPage) {
        final elapsed = DateTime.now().difference(startedAt);
        if (elapsed < minSpinner) {
          await Future.delayed(minSpinner - elapsed);
        }
      }

      // ⚠️ Stale check: agar is beech me koi naya request aa chuka,
      // toh is result ko ignore kar do
      if (currentRequestId != _requestId) return;

      // 🧠 Ab hamesha REPLACE karna hai
      _paginatedInstitutes
        ..clear()
        ..addAll(newFullList);

      final bool hasMore = newFullList.length == effectiveLimit;

      emit(InstituteLoaded(
        institutes:     List.unmodifiable(_paginatedInstitutes),
        meta:           parsed.meta,
        hasMore:        hasMore,
        isFetchingMore: false,
      ));
    } catch (e) {
      if (currentRequestId != _requestId) return; // stale => ignore
      emit(InstituteError(e.toString()));
    } finally {
      // Sirf latest request hi _inFlight reset kare
      if (currentRequestId == _requestId) {
        _inFlight = false;
      }
    }
  }



  Future<void> _onSearch(
      InstituteSearchEvent event,
      Emitter<InstituteState> emit,
      ) async {
    final term = event.search.trim();

    // koi bhi purana fetch guard block na kare
    _inFlight = false;

    // 🔹 pagination + cache reset
    _paginatedInstitutes.clear();
    _lastPage  = 1;
    _lastLimit = 5;

    // 🔹 filters set (sirf studentName use ho raha hai abhi)
    _collegeName = '';
    _courseId    = '';
    _passoutYear = '';
    _studentName = term;   // empty string => full list
    _status      = '';

    // loading state
    emit(const InstituteLoading());

    // 🔹 actual API call sirf yahan se hoga → _onFetchPaginated me
    add(FetchInstitutes(
      collegeName: _collegeName,
      courseId: _courseId,
      passoutYear: _passoutYear,
      studentName: _studentName,
      status: _status,
      page: 1,           // hamesha page 1 se
      limit: _lastLimit, // 5
    ));
  }

//
  // Future<void> _onSearch(
  //     InstituteSearchEvent event,
  //     Emitter<InstituteState> emit,
  //     ) async {
  //   final term = event.search.trim();
  //
  //   // 🔹 1) Agar search EMPTY hai → normal full list reload
  //   if (term.isEmpty) {
  //     // koi purana inFlight guard block na kare
  //     _inFlight = false;
  //
  //     // filters reset
  //     _collegeName = '';
  //     _courseId    = '';
  //     _passoutYear = '';
  //     _studentName = '';
  //     _status      = '';
  //
  //     _paginatedInstitutes.clear();
  //     _lastPage  = 1;
  //     _lastLimit = 5;
  //
  //     emit(const InstituteLoading());
  //
  //     add(const FetchInstitutes(
  //       collegeName: '',
  //       courseId: '',
  //       passoutYear: '',
  //       studentName: '',
  //       status: '',
  //       page: 1,
  //       limit: 5,
  //     ));
  //     return;
  //   }
  //
  //   // 🔹 2) Non-empty search → NEW FILTER, page=1 se start karo
  //   _inFlight = false; // koi bhi pending fetch ignore
  //   _lastPage  = 1;
  //   _lastLimit = 5;
  //
  //   _collegeName = '';
  //   _courseId    = '';
  //   _passoutYear = '';
  //   _studentName = term; // 👈 search term ko active filter banao
  //   _status      = '';
  //
  //   emit(const InstituteLoading());
  //
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('auth_token');
  //     if (token == null || token.isEmpty) {
  //       emit(const InstituteError('Token not found'));
  //       return;
  //     }
  //
  //     final url = Uri.parse('${BASE_URL}tpo/student-listing');
  //     const int limit = 5;
  //
  //     final body = {
  //       "college_name": _collegeName,
  //       "course_id": _courseId,
  //       "passout_year": _passoutYear,
  //       "student_name": _studentName, // 👈 yahi pe search jaa raha
  //       "status": _status,
  //       "limit": limit.toString(),
  //       "offset": "0",
  //       "page": "1",
  //     };
  //
  //     final resp = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //         'Accept': 'application/json',
  //       },
  //       body: jsonEncode(body),
  //     );
  //
  //     if (resp.statusCode != 200) {
  //       emit(InstituteError('Failed with ${resp.statusCode}'));
  //       return;
  //     }
  //
  //     final json = jsonDecode(resp.body) as Map<String, dynamic>;
  //     final parsed = InstituteListingResponse.fromJson(json);
  //
  //     if (!parsed.success) {
  //       emit(const InstituteError('API returned success=false'));
  //       return;
  //     }
  //
  //     final List<InstituteModel> firstPage = parsed.data;
  //
  //     // ⬇️ SABSE IMPORTANT PART:
  //     // search ke result ko pagination cache ke saath sync karo
  //     _paginatedInstitutes
  //       ..clear()
  //       ..addAll(firstPage);
  //
  //     final bool hasMore = firstPage.length == limit;
  //
  //     emit(InstituteLoaded(
  //       institutes: List.unmodifiable(_paginatedInstitutes),
  //       meta: parsed.meta,
  //       hasMore: hasMore,
  //       isFetchingMore: false,
  //     ));
  //   } catch (e) {
  //     emit(InstituteError(e.toString()));
  //   }
  // }



}
