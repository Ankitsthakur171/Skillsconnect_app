import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Constant/constants.dart';
import '../../model/applicant_model.dart';
import '../../model/college_invitation_model.dart';
import 'college_event.dart';
import 'college_state.dart';

class CollegeInviteBloc extends Bloc<CollegeEvent, CollegeState> {
  final int _perPage = 5; // Items per page
  // 🔹 yeh line ADD KARO sabse upar (class ke andar)
  String _lastInviteCount = '';
  CollegeCriteria _criteria = const CollegeCriteria(); // active filters

  // 🔹 optional: ek public getter (UI me use karne ke liye)
  String get inviteCountLabel => _lastInviteCount;
  // CollegeInviteBloc ke andar (top par) yeh helpers add kar do:

  String _formatInviteLabel(String raw) {
    if (raw.isEmpty) return raw;
    // "Invited 0/20" -> "Invited (0/20)"
    final m = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(raw);
    if (m != null) return 'Invited (${m.group(1)}/${m.group(2)})';
    // safety: agar already bracketed ho to as-is
    if (raw.contains('(') && raw.contains(')')) return raw;
    return raw;
  }

  String _inviteKey(int jobId, String type) => 'invite_count_${jobId}_$type';


  CollegeInviteBloc() : super(CollegeInitial()) {
    on<LoadInitialColleges>(_onLoadInitialColleges);
    on<LoadMoreColleges>(_onLoadMoreColleges);
    on<SearchCollegeEvent>(_onSearchColleges);
    on<ApplyFilterCollegeEvent>(_onApplyFilterColleges);

  }
  List<College> allColleges = [];

  Future<void> _onLoadInitialColleges(
      LoadInitialColleges event,
      Emitter<CollegeState> emit,
      ) async {
    try {
      // 🔹 cached invite_count ko pehle set kar do (UI me turant dikh jayega)
      try {
        final sp = await SharedPreferences.getInstance();
        final cached = sp.getString(_inviteKey(event.jobId, event.type)) ?? '';
        if (cached.isNotEmpty) {
          _lastInviteCount = cached; // UI: bloc.inviteCountLabel se mil jayega
        }
      } catch (_) {}

      _criteria = _criteria.copyWith(
        collegeName: event.collegeName,
        selectedState: event.selectedState,
        selectedcity: event.selectedcity,
        collegestatus: event.collegestatus,
        instituteType: event.instituteType,
        course: event.course,
        naacgrade: event.naacgrade,
        mylistname: event.mylistname,
        specialization: event.specialization,
        type: event.type,
      );

      emit(CollegeLoading(colleges: state.colleges));

      final colleges = await _fetchColleges(
        page: 1,
        jobId: event.jobId,
        collegeName: _criteria.collegeName,
        statename: _criteria.selectedState,
        city: _criteria.selectedcity,
        collgeStatus: _criteria.collegestatus,
        instituteType: _criteria.instituteType,
        course: _criteria.course,
        naac: _criteria.naacgrade,
        type: _criteria.type,

      );


//  Save to allColleges so search can use it
      allColleges = colleges;

      emit(CollegeLoaded(
        colleges: colleges,
        hasReachedMax: colleges.length < _perPage,
        currentPage: 1,
        type: _criteria.type,

      ));
    } catch (e) {
      emit(CollegeError(
        error: e.toString(),
        colleges: state.colleges,
      ));
    }
  }

  Future<void> _onLoadMoreColleges(
      LoadMoreColleges event,
      Emitter<CollegeState> emit,
      ) async {
    if (state is! CollegeLoaded) return;
    final currentState = state as CollegeLoaded;

    if (currentState.hasReachedMax) return;

    try {
      emit(currentState.copyWith()); // Show loading in UI

      final colleges = await _fetchColleges(
        page: currentState.currentPage + 1,
        jobId: event.jobId,
        collegeName: _criteria.collegeName,
        city: _criteria.selectedcity,
        statename: _criteria.selectedState,
        collgeStatus: _criteria.collegestatus,
        instituteType: _criteria.instituteType,
        course: _criteria.course,
        naac: _criteria.naacgrade,
        mylist : _criteria.mylistname,
        speacilization : _criteria.specialization,
        type: _criteria.type,

      );

      //  Append to full list for search
      allColleges += colleges;

      emit(colleges.isEmpty
          ? currentState.copyWith(hasReachedMax: true)
          : CollegeLoaded(
        colleges: currentState.colleges + colleges,
        hasReachedMax: colleges.length < _perPage,
        currentPage: currentState.currentPage + 1,
        type: _criteria.type,
      ));
    } catch (e) {
      emit(CollegeError(
        error: e.toString(),
        colleges: currentState.colleges,
      ));
    }
  }

  //   Future<void> _onSearchColleges(
  //     SearchCollegeEvent event, Emitter<CollegeState> emit) async {
  //   try {
  //     emit(CollegeLoading(colleges: state.colleges));
  //
  //     final colleges = await _fetchColleges(
  //       page: 1,
  //       jobId: event.jobId,
  //       collegeName: event.query,
  //       statename: event.selectedState,
  //       city: event.selectedcity,
  //       type: event.type,
  //     );
  //
  //     emit(CollegeLoaded(
  //       colleges: colleges,
  //       hasReachedMax: colleges.length < _perPage,
  //       currentPage: 1,
  //       type: event.type,
  //     ));
  //   } catch (e) {
  //     emit(CollegeError(error: e.toString(), colleges: state.colleges));
  //   }
  // }


