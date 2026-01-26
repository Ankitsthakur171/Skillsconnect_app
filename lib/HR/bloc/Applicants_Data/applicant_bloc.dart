//  import 'dart:async';
// import 'dart:convert';
//   import 'package:flutter/cupertino.dart';
//   import 'package:flutter_bloc/flutter_bloc.dart';
//   import 'package:http/http.dart' as http;
//   import 'package:shared_preferences/shared_preferences.dart';
//   import '../../../Constant/constants.dart';
// import 'applicant_event.dart';
//   import 'applicant_state.dart';
//   import '../../model/applicant_model.dart';
//   import '../../model/job_model.dart';
//
//
//   class ApplicantBloc extends Bloc<ApplicantDataEvent, ApplicantState> {
//     final int _perPage = 5;
//     List<ApplicantModel> _allApplicants = [];
//     List<ApplicationStage> _applicationStages = [];
//     String? _currentSearchQuery;
//     // ✅ filter mode state
//     bool _isFilterMode = false;
//     Map<String, String> _activeFilter = {};
//     String _activeDate = "";
//     String _activeEmailId = "";
//     String _activeProcessId = "";
//     String _activeStatusId = "";
//
//
//     Map<String, String> _defaultFilter() => {
//       "name": "",
//       "college_name": "",
//       "process_name": "",
//       "application_status_name": "",
//       "current_degree": "",
//       "current_course_name": "",
//       "current_specialization_name": "",
//       "current_passing_year": "",
//       "perfered_location1": "",
//       "current_location": "",
//       "remarks": "",
//       "state": "",
//       "gender": "",
//       "college_city": "",
//       "college_state": "",
//       "assessment_status": ""
//     };
//
//
//
//     ApplicantBloc() : super(ApplicantInitial()) {
//       on<LoadDataApplicants>(_onLoadApplicants);
//       on<SearchApplicantEvent>(_onSearchApplicants);
//       on<LoadMoreApplicants>(_onLoadMoreApplicants);
//       // 👇 inline anonymous ko remove karke is named handler ko use karo
//       on<ApplyApplicantFilter>(_onApplyApplicantFilter);
//       on<LoadAllApplicantsCount>(_onLoadAllApplicantsCount);
//
//     }
//
//
//     Future<void> _onLoadApplicants(
//         LoadDataApplicants event,
//         Emitter<ApplicantState> emit,
//         ) async {
//       try {
//         emit(ApplicantLoading(applicants: []));
//         final query = _currentSearchQuery?.trim() ?? '';
//
//         // ✅ reset filter mode
//         _isFilterMode = false;
//         _activeFilter = {};
//         _activeDate = _activeEmailId = _activeProcessId = _activeStatusId = "";
//
//         final response = await _fetchApplicantResponse(
//           job: event.job,
//           page: 1,
//           query: query,
//         );
//
//         final filtered = _parseApplicantsFromResponse(response);
//
//         _allApplicants = _parseApplicantsFromResponse(response);
//         _applicationStages = _parseStagesFromResponse(response);
//         final processes = _parseProcessesFromResponse(response);
//         // ✅ First page par hi end detect:
//         final bool reachedEnd = _allApplicants.length < _perPage;
//
//         emit(ApplicantLoaded(
//           applicants: filtered,
//           hasReachedMax:  _allApplicants.length < _perPage, // ✅ No more loading
//           currentPage: 1,
//           applicationStages: _applicationStages,
//           processList: processes,   // ✅ now parsed list
//           searchQuery: null,
//           // searchQuery: _currentSearchQuery,
//           // isLoadingMore: false,
//         ));
//       } catch (e) {
//         emit(ApplicantError(
//           'Failed to load applicants: ${e.toString()}',
//           applicants: [],
//         ));
//       }
//     }
//
//
//     Future<void> _onLoadMoreApplicants(
//         LoadMoreApplicants event,
//         Emitter<ApplicantState> emit,
//         ) async {
//       if (state is! ApplicantLoaded) return;
//
//       final currentState = state as ApplicantLoaded;
//
//       // Search mode me load more disabled hi rahe
//       if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) return;
//
//       // Agar pehle se end a chuka ya already loading ho to return
//       if (currentState.hasReachedMax || currentState.isLoadingMore) return;
//
//       emit(currentState.copyWith(isLoadingMore: true, errorMessage: null));
//
//       try {
//         final prefs = await SharedPreferences.getInstance();
//         final token = prefs.getString('auth_token');
//
//         final nextPage  = currentState.currentPage + 1;
//         final nextLimit = nextPage * _perPage; // cumulative: 10, 15, 20...
//
//         Map<String, dynamic> body;
//         if (_isFilterMode) {
//           body = {
//             "job_id": event.job.jobId,
//             "offset": 0,
//             "limit": nextLimit,
//             "filter": _activeFilter.isEmpty ? _defaultFilter() : _activeFilter,
//             "date": _activeDate,
//             "email_id": _activeEmailId,
//             "process_id": _activeProcessId,
//             "status_id": _activeStatusId,
//           };
//         } else {
//           body = {
//             "job_id": event.job.jobId,
//             "offset": 0,
//             "limit": nextLimit,
//             "filter": _defaultFilter(),
//             "date": "",
//             "email_id": "",
//             "process_id": "",
//             "status_id": "",
//           };
//         }
//
//         final response = await http.post(
//           Uri.parse('${BASE_URL}job/dashboard/application-listing'),
//           headers: {
//             'Content-Type': 'application/json',
//             if (token != null) 'Authorization': 'Bearer $token',
//           },
//           body: jsonEncode(body),
//         );
//
//         if (response.statusCode != 200) {
//           emit(currentState.copyWith(
//             errorMessage: 'API Error: ${response.statusCode}',
//             isLoadingMore: false,
//           ));
//           return;
//         }
//
//         final decoded    = jsonDecode(response.body);
//         final cumulative = _parseApplicantsFromResponse(decoded); // 1..N latest snapshot
//
//         // ✅ Agar server ne same size ya chhota diya jitna already _allApplicants me hai,
//         // ya bilkul empty diya —> end reached. Loader band.
//         if (cumulative.isEmpty || cumulative.length <= _allApplicants.length) {
//           emit(currentState.copyWith(
//             hasReachedMax: true,
//             isLoadingMore: false,
//           ));
//           return;
//         }
//
//         // ✅ New unique items nikaalo
//         final uniqueNew = cumulative.where(
//               (x) => !_allApplicants.any((y) => y.application_id == x.application_id),
//         ).toList();
//
//         // Agar unique new zero aa gaya (server ne reorder diya) —> end treat karo
//         if (uniqueNew.isEmpty) {
//           emit(currentState.copyWith(
//             hasReachedMax: true,
//             isLoadingMore: false,
//           ));
//           return;
//         }
//
//         _allApplicants.addAll(uniqueNew);
//
//         // ✅ End condition:
//         //  - cumulative < nextLimit  (server ne requested se kam diya)
//         //  - ya latest batch me _perPage se kam naye aaye
//         final reachedEnd = (cumulative.length < nextLimit) || (uniqueNew.length < _perPage);
//
//         emit(ApplicantLoaded(
//           applicants: [...currentState.applicants, ...uniqueNew],
//           hasReachedMax: reachedEnd,
//           currentPage: nextPage,
//           applicationStages: currentState.applicationStages,
//           processList: currentState.processList,
//           searchQuery: currentState.searchQuery,
//           isLoadingMore: false,
//         ));
//       } catch (e) {
//         // Error pe loader band rakho
//         emit(currentState.copyWith(
//           errorMessage: 'Failed to load more: $e',
//           isLoadingMore: false,
//         ));
//       }
//     }
//
//
//     // Future<void> _onLoadMoreApplicants(
//     //     LoadMoreApplicants event,
//     //     Emitter<ApplicantState> emit,
//     //     ) async {
//     //   if (state is! ApplicantLoaded) return;
//     //
//     //   final currentState = state as ApplicantLoaded;
//     //
//     //   // searching? (tumne search ke liye load-more disable kiya hua hai)
//     //   if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) return;
//     //
//     //   if (currentState.hasReachedMax || currentState.isLoadingMore) return;
//     //
//     //   emit(currentState.copyWith(isLoadingMore: true));
//     //
//     //   try {
//     //     final prefs = await SharedPreferences.getInstance();
//     //     final token = prefs.getString('auth_token');
//     //
//     //     final nextPage = currentState.currentPage + 1;
//     //     final nextLimit = nextPage * _perPage; // 10, 15, 20...
//     //
//     //     Map<String, dynamic> body;
//     //
//     //     if (_isFilterMode) {
//     //       // ✅ FILTER MODE: offset=0, limit cumulative
//     //       body = {
//     //         "job_id": event.job.jobId,
//     //         "offset": 0,
//     //         "limit": nextLimit,
//     //         "filter": _activeFilter.isEmpty ? _defaultFilter() : _activeFilter,
//     //         "date": _activeDate,
//     //         "email_id": _activeEmailId,
//     //         "process_id": _activeProcessId,
//     //         "status_id": _activeStatusId,
//     //       };
//     //     } else {
//     //       // ✅ NORMAL MODE: tum already offset=0 + cumulative use kar rahe ho
//     //       body = {
//     //         "job_id": event.job.jobId,
//     //         "offset": 0,
//     //         "limit": nextLimit,
//     //         "filter": _defaultFilter(),
//     //         "date": "",
//     //         "email_id": "",
//     //         "process_id": "",
//     //         "status_id": "",
//     //       };
//     //     }
//     //
//     //     final response = await http.post(
//     //       Uri.parse('${BASE_URL}job/dashboard/application-listing'),
//     //       headers: {
//     //         'Content-Type': 'application/json',
//     //         if (token != null) 'Authorization': 'Bearer $token',
//     //       },
//     //       body: jsonEncode(body),
//     //     );
//     //
//     //     if (response.statusCode != 200) {
//     //       emit(currentState.copyWith(
//     //         errorMessage: 'API Error: ${response.statusCode}',
//     //         isLoadingMore: false,
//     //       ));
//     //       return;
//     //     }
//     //
//     //     final decoded = jsonDecode(response.body);
//     //     final cumulative = _parseApplicantsFromResponse(decoded); // 1..N items
//     //
//     //     // ✅ pick only new ones (avoid duplicates)
//     //     final uniqueNew = cumulative.where(
//     //           (x) => !_allApplicants.any((y) => y.application_id == x.application_id),
//     //     ).toList();
//     //
//     //     if (uniqueNew.isEmpty) {
//     //       // may be end or server re-ordered same items
//     //       final reached = cumulative.length < nextLimit;
//     //       emit(currentState.copyWith(
//     //         hasReachedMax: reached,
//     //         isLoadingMore: false,
//     //       ));
//     //       return;
//     //     }
//     //
//     //     _allApplicants.addAll(uniqueNew);
//     //
//     //     // ✅ end when server returned less than requested cumulative size
//     //     final reachedEnd = cumulative.length < nextLimit;
//     //
//     //     emit(ApplicantLoaded(
//     //       applicants: [...currentState.applicants, ...uniqueNew],
//     //       hasReachedMax: reachedEnd,
//     //       currentPage: nextPage,
//     //       applicationStages: currentState.applicationStages,
//     //       processList: currentState.processList,
//     //       searchQuery: currentState.searchQuery,
//     //       isLoadingMore: false,
//     //     ));
//     //   } catch (e) {
//     //     emit(currentState.copyWith(
//     //       errorMessage: 'Failed to load more: $e',
//     //       isLoadingMore: false,
//     //     ));
//     //   }
//     // }
//
//
//     //---------------------------Search Code----------------------//
//     void _onSearchApplicants(
//         SearchApplicantEvent event,
//         Emitter<ApplicantState> emit,
//         ) async {
//
//       // ApplicantBloc में, SearchApplicantEvent handler की शुरुआत में:
//       if (event.query.trim().isEmpty) {
//         add(LoadDataApplicants(event.job));
//         return;
//       }
//
//       try {
//         emit(ApplicantLoading(applicants: []));
//
//         final prefs = await SharedPreferences.getInstance();
//         final token = prefs.getString('auth_token');
//         final query = event.query.trim();
//
//         if (token == null) throw Exception("Missing token");
//
//         final response = await http.post(
//           Uri.parse('${BASE_URL}job/dashboard/application-listing'),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//           body: jsonEncode({
//             "job_id": event.job.jobId,
//             "offset": 0,
//             "limit": event.page * _perPage,
//             "filter": {
//               "name": query,
//               "college_name": "",
//               "process_name": "",
//               "application_status_name": "",
//               "current_degree": "",
//               "current_course_name": "",
//               "current_specialization_name": "",
//               "current_passing_year": "",
//               "perfered_location1": "",
//               "current_location": "",
//               "remarks": "",
//               "state": "",
//               "gender": "",
//               "college_city": "",
//               "college_state": "",
//               "assessment_status": ""
//             },
//             "date": "",
//             "email_id": "",
//             "process_id": "",
//             "status_id": ""
//           }),
//         );
//
//         if (response.statusCode == 200) {
//           final decoded = json.decode(response.body);
//           final List<dynamic> data = decoded['studentListing'] ?? [];
//
//           final applicants = data.map((e) => ApplicantModel.fromJson(e)).toList();
//
//           _allApplicants = applicants; // save to local
//           _currentSearchQuery = query;
//
//           emit(ApplicantLoaded(
//             applicants: applicants,
//             // hasReachedMax: true,
//             hasReachedMax: applicants.length < _perPage,  // ✅ अब search भी paginate होगा
//
//             currentPage: 1,
//             applicationStages: [],
//             searchQuery: query,
//           ));
//         } else {
//           emit(ApplicantError('API Error: ${response.statusCode}', applicants: []));
//         }
//       } catch (e) {
//         emit(ApplicantError('Search failed: $e', applicants: []));
//       }
//     }
//
//     //
//     // void _onSearchApplicants(
//     //     SearchApplicantEvent event,
//     //     Emitter<ApplicantState> emit,
//     //     ) {
//     //   if (state is! ApplicantLoaded) return;
//     //   final currentState = state as ApplicantLoaded;
//     //
//     //   _currentSearchQuery = event.query.toLowerCase().trim();
//     //
//     //   if (_currentSearchQuery!.isEmpty) {
//     //     emit(currentState.copyWith(
//     //       applicants: _allApplicants,
//     //       searchQuery: null,
//     //     ));
//     //     return;
//     //   }
//     //
//     //   final filtered = _allApplicants.where((applicant) {
//     //     return applicant.name.toLowerCase().contains(_currentSearchQuery!) ||
//     //         applicant.university.toLowerCase().contains(_currentSearchQuery!) ||
//     //         applicant.degree.toLowerCase().contains(_currentSearchQuery!);
//     //   }).toList();
//     //
//     //   emit(currentState.copyWith(
//     //     applicants: filtered,
//     //     searchQuery: _currentSearchQuery,
//     //   ));
//     // }
//     //
//
//     //---------------------------Search Code----------------------//
//
//
//     Future<dynamic> _fetchApplicantResponse({
//       required JobModel job,
//       required int page,
//       required String query,
//     }) async {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');
//
//       if (token == null) throw Exception('Authentication required');
//
//
//       final response = await http.post(
//         Uri.parse('${BASE_URL}job/dashboard/application-listing'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode({
//           'job_id': job.jobId,
//           'offset': 0,
//           'limit': page * _perPage,
//           'filter': {
//             'name': query,
//             'college_name': '',
//             'process_name': '',
//             'application_status_name': '',
//             'current_degree': '',
//             'current_course_name': '',
//             'current_specialization_name': '',
//             'current_passing_year': '',
//             'perfered_location1': '',
//             'current_location': '',
//             'remarks': '',
//             'state': '',
//             'gender': '',
//             'college_city': '',
//             'college_state': '',
//             'assessment_status': ''
//           },
//           'date': '',
//           'email_id': '',
//           'process_id': '',
//           'status_id': '',
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data;
//       } else {
//         final errorData = json.decode(response.body);
//         throw Exception(errorData['message'] ?? 'API error');
//       }
//     }
//
//
//
//     List<ApplicantModel> _parseApplicantsFromResponse(dynamic responseData) {
//       try {
//         final List<dynamic> applicantsData = responseData['studentListing'] ?? [];
//         return applicantsData.map((applicantJson) {
//           return ApplicantModel(
//             name: applicantJson['full_name'] ?? 'No Name',
//             university: applicantJson['college_name'] ?? 'Not Specified',
//             degree: applicantJson['current_degree'] ?? 'Not Specified',
//             grade: applicantJson['current_marks'] ?? 'Not Specified',
//             year: applicantJson['current_passing_year'] ?? 'N/A',
//             grade_type: applicantJson['grade_type'] ?? 'N/A',
//             application_id: int.tryParse(applicantJson['application_id'].toString()) ?? 0,
//             job_id: int.tryParse(applicantJson['job_id'].toString()) ?? 0,
//             user_id: int.tryParse(applicantJson['user_id'].toString()) ?? 0,
//             current_course_name: applicantJson['current_course_name'] ?? 'N/A',
//             application_status: applicantJson['application_status_name'] ?? 'Applied',
//           );
//         }).toList();
//       } catch (e) {
//         throw Exception('Failed to parse applicants data: $e');
//       }
//     }
//
//     List<ApplicationStage> _parseStagesFromResponse(dynamic responseData) {
//       try {
//         final stageList = responseData['applicationCountStage'] as List<dynamic>?;
//         if (stageList == null) return [];
//         return stageList.map((e) => ApplicationStage.fromJson(e)).toList();
//       } catch (e) {
//         throw Exception('Failed to parse application stages: $e');
//       }
//     }
//
//     Future<void> updateApplicationStatus({
//       required int jobId,
//       required int applicationId,
//       required String action,
//     }) async {
//       try {
//         final prefs = await SharedPreferences.getInstance();
//         final token = prefs.getString('auth_token');
//
//         if (token == null) {
//           throw Exception('Authentication token missing');
//         }
//
//         final response = await http.post(
//           Uri.parse('${BASE_URL}job/dashboard/update-application-status'),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//           body: json.encode({
//             "job_id": jobId,
//             "action": action,
//             "application_id_list": [applicationId],
//             "process_id": "",
//           }),
//         );
//
//         final responseData = json.decode(response.body);
//         if (response.statusCode != 200 || responseData["status"] != true) {
//           throw Exception(responseData["msg"] ?? "Status update failed");
//         }
//
//         // Update local state if successful
//         if (state is ApplicantLoaded) {
//           final currentState = state as ApplicantLoaded;
//           final updatedApplicants = currentState.applicants.map((applicant) {
//             if (applicant.application_id == applicationId) {
//               return applicant.copyWith(application_status: action);
//             }
//             return applicant;
//           }).toList();
//
//           _allApplicants = updatedApplicants;
//           emit(currentState.copyWith(applicants: updatedApplicants));
//         }
//       } catch (e) {
//         throw Exception('Failed to update status: ${e.toString()}');
//       }
//     }
//
//     Map<String, String> _removeEmptyValues(Map<String, String> original) {
//       return Map.fromEntries(
//         original.entries.where((e) => e.value.trim().isNotEmpty),
//       );
//     }
//
//     List<ProcessModel> _parseProcessesFromResponse(dynamic responseData) {
//       try {
//         final processList = responseData['processList'] as List<dynamic>?;
//         if (processList == null) return [];
//         return processList.map((e) => ProcessModel.fromJson(e)).toList();
//       } catch (e) {
//         throw Exception('Failed to parse process list: $e');
//       }
//     }
//
//
//     Future<void> _onApplyApplicantFilter(
//         ApplyApplicantFilter event,
//         Emitter<ApplicantState> emit,
//         ) async {
//       try {
//         emit(ApplicantLoading(applicants: []));
//
//         final prefs = await SharedPreferences.getInstance();
//         final token = prefs.getString('auth_token');
//
//         // ✅ activate filter mode + store filters for next pages
//         _isFilterMode = true;
//         _currentSearchQuery = null; // search mode off
//         _activeFilter = _removeEmptyValues(event.filters);
//         _activeDate      = event.filters["date"] ?? "";
//         _activeEmailId   = event.filters["email_id"] ?? "";
//         _activeProcessId = event.filters["process_id"] ?? "";
//         _activeStatusId  = event.filters["status_id"] ?? "";
//
//         final body = {
//           "job_id": event.jobId,
//           "offset": 0,             // always 0
//           "limit": _perPage,       // first page only 5
//           "filter": _activeFilter.isEmpty ? _defaultFilter() : _activeFilter,
//           "date": _activeDate,
//           "email_id": _activeEmailId,
//           "process_id": _activeProcessId,
//           "status_id": _activeStatusId,
//         };
//
//         final response = await http.post(
//           Uri.parse('${BASE_URL}job/dashboard/application-listing'),
//           headers: {
//             'Content-Type': 'application/json',
//             if (token != null) 'Authorization': 'Bearer $token',
//           },
//           body: jsonEncode(body),
//         );
//
//         if (response.statusCode != 200) {
//           emit(ApplicantError("API Error: ${response.statusCode}", applicants: []));
//           return;
//         }
//
//         final decoded = jsonDecode(response.body);
//         final List<dynamic> data = decoded['studentListing'] ?? [];
//         final applicants = data.map((e) => ApplicantModel.fromJson(e)).toList();
//
//         _allApplicants = List<ApplicantModel>.from(applicants);
//         _applicationStages = _parseStagesFromResponse(decoded);
//         final processes = _parseProcessesFromResponse(decoded);
//
//         emit(ApplicantLoaded(
//           applicants: applicants,
//           hasReachedMax: applicants.length < _perPage, // <5 => end
//           currentPage: 1,
//           applicationStages: _applicationStages,
//           processList: processes,
//           searchQuery: null,
//           isLoadingMore: false,
//         ));
//       } catch (e) {
//         emit(ApplicantError("Exception: $e", applicants: []));
//       }
//     }
//
//
//     Future<void> _onLoadAllApplicantsCount(
//         LoadAllApplicantsCount event,
//         Emitter<ApplicantState> emit,
//         ) async {
//       try {
//         final currentState = state;
//
//         final prefs = await SharedPreferences.getInstance();
//         final token = prefs.getString('auth_token');
//
//         if (token == null) throw Exception("Missing auth token");
//
//         // ✅ Make sure filter map is typed correctly
//         final Map<String, dynamic> filterMap =
//         Map<String, dynamic>.from(event.filters ?? _defaultFilter());
//
//         // ✅ Inject search query if available
//         if (event.searchQuery != null && event.searchQuery!.trim().isNotEmpty) {
//           filterMap["name"] = event.searchQuery;
//         }
//
//         final body = {
//           "job_id": event.jobId,
//           "offset": 0,
//           "limit": 100000, // big number to fetch all
//           "filter": filterMap,
//           "date": "",
//           "email_id": "",
//           "process_id": "",
//           "status_id": "",
//         };
//
//         final response = await http.post(
//           Uri.parse('${BASE_URL}job/dashboard/application-listing'),
//           headers: {
//             'Content-Type': 'application/json',
//             if (token != null) 'Authorization': 'Bearer $token',
//           },
//           body: jsonEncode(body),
//         );
//
//         if (response.statusCode != 200) {
//           throw Exception("Failed: ${response.statusCode}");
//         }
//
//         final decoded = jsonDecode(response.body);
//         final allApplicants = _parseApplicantsFromResponse(decoded);
//         final totalCount = allApplicants.length;
//
//         // ✅ Emit count update without breaking pagination
//         if (currentState is ApplicantLoaded) {
//           emit(currentState.copyWith(
//             totalCount: totalCount,
//           ));
//         } else {
//           emit(ApplicantLoaded(
//             applicants: [],
//             hasReachedMax: true,
//             currentPage: 1,
//             totalCount: totalCount,
//             applicationStages: [],
//             processList: [],
//           ));
//         }
//       } catch (e) {
//         debugPrint("Error fetching all applicants count: $e");
//       }
//     }
//
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//











