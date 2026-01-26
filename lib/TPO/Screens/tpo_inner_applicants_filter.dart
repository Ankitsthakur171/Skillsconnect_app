import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ⬇️ your existing Student BLoC/events
import '../../Constant/constants.dart';
import '../TpoHomeInnerApplicants/tpoinnerapplicants_bloc.dart';
import '../TpoHomeInnerApplicants/tpoinnerapplicants_event.dart';

// ⬇️ your existing models (you already have these)
import '../Model/tpo_home_job_model.dart'; // if needed elsewhere
import '../Model/student_model.dart';      // if needed elsewhere


/// -------------------- LIGHT MODELS (state/city) --------------------
class StateOption {
  final int id;
  final String name;
  const StateOption({required this.id, required this.name});
  factory StateOption.fromJson(Map<String, dynamic> j)
  => StateOption(id: j['id'] ?? 0, name: (j['name'] ?? '').toString());
  @override
  String toString() => name;
}

class CityOption {
  final int id;
  final String name;
  final int? stateId;
  final String? stateName;
  const CityOption({required this.id, required this.name, this.stateId, this.stateName});
  factory CityOption.fromJson(Map<String, dynamic> j) => CityOption(
    id: j['id'] ?? 0,
    name: (j['name'] ?? '').toString(),
    stateId: j['state_id'],
    stateName: j['state_name'],
  );
  @override
  String toString() => name;
}

/// -------------------- TOKEN + HEADERS --------------------
Future<String?> _token() async {
  final sp = await SharedPreferences.getInstance();
  return sp.getString('auth_token');
}
Map<String, String> _headers(String? token) => {
  'Content-Type': 'application/json',
  if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
};

/// -------------------- DATA FETCHERS --------------------
/// State list (search by partial)
Future<List<StateOption>> fetchStates(String search) async {
  final token = await _token();
  final resp = await http.post(
    Uri.parse('${BASE_URL}master/state/list'),
    headers: _headers(token),
    body: jsonEncode({"state_name": search}),
  );
  if (resp.statusCode != 200) throw Exception('State list failed');
  final raw = jsonDecode(resp.body);
  final List data = raw['data'] ?? [];
  return data.map((e) => StateOption.fromJson(e)).toList();
}

/// City list (optional by state_id)
Future<List<CityOption>> fetchCities({required String search, int? stateId}) async {
  final token = await _token();
  final resp = await http.post(
    Uri.parse('${BASE_URL}master/city/list'),
    headers: _headers(token),
    body: jsonEncode({"cityName": search, if (stateId != null) "state_id": stateId}),
  );
  if (resp.statusCode != 200) throw Exception('City list failed');
  final raw = jsonDecode(resp.body);
  final List data = raw['data'] ?? [];
  return data.map((e) => CityOption.fromJson(e)).toList();
}