  Future<void> _onSearchColleges(
      SearchCollegeEvent event,
      Emitter<CollegeState> emit,
      ) async {
    try {
      emit(CollegeLoading(colleges: state.colleges));

      // query ko active criteria me inject karo (baaki same filters)
      final criteriaForSearch = _criteria.copyWith(collegeName: event.query);

      final colleges = await _fetchColleges(
        page: event.page,                 // usually 1 on first search
        jobId: event.jobId,
        // 🔑 query ko backend param "college_name" me bhejo
        collegeName: criteriaForSearch.collegeName,
        statename: criteriaForSearch.selectedState,
        city: criteriaForSearch.selectedcity,
        collgeStatus: criteriaForSearch.collegestatus,
        instituteType: criteriaForSearch.instituteType,
        course: criteriaForSearch.course,
        naac: criteriaForSearch.naacgrade,
        mylist: criteriaForSearch.mylistname,
        speacilization: criteriaForSearch.specialization,
        type: criteriaForSearch.type,
      );

      // NOTE: search ke baad bhi criteria me query rakhna chahte ho to _criteria = criteriaForSearch; kar do
      _criteria = criteriaForSearch;

      emit(CollegeLoaded(
        colleges: colleges,
        hasReachedMax: colleges.length < _perPage,
        currentPage: event.page,
        type: criteriaForSearch.type,
      ));
    } catch (e) {
      emit(CollegeError(error: e.toString(), colleges: state.colleges));
    }
  }


  Future<void> _onApplyFilterColleges(
      ApplyFilterCollegeEvent event,
      Emitter<CollegeState> emit,
      ) async {
    try {

      _criteria = _criteria.copyWith(
        collegeName: event.collegeName ?? '',
        selectedState: event.selectedState ?? '',
        selectedcity: event.selectedcity ?? '',
        collegestatus: event.collegestatus ?? '',
        instituteType: event.instituteType ?? '',
        course: event.course ?? '',
        naacgrade: event.naacgrade ?? '',
        mylistname: event.mylistname ?? '',
        specialization: event.specialization ?? '',
        type: event.type,
      );
      // 🔹 Start log
      print("----------------------------------------------------");
      print("🎯 [CollegeBloc] _onApplyFilterColleges() called");

      emit(CollegeLoading(colleges: []));

      final colleges = await _fetchColleges(
        page: 1,
        jobId: event.jobId,
        collegeName: _criteria.collegeName ?? '', // Search query not needed for filter
        statename: _criteria.selectedState ?? '',
        city: _criteria.selectedcity ?? '',
        collgeStatus: _criteria.collegestatus ?? '',
        instituteType: _criteria.instituteType ?? '',
        course: _criteria.course ?? '',
        naac: _criteria.naacgrade ?? '',
        mylist: _criteria.mylistname ?? '',
        speacilization: _criteria.specialization ?? '',
        type: _criteria.type,
      );

      print("✅ Colleges fetched successfully: ${colleges.length}");
      if (colleges.isNotEmpty) {
        print("📋 First college: ${colleges.first}");
      }


      emit(CollegeLoaded(
        colleges: colleges,
        hasReachedMax: colleges.length < _perPage,
        currentPage: 1,
        type: _criteria.type,
      ));
    } catch (e) {
      emit(CollegeError(
        error: e.toString(),
        colleges: state.colleges,
      ));
    }
  }





  Future<List<College>> _fetchColleges({
    required int page,
    required int jobId,
    String collegeName = '',
    String city = '',
    String statename = '',
    String collgeStatus = '',
    String instituteType = '',
    String course = '',
    String naac = '',
    String mylist = '',
    String speacilization = '',
    String type = 'invitation', //  default to 'invitation'

  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('${BASE_URL}job/dashboard/college-invite'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "college_name": collegeName,
        "city": city,
        "collge_status": collgeStatus ?? 'Invited',
        "institute_type": instituteType,
        "course": course,
        "state": statename,
        "naac_grade": naac,
        "mylist": mylist,
        "specialization": speacilization,
        "limit": _perPage,
        "page": page,
        "job_id": jobId,
        "type": type,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);

// 🔹 format + store in bloc + cache
      try {
        final raw = (jsonBody['invite_count'] ?? '').toString();       // e.g. "Invited 0/20"
        final formatted = _formatInviteLabel(raw);                      // -> "Invited (0/20)"
        _lastInviteCount = formatted;

        final sp = await SharedPreferences.getInstance();
        // 'type' local param hi use ho raha (invitation / invited)
        await sp.setString(_inviteKey(jobId, type), formatted);
      } catch (_) {}
      final data = jsonBody['data'];

      if (data != null && data is List) {
        return data.map((e) => College.fromJson(e,type)).toList();
        final String inviteCount = (jsonBody['invite_count'] ?? '').toString(); // 👈 "Invited 0/20"

      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load colleges: ${response.statusCode}');
    }
  }


  // -------------------- Search --------------------
  //
  //
  //
  // void _onSearchColleges(SearchCollegeEvent event, Emitter<CollegeState> emit) {
  //   final query = event.query.toLowerCase().trim();
  //
  //   final filteredColleges = allColleges.where((colleges) {
  //     final title = colleges.name.toLowerCase();
  //     final location = colleges.statename.toLowerCase();
  //     // final status = job.status.toLowerCase();
  //
  //     return title.contains(query) || location.contains(query);
  //   }).toList();
  //   final currentType = (state is CollegeLoaded) ? (state as CollegeLoaded).type : 'invitation';
  //
  //
  //   emit(CollegeLoaded(colleges: filteredColleges,  hasReachedMax: true,
  //       currentPage: 1,
  //       type: currentType));
  // }

}