import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Constant/constants.dart';
import 'applicant_event.dart';
import 'applicant_state.dart';
import '../../model/applicant_model.dart';
import '../../model/job_model.dart';

class ApplicantBloc extends Bloc<ApplicantDataEvent, ApplicantState> {
  // ✅ hamesha 5
  static const int _perPage = 5;

  // Local caches
  List<ApplicantModel> _allApplicants = [];
  List<ApplicationStage> _applicationStages = [];
  String? _currentSearchQuery;

  // Filter mode
  bool _isFilterMode = false;
  Map<String, String> _activeFilter = {};
  String _activeDate = "";
  String _activeEmailId = "";
  String _activeProcessId = "";
  String _activeStatusId = "";

  Map<String, String> _defaultFilter() => {
    "name": "",
    "college_name": "",
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
    "college_city": "",
    "college_state": "",
    "assessment_status": ""
  };

  ApplicantBloc() : super(const ApplicantInitial()) {
    on<LoadDataApplicants>(_onLoadApplicants);
    on<SearchApplicantEvent>(_onSearchApplicants);
    on<LoadMoreApplicants>(_onLoadMoreApplicants);
    on<ApplyApplicantFilter>(_onApplyApplicantFilter);
    // on<LoadAllApplicantsCount>(_onLoadAllApplicantsCount);
  }