// /// -------------------- DATA FETCHERS --------------------
// /// State list (search by partial)
// Future<List<StateOption>> fetchStates(String search) async {
//   print("🔍 [fetchStates] API Start");
//   print("🔹 Search Text: $search");
//
//   final token = await _token();
//   print("🔐 Token: $token");
//
//   final url = Uri.parse('${BASE_URL}master/state/list');
//   print("🌐 URL: $url");
//
//   final body = {"state_name": search};
//   print("📤 Request Body: ${jsonEncode(body)}");
//
//   print("📩 Headers: ${_headers(token)}");
//
//   final resp = await http.post(
//     url,
//     headers: _headers(token),
//     body: jsonEncode(body),
//   );
//
//   print("📥 Status Code: ${resp.statusCode}");
//   print("📥 Raw Response: ${resp.body}");
//
//   if (resp.statusCode != 200) {
//     print("❌ Error: API returned ${resp.statusCode}");
//     throw Exception('State list failed');
//   }
//
//   final raw = jsonDecode(resp.body);
//   print("🧾 Decoded Response: $raw");
//
//   final List data = raw['data'] ?? [];
//   print("✅ States Received: ${data.length}");
//
//   final list = data.map((e) => StateOption.fromJson(e)).toList();
//   print("📦 Returning StateOption list: ${list.length}");
//
//   return list;
// }
//
//
// /// City list (optional by state_id)
// Future<List<CityOption>> fetchCities({required String search, int? stateId}) async {
//   print("🔍 [fetchCities] Starting API call...");
//   print("🔹 Search: $search");
//   print("🔹 stateId: $stateId");
//
//   final token = await _token();
//   print("🔐 Token: $token");
//
//   final url = Uri.parse('${BASE_URL}master/city/list');
//   print("🌐 URL: $url");
//
//   final body = {
//     "cityName": search,
//     if (stateId != null) "state_id": stateId
//   };
//
//   print("📤 Request Body: ${jsonEncode(body)}");
//   print("📩 Headers: ${_headers(token)}");
//
//   final resp = await http.post(
//     url,
//     headers: _headers(token),
//     body: jsonEncode(body),
//   );
//
//   print("📥 Status Code: ${resp.statusCode}");
//   print("📥 Raw Response: ${resp.body}");
//
//   if (resp.statusCode != 200) {
//     print("❌ API Error: ${resp.statusCode}");
//     throw Exception('City list failed');
//   }
//
//   final raw = jsonDecode(resp.body);
//   final List data = raw['data'] ?? [];
//
//   print("✅ Total cities received: ${data.length}");
//
//   final list = data.map((e) => CityOption.fromJson(e)).toList();
//
//   print("📦 Returning CityOption list (size: ${list.length})");
//
//   return list;
// }

/// College (search)
Future<List<CollegeModel>> fetchColleges(String search) async {
  final token = await _token();
  final resp = await http.post(
    Uri.parse('${BASE_URL}common/get-college-list'),
    headers: _headers(token),
    body: jsonEncode({
      "college_id": "",
      "state_id": "",
      "city_id": "",
      "course_id": "",
      "specialization_id": "",
      "search": search,
      "page": 1,
    }),
  );
  if (resp.statusCode != 200) throw Exception('College list failed');
  final raw = jsonDecode(resp.body);
  final List data = raw['data']?['options'] ?? [];
  return data.map<CollegeModel>((e) => CollegeModel.fromJson(e)).toList();
}

/// Process list → unique (process_id, process_name) mapped to your ProcessModel
/// Process list → comes directly from processList array
Future<List<ProcessModel>> fetchProcessesFromListing({
  required int jobId,
  required String search,
}) async {
  final token = await _token();
  final resp = await http.post(
    Uri.parse('${BASE_URL}job/dashboard/application-listing'),
    headers: _headers(token),
    body: jsonEncode({
      "job_id": jobId,
      "offset": 0,
      "limit": 1, // we only need meta, not student list
      "filter": {},
      "date": "",
      "email_id": "",
      "process_id": "",
      "status_id": ""
    }),
  );
  if (resp.statusCode != 200) throw Exception('Process list failed');
  final raw = jsonDecode(resp.body);

  final List plist = raw['processList'] ?? [];
  final res = plist.map((e) {
    final int id = e['id'] is int ? e['id'] : int.tryParse('${e['id']}') ?? 0;
    final String name = (e['name'] ?? '').toString();
    final String type = (e['type'] ?? '').toString();
    return ProcessModel(id: id, name: name, type: type);
  }).where((p) => p.name.toLowerCase().contains(search.toLowerCase())).toList();

  res.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return res;
}

/// Status list → comes directly from applicationCountStage array
Future<List<ApplicationStage>> fetchStatusesFromListing({
  required int jobId,
  required String search,
}) async {
  final token = await _token();
  final resp = await http.post(
    Uri.parse('${BASE_URL}job/dashboard/application-listing'),
    headers: _headers(token),
    body: jsonEncode({
      "job_id": jobId,
      "offset": 0,
      "limit": 1, // only meta needed
      "filter": {},
      "date": "",
      "email_id": "",
      "process_id": "",
      "status_id": ""
    }),
  );
  if (resp.statusCode != 200) throw Exception('Status list failed');
  final raw = jsonDecode(resp.body);

  final List slist = raw['applicationCountStage'] ?? [];
  final res = slist.map((e) {
    final int id = e['application_status_id'] is int
        ? e['application_status_id']
        : int.tryParse('${e['application_status_id']}') ?? 0;
    final String name = (e['name'] ?? '').toString();
    return ApplicationStage(id: id, name: name);
  }).where((s) => s.name.toLowerCase().contains(search.toLowerCase())).toList();

  res.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return res;
}


/// Resolve by Id (prefill)
Future<ProcessModel?> fetchProcessById(int jobId, int processId) async {
  final token = await _token();
  final resp = await http.post(
    Uri.parse('${BASE_URL}job/dashboard/application-listing'),
    headers: _headers(token),
    body: jsonEncode({
      "job_id": jobId,
      "offset": 0,
      "limit": 1,
      "filter": {},
      "date": "",
      "email_id": "",
      "process_id": processId.toString(),
      "status_id": ""
    }),
  );
  if (resp.statusCode != 200) return null;
  final raw = jsonDecode(resp.body);
  final List list = raw['studentListing'] ?? [];
  if (list.isEmpty) return null;
  final name = (list.first['process_name'] ?? '').toString().trim();
  return name.isEmpty ? null : ProcessModel(id: processId, name: name, type: '');
}

Future<ApplicationStage?> fetchStatusById(int jobId, int statusId) async {
  final token = await _token();
  final resp = await http.post(
    Uri.parse('${BASE_URL}job/dashboard/application-listing'),
    headers: _headers(token),
    body: jsonEncode({
      "job_id": jobId,
      "offset": 0,
      "limit": 1,
      "filter": {},
      "date": "",
      "email_id": "",
      "process_id": "",
      "status_id": statusId.toString()
    }),
  );

  if (resp.statusCode != 200) return null;
  final raw = jsonDecode(resp.body);

  // ✅ applicationCountStage array se resolve karo
  final List slist = raw['applicationCountStage'] ?? [];
  final match = slist.firstWhere(
        (e) =>
    (e['application_status_id'] is int
        ? e['application_status_id']
        : int.tryParse('${e['application_status_id']}')) ==
        statusId,
    orElse: () => null,
  );

  if (match == null) return null;

  final name = (match['name'] ?? '').toString();
  return ApplicationStage(id: statusId, name: name);
}

/// -------------------- APPLIED FILTERS (prefill memory) --------------------
Map<String, dynamic> appliedStudentFilters = {};