  // -------------------- LOAD (offset = 0, limit = 5) -------------------- //
  Future<void> _onLoadApplicants(
      LoadDataApplicants event,
      Emitter<ApplicantState> emit,
      ) async {
    try {
      emit(const ApplicantLoading(applicants: []));
      final page = 0; // ✅ offset page-number: 0
      // final query = _currentSearchQuery?.trim() ?? '';

      // reset filter/search
      _isFilterMode = false;
      _activeFilter = {};
      _activeDate = _activeEmailId = _activeProcessId = _activeStatusId = "";
      _currentSearchQuery = null;
      final query = '';   // ✅ always empty for LoadDataApplicants

      final response = await _fetchApplicantResponse(
        job: event.job,
        page: page, // ✅ offset=0
        query: '',
        filters: _defaultFilter(),
        debugLabel: "INIT",
      );

      final applicants = _parseApplicantsFromResponse(response);
      _allApplicants = List<ApplicantModel>.from(applicants);
      _applicationStages = _parseStagesFromResponse(response);
      final processes = _parseProcessesFromResponse(response);

      emit(ApplicantLoaded(
        applicants: applicants,
        hasReachedMax: applicants.length < _perPage,
        currentPage: page, // ✅ 0
        applicationStages: _applicationStages,
        processList: processes,
        searchQuery: null,
      ));
    } catch (e) {
      emit(ApplicantError(
        'Failed to load applicants: $e',
        applicants: const [],
      ));
    }
  }

  // -------------------- LOAD MORE (offset = currentPage + 1, limit = 5) -------------------- //
  Future<void> _onLoadMoreApplicants(
      LoadMoreApplicants event,
      Emitter<ApplicantState> emit,
      ) async {
    if (state is! ApplicantLoaded) return;
    final st = state as ApplicantLoaded;

    // Search mode me load-more off (tumhari policy)
    if ((_currentSearchQuery ?? '').isNotEmpty) return;

    if (st.hasReachedMax || st.isLoadingMore) return;
    emit(st.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      // ✅ page-number => offset = currentPage + 1 (0,1,2,...)
      final nextPage = st.currentPage + 1;

      final bodyFilters = _isFilterMode
          ? (_activeFilter.isEmpty ? _defaultFilter() : _activeFilter)
          : _defaultFilter();

      final response = await _fetchRaw(
        debugLabel: "LOAD_MORE",
        jobId: event.job.jobId,
        page: nextPage, // ✅ offset (page-number): 1,2,3...
        limit: _perPage, // ✅ 5 fixed
        filters: bodyFilters,
        date: _activeDate,
        emailId: _activeEmailId,
        processId: _activeProcessId,
        statusId: _activeStatusId,
        nameQuery: '', // load-more me search nahi
      );

      if (response == null) {
        emit(st.copyWith(
          errorMessage: 'Null response',
          isLoadingMore: false,
        ));
        return;
      }

      final newBatch = _parseApplicantsFromResponse(response);

      if (newBatch.isEmpty) {
        emit(st.copyWith(hasReachedMax: true, isLoadingMore: false));
        return;
      }

      // dedupe
      final uniqueNew = newBatch
          .where((x) => !_allApplicants.any((y) => y.application_id == x.application_id))
          .toList();

      if (uniqueNew.isEmpty) {
        emit(st.copyWith(hasReachedMax: true, isLoadingMore: false));
        return;
      }

      _allApplicants.addAll(uniqueNew);

      emit(ApplicantLoaded(
        applicants: [...st.applicants, ...uniqueNew],
        hasReachedMax: newBatch.length < _perPage, // agar 5 se kam mila => end
        currentPage: nextPage, // ✅ 0→1→2
        applicationStages: st.applicationStages,
        processList: st.processList,
        searchQuery: st.searchQuery,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(st.copyWith(
        errorMessage: 'Failed to load more: $e',
        isLoadingMore: false,
      ));
    }
  }

  // -------------------- SEARCH (offset = 0, limit = 5) -------------------- //
  Future<void> _onSearchApplicants(
      SearchApplicantEvent event,
      Emitter<ApplicantState> emit,
      ) async {
    // blank search => normal load
    // if (event.query.trim().isEmpty) {
    //   add(LoadDataApplicants(event.job));
    //   return;
    // }
    if (event.query.trim().isEmpty) {
      return;   // ✅ bas ignore karo, UI LoadDataApplicants handle karegi
    }


    try {
      print("🚨 SEARCH CALL from = ${StackTrace.current}");

      emit(const ApplicantLoading(applicants: []));

      final page = 0; // ✅ first page-number
      final query = event.query.trim();

      final res = await _fetchRaw(
        debugLabel: "SEARCH",
        jobId: event.job.jobId,
        page: page, // ✅ offset = 0
        limit: _perPage, // ✅ 5
        filters: _defaultFilter()..update('name', (_) => query, ifAbsent: () => query),
        date: "",
        emailId: "",
        processId: "",
        statusId: "",
        nameQuery: query,
      );

      if (res == null) {
        emit(const ApplicantError('Null response', applicants: []));
        return;
      }

      final applicants = _parseApplicantsFromResponse(res);
      _allApplicants = List<ApplicantModel>.from(applicants);
      _currentSearchQuery = query;

      emit(ApplicantLoaded(
        applicants: applicants,
        hasReachedMax: applicants.length < _perPage,
        currentPage: page, // 0
        applicationStages: const [],
        searchQuery: query,
      ));
    } catch (e) {
      emit(ApplicantError('Search failed: $e', applicants: const []));
    }
  }

  // -------------------- APPLY FILTER (offset = 0, limit = 5) -------------------- //
  Future<void> _onApplyApplicantFilter(
      ApplyApplicantFilter event,
      Emitter<ApplicantState> emit,
      ) async {
    try {
      emit(const ApplicantLoading(applicants: []));

      final page = 0; // ✅ 0-based page-number

      _isFilterMode = true;
      _currentSearchQuery = null;

      _activeFilter = _removeEmptyValues(event.filters);
      _activeDate = event.filters["date"] ?? "";
      _activeEmailId = event.filters["email_id"] ?? "";
      _activeProcessId = event.filters["process_id"] ?? "";
      _activeStatusId = event.filters["status_id"] ?? "";

      final res = await _fetchRaw(
        debugLabel: "FILTER",
        jobId: event.jobId,
        page: page, // ✅ offset=0
        limit: _perPage, // ✅ 5
        filters: _activeFilter.isEmpty ? _defaultFilter() : _activeFilter,
        date: _activeDate,
        emailId: _activeEmailId,
        processId: _activeProcessId,
        statusId: _activeStatusId,
        nameQuery: '',
      );

      if (res == null) {
        emit(const ApplicantError("Null response", applicants: []));
        return;
      }

      final applicants = _parseApplicantsFromResponse(res);
      _allApplicants = List<ApplicantModel>.from(applicants);
      _applicationStages = _parseStagesFromResponse(res);
      final processes = _parseProcessesFromResponse(res);

      emit(ApplicantLoaded(
        applicants: applicants,
        hasReachedMax: applicants.length < _perPage,
        currentPage: page, // 0
        applicationStages: _applicationStages,
        processList: processes,
        searchQuery: null,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(ApplicantError("Exception: $e", applicants: const []));
    }
  }

  // -------------------- TOTAL COUNT (does full fetch once) -------------------- //
  // Future<void> _onLoadAllApplicantsCount(
  //     LoadAllApplicantsCount event,
  //     Emitter<ApplicantState> emit,
  //     ) async {
  //   try {
  //     final currentState = state;
  //
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('auth_token');
  //     if (token == null) throw Exception("Missing auth token");
  //
  //     final pageIndex = 0;
  //
  //     final Map<String, dynamic> filterMap =
  //     Map<String, dynamic>.from(event.filters ?? _defaultFilter());
  //
  //     if (event.searchQuery != null && event.searchQuery!.trim().isNotEmpty) {
  //       filterMap["name"] = event.searchQuery;
  //     }
  //
  //     final body = {
  //       "job_id": event.jobId,
  //       "offset": pageIndex, // ✅ 0
  //       "limit": 1, // all
  //       "filter": filterMap,
  //       "date": "",
  //       "email_id": "",
  //       "process_id": "",
  //       "status_id": "",
  //     };
  //
  //     if (kDebugMode) {
  //       debugPrint("🧮[COUNT] POST offset=$pageIndex, limit=100000");
  //     }
  //
  //     final sw = Stopwatch()..start();
  //     final response = await http.post(
  //       Uri.parse('${BASE_URL}job/dashboard/application-listing'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         if (token != null) 'Authorization': 'Bearer $token',
  //       },
  //       body: jsonEncode(body),
  //     );
  //     sw.stop();
  //
  //     if (kDebugMode) {
  //       debugPrint("🧮[COUNT] status=${response.statusCode} in ${sw.elapsedMilliseconds}ms");
  //     }
  //
  //     if (response.statusCode != 200) {
  //       throw Exception("Failed: ${response.statusCode}");
  //     }
  //
  //     final decoded = jsonDecode(response.body);
  //     final allApplicants = _parseApplicantsFromResponse(decoded);
  //     final totalCount = allApplicants.length;
  //
  //     if (currentState is ApplicantLoaded) {
  //       emit(currentState.copyWith(totalCount: totalCount));
  //     } else {
  //       emit(ApplicantLoaded(
  //         applicants: const [],
  //         hasReachedMax: true,
  //         currentPage: 0,
  //         totalCount: totalCount,
  //         applicationStages: const [],
  //         processList: const [],
  //       ));
  //     }
  //   } catch (e) {
  //     debugPrint("Error fetching all applicants count: $e");
  //   }
  // }

  // -------------------- Shared API helpers -------------------- //
  Future<dynamic> _fetchApplicantResponse({
    required JobModel job,
    required int page, // ✅ page-number used as offset
    required String query,
    Map<String, String>? filters,
    String debugLabel = "INIT",
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('Authentication required');

    final body = {
      'job_id': job.jobId,
      'offset': page,        // ✅ 0,1,2...
      'limit': _perPage,     // ✅ 5
      'filter': (filters ?? _defaultFilter())
        ..update('name', (_) => query, ifAbsent: () => query),
      'date': '',
      'email_id': '',
      'process_id': '',
      'status_id': '',
    };

    if (kDebugMode) {
      debugPrint("📦[$debugLabel] POST offset=$page, limit=$_perPage, query='$query'");
    }

    final sw = Stopwatch()..start();
    final response = await http.post(
      Uri.parse('${BASE_URL}job/dashboard/application-listing'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    sw.stop();
    debugPrint("📏 Response length: ${response.body.length}");

    if (kDebugMode) {
      debugPrint("📦[$debugLabel] status=${response.statusCode} in ${sw.elapsedMilliseconds}ms");
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'API error');
    }
  }

  Future<dynamic> _fetchRaw({
    required String debugLabel,
    required int jobId,
    required int page, // ✅ page-number used as offset
    required int limit, // ✅ 5
    required Map<String, String> filters,
    required String date,
    required String emailId,
    required String processId,
    required String statusId,
    required String nameQuery,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('Missing token');

    // filters + optional name
    final f = Map<String, String>.from(filters);
    if (nameQuery.trim().isNotEmpty) {
      f['name'] = nameQuery.trim();
    } else {
      f.putIfAbsent('name', () => '');
    }

    final body = {
      "job_id": jobId,
      "offset": page, // ✅ 0,1,2...
      "limit": limit, // ✅ 5
      "filter": f,
      "date": date,
      "email_id": emailId,
      "process_id": processId,
      "status_id": statusId,
    };

    if (kDebugMode) {
      debugPrint("📥[$debugLabel] POST offset=$page, limit=$limit, name='$nameQuery'");
    }

    final sw = Stopwatch()..start();
    final res = await http.post(
      Uri.parse('${BASE_URL}job/dashboard/application-listing'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    sw.stop();
    debugPrint("📏 Response length: ${res.body.length}");


    if (kDebugMode) {
      debugPrint("📥[$debugLabel] status=${res.statusCode} in ${sw.elapsedMilliseconds}ms");
    }

    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }

  // -------------------- Parsers & helpers -------------------- //
  List<ApplicantModel> _parseApplicantsFromResponse(dynamic responseData) {
    try {
      final List<dynamic> applicantsData = responseData['studentListing'] ?? [];
      return applicantsData.map((applicantJson) {
        return ApplicantModel(
          name: applicantJson['full_name'] ?? 'No Name',
          university: applicantJson['college_name'] ?? 'Not Specified',
          degree: applicantJson['current_degree'] ?? 'Not Specified',
          grade: applicantJson['current_marks'] ?? 'Not Specified',
          year: applicantJson['current_passing_year'] ?? 'N/A',
          grade_type: applicantJson['grade_type'] ?? 'N/A',
          application_id: int.tryParse(applicantJson['application_id'].toString()) ?? 0,
          job_id: int.tryParse(applicantJson['job_id'].toString()) ?? 0,
          user_id: int.tryParse(applicantJson['user_id'].toString()) ?? 0,
          current_course_name: applicantJson['current_course_name'] ?? 'N/A',
          application_status: applicantJson['application_status_name'] ?? 'Applied',
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse applicants data: $e');
    }
  }

  List<ApplicationStage> _parseStagesFromResponse(dynamic responseData) {
    try {
      final stageList = responseData['applicationCountStage'] as List<dynamic>?;
      if (stageList == null) return [];
      return stageList.map((e) => ApplicationStage.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to parse application stages: $e');
    }
  }

  List<ProcessModel> _parseProcessesFromResponse(dynamic responseData) {
    try {
      final processList = responseData['processList'] as List<dynamic>?;
      if (processList == null) return [];
      return processList.map((e) => ProcessModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to parse process list: $e');
    }
  }

  Map<String, String> _removeEmptyValues(Map<String, String> original) {
    return Map.fromEntries(
      original.entries.where((e) => e.value.trim().isNotEmpty),
    );
  }

  // ------------ Optional: status update (unchanged) ------------ //
  Future<void> updateApplicationStatus({
    required int jobId,
    required int applicationId,
    required String action,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Authentication token missing');

      final response = await http.post(
        Uri.parse('${BASE_URL}job/dashboard/update-application-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "job_id": jobId,
          "action": action,
          "application_id_list": [applicationId],
          "process_id": "",
        }),
      );
      debugPrint("📏 Response length: ${response.body.length}");

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200 || responseData["status"] != true) {
        throw Exception(responseData["msg"] ?? "Status update failed");
      }

      if (state is ApplicantLoaded) {
        final st = state as ApplicantLoaded;
        final updatedApplicants = st.applicants.map((a) {
          if (a.application_id == applicationId) {
            return a.copyWith(application_status: action);
          }
          return a;
        }).toList();

        _allApplicants = updatedApplicants;
        emit(st.copyWith(applicants: updatedApplicants));
      }
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
}



















//
//  //
//  //
//  //
//  //
//  // import 'dart:convert';
//  // import 'package:flutter_bloc/flutter_bloc.dart';
//  // import 'package:http/http.dart' as http;
//  // import 'package:shared_preferences/shared_preferences.dart';
//  // import 'applicant_event.dart';
//  // import 'applicant_state.dart';
//  // import '../../model/applicant_model.dart';
//  // import '../../model/job_model.dart';
//  //
//  // class ApplicantBloc extends Bloc<ApplicantDataEvent, ApplicantState> {
//  //   final int _perPage = 5;
//  //   List<ApplicantModel> _allApplicants = [];
//  //   List<ApplicationStage> _applicationStages = [];
//  //   String? _currentSearchQuery;
//  //
//  //   ApplicantBloc() : super(ApplicantInitial()) {
//  //     on<LoadDataApplicants>(_onLoadApplicants);
//  //     on<SearchApplicantEvent>(_onSearchApplicants);
//  //     on<LoadMoreApplicants>(_onLoadMoreApplicants);
//  //     on<ClearSearchEvent>(_onClearSearch);
//  //     on<ApplyApplicantFilter>(_onApplyFilter);
//  //   }
//  //
//  //   //-------------------- LOAD APPLICANTS --------------------//
//  //   Future<void> _onLoadApplicants(
//  //       LoadDataApplicants event,
//  //       Emitter<ApplicantState> emit,
//  //       ) async {
//  //     try {
//  //       emit(ApplicantLoading(applicants: []));
//  //       _currentSearchQuery = null;
//  //
//  //       final response = await _fetchApplicantResponse(
//  //         job: event.job,
//  //         page: 1,
//  //         query: "",
//  //       );
//  //
//  //       _allApplicants = _parseApplicantsFromResponse(response);
//  //       _applicationStages = _parseStagesFromResponse(response);
//  //
//  //       emit(ApplicantLoaded(
//  //         applicants: _allApplicants,
//  //         hasReachedMax: _allApplicants.length < _perPage,
//  //         currentPage: 1,
//  //         applicationStages: _applicationStages,
//  //         searchQuery: null,
//  //       ));
//  //     } catch (e) {
//  //       emit(ApplicantError(
//  //         'Failed to load applicants: ${e.toString()}',
//  //         applicants: [],
//  //       ));
//  //     }
//  //   }
//  //
//  //   //-------------------- LOAD MORE (Pagination) --------------------//
//  //   Future<void> _onLoadMoreApplicants(
//  //       LoadMoreApplicants event,
//  //       Emitter<ApplicantState> emit,
//  //       ) async {
//  //     if (state is! ApplicantLoaded) return;
//  //
//  //     final currentState = state as ApplicantLoaded;
//  //     if (currentState.hasReachedMax || currentState.isLoadingMore) return;
//  //
//  //     emit(currentState.copyWith(isLoadingMore: true));
//  //
//  //     try {
//  //       final response = await _fetchApplicantResponse(
//  //         job: event.job,
//  //         page: currentState.currentPage + 1,
//  //         query: _currentSearchQuery ?? "",
//  //       );
//  //
//  //       final newApplicants = _parseApplicantsFromResponse(response);
//  //
//  //       // ✅ Remove duplicates
//  //       final uniqueNewApplicants = newApplicants.where((newApp) {
//  //         return !_allApplicants.any(
//  //                 (existing) => existing.application_id == newApp.application_id);
//  //       }).toList();
//  //
//  //       _allApplicants.addAll(uniqueNewApplicants);
//  //
//  //       final hasReachedMax = uniqueNewApplicants.length < _perPage;
//  //
//  //       emit(currentState.copyWith(
//  //         applicants: [...currentState.applicants, ...uniqueNewApplicants],
//  //         hasReachedMax: hasReachedMax,
//  //         currentPage: currentState.currentPage + 1,
//  //         isLoadingMore: false,
//  //       ));
//  //     } catch (e) {
//  //       emit(currentState.copyWith(
//  //         errorMessage: 'Failed to load more: ${e.toString()}',
//  //         isLoadingMore: false,
//  //       ));
//  //     }
//  //   }
//  //
//  //   //-------------------- SEARCH (with pagination) --------------------//
//  //   Future<void> _onSearchApplicants(
//  //       SearchApplicantEvent event,
//  //       Emitter<ApplicantState> emit,
//  //       ) async {
//  //     try {
//  //       emit(ApplicantLoading(applicants: []));
//  //       _currentSearchQuery = event.query.trim();
//  //
//  //       final response = await _fetchApplicantResponse(
//  //         job: event.job,
//  //         page: 1,
//  //         query: _currentSearchQuery!,
//  //       );
//  //
//  //       final applicants = _parseApplicantsFromResponse(response);
//  //
//  //       _allApplicants = applicants;
//  //
//  //       emit(ApplicantLoaded(
//  //         applicants: applicants,
//  //         hasReachedMax: applicants.length < _perPage,
//  //         currentPage: 1,
//  //         applicationStages: [],
//  //         searchQuery: _currentSearchQuery,
//  //       ));
//  //     } catch (e) {
//  //       emit(ApplicantError('Search failed: $e', applicants: []));
//  //     }
//  //   }
//  //
//  //   //-------------------- CLEAR SEARCH --------------------//
//  //   Future<void> _onClearSearch(
//  //       ClearSearchEvent event,
//  //       Emitter<ApplicantState> emit,
//  //       ) async {
//  //     _currentSearchQuery = null;
//  //     add(LoadDataApplicants(job: event.job));
//  //   }
//  //
//  //   //-------------------- APPLY FILTER --------------------//
//  //   Future<void> _onApplyFilter(
//  //       ApplyApplicantFilter event,
//  //       Emitter<ApplicantState> emit,
//  //       ) async {
//  //     try {
//  //       emit(ApplicantLoading(applicants: []));
//  //       final prefs = await SharedPreferences.getInstance();
//  //       final token = prefs.getString('auth_token');
//  //
//  //       final cleanedFilter = _removeEmptyValues(event.filters);
//  //
//  //       final response = await http.post(
//  //         Uri.parse(
//  //             'https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/job/dashboard/application-listing'),
//  //         headers: {
//  //           'Content-Type': 'application/json',
//  //           if (token != null) 'Authorization': 'Bearer $token',
//  //         },
//  //         body: jsonEncode({
//  //           "job_id": event.jobId,
//  //           "offset": 0,
//  //           "limit": _perPage,
//  //           "filter": cleanedFilter,
//  //         }),
//  //       );
//  //
//  //       if (response.statusCode == 200) {
//  //         final decoded = jsonDecode(response.body);
//  //         final List<dynamic> data = decoded['studentListing'] ?? [];
//  //         final applicants =
//  //         data.map((e) => ApplicantModel.fromJson(e)).toList();
//  //
//  //         emit(ApplicantLoaded(
//  //           applicants: applicants,
//  //           hasReachedMax: applicants.length < _perPage,
//  //           currentPage: 1,
//  //           applicationStages: [],
//  //         ));
//  //       } else {
//  //         emit(ApplicantError(
//  //             "API Error: ${response.statusCode}", applicants: []));
//  //       }
//  //     } catch (e) {
//  //       emit(ApplicantError("Exception: $e", applicants: []));
//  //     }
//  //   }
//  //
//  //   //-------------------- API FETCH --------------------//
//  //   Future<dynamic> _fetchApplicantResponse({
//  //     required JobModel job,
//  //     required int page,
//  //     required String query,
//  //   }) async {
//  //     final prefs = await SharedPreferences.getInstance();
//  //     final token = prefs.getString('auth_token');
//  //     if (token == null) throw Exception('Authentication required');
//  //
//  //     final offset = (page - 1) * _perPage;
//  //
//  //     final response = await http.post(
//  //       Uri.parse(
//  //           'https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/job/dashboard/application-listing'),
//  //       headers: {
//  //         'Content-Type': 'application/json',
//  //         'Authorization': 'Bearer $token',
//  //       },
//  //       body: json.encode({
//  //         'job_id': job.jobId,
//  //         'offset': offset,
//  //         'limit': _perPage,
//  //         'filter': {
//  //           'name': query,
//  //           'college_name': '',
//  //           'process_name': '',
//  //           'application_status_name': '',
//  //           'current_degree': '',
//  //           'current_course_name': '',
//  //           'current_specialization_name': '',
//  //           'current_passing_year': '',
//  //           'perfered_location1': '',
//  //           'current_location': '',
//  //           'remarks': '',
//  //           'state': '',
//  //           'gender': '',
//  //           'college_city': '',
//  //           'college_state': '',
//  //           'assessment_status': ''
//  //         },
//  //       }),
//  //     );
//  //
//  //     if (response.statusCode == 200) {
//  //       final data = json.decode(response.body);
//  //       return data;
//  //     } else {
//  //       final errorData = json.decode(response.body);
//  //       throw Exception(errorData['message'] ?? 'API error');
//  //     }
//  //   }
//  //
//  //   //-------------------- HELPERS --------------------//
//  //   List<ApplicantModel> _parseApplicantsFromResponse(dynamic responseData) {
//  //     final List<dynamic> applicantsData = responseData['studentListing'] ?? [];
//  //     return applicantsData.map((applicantJson) {
//  //       return ApplicantModel(
//  //         name: applicantJson['full_name'] ?? 'No Name',
//  //         university: applicantJson['college_name'] ?? 'Not Specified',
//  //         degree: applicantJson['current_degree'] ?? 'Not Specified',
//  //         grade: applicantJson['current_marks'] ?? 'Not Specified',
//  //         year: applicantJson['current_passing_year'] ?? 'N/A',
//  //         grade_type: applicantJson['grade_type'] ?? 'N/A',
//  //         application_id:
//  //         int.tryParse(applicantJson['application_id'].toString()) ?? 0,
//  //         job_id: int.tryParse(applicantJson['job_id'].toString()) ?? 0,
//  //         user_id: int.tryParse(applicantJson['user_id'].toString()) ?? 0,
//  //         current_course_name:
//  //         applicantJson['current_course_name'] ?? 'N/A',
//  //         application_status:
//  //         applicantJson['application_status_name'] ?? 'Applied',
//  //       );
//  //     }).toList();
//  //   }
//  //
//  //   List<ApplicationStage> _parseStagesFromResponse(dynamic responseData) {
//  //     final stageList =
//  //     responseData['applicationCountStage'] as List<dynamic>?;
//  //     if (stageList == null) return [];
//  //     return stageList.map((e) => ApplicationStage.fromJson(e)).toList();
//  //   }
//  //
//  //   Map<String, String> _removeEmptyValues(Map<String, String> original) {
//  //     return Map.fromEntries(
//  //       original.entries.where((e) => e.value.trim().isNotEmpty),
//  //     );
//  //   }
//  // }