/// -------------------- BOTTOM SHEET --------------------
Future<void> showStudentFilterBottomSheet(
    BuildContext parentContext, {
      required int jobId,
      required void Function(int) onFiltersUpdated, // badge count
      StudentQuery? initial, // optional prefill from BLoC state
    }) async {

  // Prefill preference order: 1) explicit initial (from bloc) 2) last applied map
// -------------------- PREFILL START --------------------
  CollegeModel?     selectedCollege;
  ProcessModel?     selectedProcess;
  ApplicationStage? selectedStatus;
  StateOption?      selectedState;
  CityOption?       selectedCity;

// 1) Try last applied map (has id + name)
  if (appliedStudentFilters.isNotEmpty) {
    final cid   = appliedStudentFilters['college_id'];
    final cname = (appliedStudentFilters['college_name'] ?? '').toString();
    if (cid != null || cname.isNotEmpty) {
      selectedCollege = CollegeModel(id: cid ?? 0, name: cname);
    }

    final pid   = appliedStudentFilters['process_id'];
    final pname = (appliedStudentFilters['process_name'] ?? '').toString();
    if (pid != null || pname.isNotEmpty) {
      selectedProcess = ProcessModel(id: pid ?? 0, name: pname, type: '');
    }

    final sid   = appliedStudentFilters['status_id'];
    final sname = (appliedStudentFilters['status_name'] ?? '').toString();
    if (sid != null || sname.isNotEmpty) {
      selectedStatus = ApplicationStage(id: sid ?? 0, name: sname);
    }

    final stId   = appliedStudentFilters['state_id'];
    final stName = (appliedStudentFilters['state_name'] ?? '').toString();
    if (stId != null || stName.isNotEmpty) {
      selectedState = StateOption(id: stId ?? 0, name: stName);
    }

    final ctId   = appliedStudentFilters['city_id'];
    final ctName = (appliedStudentFilters['city_name'] ?? '').toString();
    if (ctId != null || ctName.isNotEmpty) {
      selectedCity = CityOption(id: ctId ?? 0, name: ctName, stateId: selectedState?.id, stateName: selectedState?.name);
    }
  }

// 2) If still null, try from BLoC initial (IDs), and resolve names via API (no placeholders)
  if (initial != null) {
    if (selectedCollege == null && initial.collegeId != null) {
      // college name resolve (quick: hit search API with empty and pick by id) — optional
      // ya user ko dropdown se choose karne do; skip bhi kar sakte ho.
    }

    if (selectedProcess == null && initial.processId != null) {
      selectedProcess = await fetchProcessById(jobId, initial.processId!); // ✅ name aayega
    }

    if (selectedStatus == null && initial.statusId != null) {
      selectedStatus = await fetchStatusById(jobId, initial.statusId!);    // ✅ name aayega
    }

    if (selectedState == null && initial.stateId != null) {
      // ❌ Placeholder mat banao "Selected State (id)"
      // agar name nahi hai to chhod do; user dubara select kar lega
      // (ya tum stateById resolver bana sakte ho exactly process jaise)
    }

    if (selectedCity == null && initial.cityId != null) {
      // ❌ Placeholder mat banao "Selected City (id)"
    }
  }
// -------------------- PREFILL END --------------------



  else if (appliedStudentFilters.isNotEmpty) {
    selectedCollege  = appliedStudentFilters["college"]  as CollegeModel?;
    selectedProcess  = appliedStudentFilters["process"]  as ProcessModel?;
    selectedStatus   = appliedStudentFilters["status"]   as ApplicationStage?;
    selectedState    = appliedStudentFilters["state"]    as StateOption?;
    selectedCity     = appliedStudentFilters["city"]     as CityOption?;
  }

  final GlobalKey _clearBtnKey = GlobalKey();

  await showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Color(0xffEBF6F7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: 36,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            int countApplied() => [
              selectedCollege?.name.isNotEmpty == true ? 1 : null,
              selectedProcess?.id,
              selectedStatus?.id,
              selectedState?.name.isNotEmpty == true ? 1 : null,
              selectedCity?.name.isNotEmpty == true ? 1 : null,
            ].where((e) => e != null).length;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      /// College
                      // const Text("College Name", style: TextStyle(color: Color(0xff003840))),
                      // const SizedBox(height: 6),
                      // DropdownSearch<CollegeModel>(
                      //   asyncItems: (s) => fetchColleges(s),
                      //   itemAsString: (c) => c.name,
                      //   selectedItem: selectedCollege,
                      //   compareFn: (a,b) => a.id == b.id,
                      //   onChanged: (v) => setModalState(() => selectedCollege = v),
                      //   popupProps: const PopupProps.menu(showSearchBox: true, isFilterOnline: true),
                      //   dropdownBuilder: (context, selectedItem) {
                      //     final text = selectedItem?.name ?? 'Select College';
                      //     return Text(
                      //       text,
                      //       style: TextStyle(
                      //           color: selectedItem != null ? Color(0xff003840) : Colors.grey[500], // 🔴 color change on selection
                      //           fontWeight: selectedItem != null
                      //               ? FontWeight.bold           // ✅ Bold when selected
                      //               : FontWeight.normal,
                      //           fontSize: 14
                      //       ),
                      //       overflow: TextOverflow.ellipsis,
                      //     );
                      //   },
                      //
                      //   dropdownDecoratorProps: DropDownDecoratorProps(
                      //     dropdownSearchDecoration: const InputDecoration(
                      //       hintText: 'Please Select',
                      //       border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
                      //       filled: true, fillColor: Colors.white,
                      //     ),
                      //   ),
                      //   dropdownButtonProps: const DropdownButtonProps(
                      //     icon: Icon(Icons.expand_more,
                      //         color: Color(0xff003840), size: 28),
                      //   ),
                      //
                      // ),
                      // const SizedBox(height: 14),

                      // Process
                      const Text("Process Listing", style: TextStyle(color: Color(0xff003840))),
                      const SizedBox(height: 6),
                      DropdownSearch<ProcessModel>(
                        asyncItems: (s) => fetchProcessesFromListing(jobId: jobId, search: s),
                        itemAsString: (p) => p.name,
                        selectedItem: selectedProcess,
                        compareFn: (a,b) => a.id == b.id,
                        onChanged: (v) => setModalState(() => selectedProcess = v),
                        dropdownBuilder: (context, selectedItem) {
                          final text = selectedItem?.name ?? 'Select Process';
                          return Text(
                            text,
                            style: TextStyle(
                                color: selectedItem != null ? Color(0xff003840) : Colors.grey[500], // 🔴 color change on selection
                                fontWeight: selectedItem != null
                                    ? FontWeight.bold           // ✅ Bold when selected
                                    : FontWeight.normal,
                                fontSize: 14
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },

                        popupProps: const PopupProps.menu(showSearchBox: true, isFilterOnline: true),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: const InputDecoration(
                            hintText: 'Please Select',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
                            filled: true, fillColor: Colors.white,
                          ),
                        ),
                        dropdownButtonProps: const DropdownButtonProps(
                          icon: Icon(Icons.expand_more,
                              color: Color(0xff003840), size: 28),
                        ),

                      ),
                      const SizedBox(height: 14),

                      // Application Status
                      const Text("Application Status", style: TextStyle(color: Color(0xff003840))),
                      const SizedBox(height: 6),
                      DropdownSearch<ApplicationStage>(
                        asyncItems: (s) => fetchStatusesFromListing(jobId: jobId, search: s),
                        itemAsString: (p) => p.name,
                        selectedItem: selectedStatus,
                        compareFn: (a,b) => a.id == b.id,
                        onChanged: (v) => setModalState(() => selectedStatus = v),
                        dropdownBuilder: (context, selectedItem) {
                          final text = selectedItem?.name ?? 'Select Status';
                          return Text(
                            text,
                            style: TextStyle(
                                color: selectedItem != null ? Color(0xff003840) : Colors.grey[500], // 🔴 color change on selection
                                fontWeight: selectedItem != null
                                    ? FontWeight.bold           // ✅ Bold when selected
                                    : FontWeight.normal,
                                fontSize: 14
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },

                        popupProps: const PopupProps.menu(showSearchBox: true, isFilterOnline: true),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: const InputDecoration(
                            hintText: 'Please Select',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
                            filled: true, fillColor: Colors.white,
                          ),
                        ),
                        dropdownButtonProps: const DropdownButtonProps(
                          icon: Icon(Icons.expand_more,
                              color: Color(0xff003840), size: 28),
                        ),

                      ),
                      const SizedBox(height: 14),

                      // State
                      const Text("State (Prefered Location)", style: TextStyle(color: Color(0xff003840))),
                      const SizedBox(height: 6),
                      DropdownSearch<StateOption>(
                        asyncItems: (s) => fetchStates(s),
                        itemAsString: (o) => o.name,
                        selectedItem: selectedState,
                        onChanged: (v) => setModalState(() {
                          selectedState = v;
                          selectedCity  = null;
                        }),
                        dropdownBuilder: (context, selectedItem) {
                          final text = selectedItem?.name ?? 'Select State';
                          return Text(
                            text,
                            style: TextStyle(
                                color: selectedItem != null ? Color(0xff003840) : Colors.grey[500], // 🔴 color change on selection
                                fontWeight: selectedItem != null
                                    ? FontWeight.bold           // ✅ Bold when selected
                                    : FontWeight.normal,
                                fontSize: 14
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },

                        popupProps: const PopupProps.menu(showSearchBox: true, isFilterOnline: true),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: const InputDecoration(
                            hintText: 'Please Select',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
                            filled: true, fillColor: Colors.white,
                          ),
                        ),
                        dropdownButtonProps: const DropdownButtonProps(
                          icon: Icon(Icons.expand_more,
                              color: Color(0xff003840), size: 28),
                        ),

                      ),
                      const SizedBox(height: 14),

                      // City
                      const Text("City (Prefered Location)", style: TextStyle(color: Color(0xff003840))),
                      const SizedBox(height: 6),
                      DropdownSearch<CityOption>(
                        asyncItems: (s) => fetchCities(search: s, stateId: selectedState?.id),
                        itemAsString: (o) => o.name,
                        selectedItem: selectedCity,
                        onChanged: (v) => setModalState(() => selectedCity = v),
                        dropdownBuilder: (context, selectedItem) {
                          final text = selectedItem?.name ?? 'Select City';
                          return Text(
                            text,
                            style: TextStyle(
                                color: selectedItem != null ? Color(0xff003840) : Colors.grey[500], // 🔴 color change on selection
                                fontWeight: selectedItem != null
                                    ? FontWeight.bold           // ✅ Bold when selected
                                    : FontWeight.normal,
                                fontSize: 14
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },

                        popupProps: const PopupProps.menu(showSearchBox: true, isFilterOnline: true),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: const InputDecoration(
                            hintText: 'Please Select',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
                            filled: true, fillColor: Colors.white,
                          ),
                        ),
                        dropdownButtonProps: const DropdownButtonProps(
                          icon: Icon(Icons.expand_more,
                              color: Color(0xff003840), size: 28),
                        ),

                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        key: _clearBtnKey,
                        onPressed: () {
                          setModalState(() {
                            selectedCollege = null;
                            selectedProcess = null;
                            selectedStatus  = null;
                            selectedState   = null;
                            selectedCity    = null;
                          });
                          appliedStudentFilters.clear();
                          onFiltersUpdated(0);

                          // close & reset the screen list via bloc
                          final bloc = parentContext.read<StudentBloc>();
                          Navigator.pop(context);

                          bloc.add(StudentApplyFilterEvent(jobId, const StudentQuery()));

                          _inlineHint(parentContext, _clearBtnKey, 'All filters cleared');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003840),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Row(
                          children: [
                            Text('Clear', style: TextStyle(color: Color(0xFFFFFFFF))),
                            SizedBox(width: 6),
                            Icon(Icons.clear, color: Color(0xFFFFFFFF)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // ✅ persist BOTH id + name for every filter
                          appliedStudentFilters = {
                            "college_id"  : selectedCollege?.id,
                            "college_name": selectedCollege?.name,

                            "process_id"  : selectedProcess?.id,
                            "process_name": selectedProcess?.name,

                            "status_id"   : selectedStatus?.id,
                            "status_name" : selectedStatus?.name,

                            "state_id"    : selectedState?.id,
                            "state_name"  : selectedState?.name,

                            "city_id"     : selectedCity?.id,
                            "city_name"   : selectedCity?.name,
                          };

                          // 🔁 badge count (optional)
                          final cnt = [
                            selectedCollege?.id,
                            selectedProcess?.id,
                            selectedStatus?.id,
                            selectedState?.id,
                            selectedCity?.id,
                          ].where((e) => e != null).length;
                          onFiltersUpdated(cnt);

                          // 🔃 BLoC ko IDs pass karo (backend ke liye)
                          final query = StudentQuery(
                            collegeId: selectedCollege?.id,
                            processId: selectedProcess?.id,
                            statusId : selectedStatus?.id,
                            stateId  : selectedState?.id,
                            cityId   : selectedCity?.id,
                          );

                          Navigator.pop(context);
                          showErrorSnackBar(context, "Filters Applied");
                          parentContext.read<StudentBloc>().add(
                            StudentApplyFilterEvent(jobId, query),
                          );
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003840),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Row(
                          children: [
                            Text('Apply', style: TextStyle(color: Colors.white)),
                            SizedBox(width: 6),
                            Icon(Icons.check_circle, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // ✅ Rectangular with little radius
      ),
      duration: Duration(seconds: 2),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}


/// small inline toast bubble (optional)
void _inlineHint(BuildContext overlayContext, GlobalKey targetKey, String text) {
  final overlay = Overlay.of(overlayContext);
  if (overlay == null) return;

  final targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  if (targetBox == null || overlayBox == null) return;

  final Offset target = targetBox.localToGlobal(
    targetBox.size.topRight(Offset.zero),
    ancestor: overlayBox,
  );

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: target.dx + 2,
      top: target.dy - 4,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1400)).then((_) { try { entry.remove(); } catch (_) {} });
}





