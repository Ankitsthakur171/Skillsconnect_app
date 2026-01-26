import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../Constant/constants.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../bloc/Applicants_Data/applicant_bloc.dart';
import '../bloc/Applicants_Data/applicant_event.dart';
import '../bloc/Applicants_Data/applicant_state.dart';
import '../model/applicant_model.dart';
import 'EnterOtpScreen.dart';

/// -------------------- MODELS --------------------

/// Common dropdown option
class FilterOption {
  final int id;
  final String name;

  FilterOption({required this.id, required this.name});

  factory FilterOption.fromJson(Map<String, dynamic> json, String field) {
    return FilterOption(
      id: json['id'] ?? json['college_id'] ?? 0,
      name: json[field] ?? '',
    );
  }

  @override
  String toString() => name;
}

/// -------------------- API CALL --------------------

Future<List<FilterOption>> fetchFilters(
  String query,
  String filterKey,
  int jobId,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final filterMap = {
    "name": filterKey == "full_name" ? query : "",
    "college_name": filterKey == "college_name" ? query : "",
    "process_name": filterKey == "process_name" ? query : "",
    "application_status_name": filterKey == "status_id" ? query : "",
    "current_degree": filterKey == "current_degree" ? query : "",
    "current_course_name": filterKey == "current_course_name" ? query : "",
    "current_specialization_name": "",
    "current_passing_year": "",
    "perfered_location1": "",
    "current_location": "",
    "remarks": "",
    "state": "",
    "gender": "",
    "college_city": "",
    "college_state": "",
    "assessment_status": "",
  };

  final body = {
    "job_id": jobId,
    "offset": 0,
    "limit": 20,
    "filter": filterMap,
    "date": "",
    "email_id": "",
    "process_id": "",
    "status_id": "",
  };

  final response = await http.post(
    Uri.parse('${BASE_URL}job/dashboard/application-listing'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    final raw = jsonDecode(response.body);
    final List<dynamic> data = raw['studentListing'] ?? [];
    return data.map((e) => FilterOption.fromJson(e, filterKey)).toList();
  } else {
    throw Exception("API Error");
    // throw Exception("API Error: ${response.statusCode}");
  }
}

/// -------------------- UI (BottomSheet) --------------------
Map<String, dynamic> appliedFilters = {};

Future<void> showFilterBottomSheet(
  BuildContext parentContext,
  int jobId,
  ApplicantBloc bloc, {
  required Function(int) onFiltersUpdated, // 👈 callback for count
}) async {
  // 🔹 Prefill – SAFE (String based)
  FilterOption? selectStudent;
  String? selectedCollegeName;
  ProcessModel? selectedRound;
  ApplicationStage? selectedStatus;
  DegreeModel? selectedDegree;
  CourseModel? selectedCourse;
  String? selectedDate;

  Future<DegreeModel?> _findDegreeById(String id) async {
    try {
      final all = await fetchDegrees(); // tumhara existing helper
      for (final d in all) {
        if (d.id.toString() == id) return d;
      }
    } catch (_) {}
    return null;
  }

  Future<CourseModel?> _findCourseById(String id) async {
    try {
      // empty filter se saare relevant courses aa jaayenge (ya jitna backend de)
      final all = await fetchCourses("");
      for (final c in all) {
        if (c.id.toString() == id) return c;
      }
    } catch (_) {}
    return null;
  }

  if (appliedFilters.isNotEmpty) {
    // name as string → dummy FilterOption bana do
    final nameVal = appliedFilters["name"];
    if (nameVal is String && nameVal.isNotEmpty) {
      selectStudent = FilterOption(id: 0, name: nameVal);
    }

    // college name as string
    final collegeVal = appliedFilters["college_name"];
    if (collegeVal is String && collegeVal.isNotEmpty) {
      selectedCollegeName = collegeVal;
    }

    // date as string
    final dateVal = appliedFilters["date"];
    if (dateVal is String && dateVal.isNotEmpty) {
      selectedDate = dateVal;
    }

    // Round / Status ko ApplicantBloc ke current state se id se find karo
    final st = bloc.state;
    if (st is ApplicantLoaded) {
      final processIdVal = appliedFilters["process_name"];
      if (processIdVal is String && processIdVal.isNotEmpty) {
        selectedRound = st.processList.firstWhere(
              (p) => p.id.toString() == processIdVal,
        );
      }

      final statusIdVal = appliedFilters["application_status_name"];
      if (statusIdVal is String && statusIdVal.isNotEmpty) {
        selectedStatus = st.applicationStages.firstWhere(
              (s) => s.id.toString() == statusIdVal,
        );
      }
    }


    // 🔹 DEGREE id se API ke through resolve
    final degreeIdVal = appliedFilters["current_degree"];
    if (degreeIdVal is String && degreeIdVal.isNotEmpty) {
      selectedDegree = await _findDegreeById(degreeIdVal);
    }

    // 🔹 COURSE id se API ke through resolve
    final courseIdVal = appliedFilters["current_course_name"];
    if (courseIdVal is String && courseIdVal.isNotEmpty) {
      selectedCourse = await _findCourseById(courseIdVal);
    }
  }


  // 🔹 controller ab selectedCollegeName ka use kare
  final TextEditingController _collegeCtrl = TextEditingController(
    text: selectedCollegeName ?? '',
  );


  final GlobalKey _clearBtnKey = GlobalKey();

  final List<Map<String, String>> filters = [
    {"label": "Student", "key": "full_name"},
    {"label": "College Name", "key": "college_name"},
    {"label": "Round", "key": "process_id"},
    {"label": "Application Status", "key": "status_id"},
    {"label": "Degree", "key": "current_degree"},
    {"label": "Course", "key": "current_course_name"},
    {"label": "Applied Date", "key": "date"},
  ];

  showModalBottomSheet(
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
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: filters.length,
                    itemBuilder: (context, i) {
                      final state = bloc.state; // 👈 direct bloc state

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              filters[i]["label"]!,
                              style: const TextStyle(color: Color(0xff003840)),
                            ),
                            const SizedBox(height: 6),

                            // 🔹 Student Filter → FilterOption
                            if (i == 0)
                              DropdownSearch<FilterOption>(
                                asyncItems: (String filter) => fetchFilters(
                                  filter,
                                  filters[i]["key"]!,
                                  jobId,
                                ),
                                selectedItem: selectStudent,
                                itemAsString: (u) => u.name,
                                onChanged: (val) =>
                                    setModalState(() => selectStudent = val),
                                dropdownBuilder: (context, selectedItem) {
                                  final text =
                                      selectedItem?.name ?? 'Select Student';
                                  return Text(
                                    text,
                                    style: TextStyle(
                                      color: selectedItem != null
                                          ? Color(0xff003840)
                                          : Colors
                                                .grey[500], // 🔴 color change on selection
                                      fontWeight: selectedItem != null
                                          ? FontWeight
                                                .bold // ✅ Bold when selected
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },

                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  isFilterOnline: true,
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    hintText: 'Please Select',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                                dropdownButtonProps: const DropdownButtonProps(
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: Color(0xff003840),
                                    size: 28,
                                  ),
                                ),
                              )
                            // 🔹 College Filter → CollegeModel (API se)
                            else if (i == 1)
                              TextField(
                                controller: _collegeCtrl,
                                onChanged: (v) => setModalState(
                                  () => selectedCollegeName = v.trim(),
                                ),
                                style: TextStyle(
                                  color: Color(
                                    0xff003840,
                                  ), // 👈 User typed text GREEN
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Select College',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                    fontWeight: FontWeight
                                        .normal, // 👈 IMPORTANT: hint normal
                                  ), // 👈 grey color for hint text
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  suffixIcon: Icon(
                                    Icons.search,
                                    color: Color(0xff003840),
                                  ),
                                ),
                              )
                            // DropdownSearch<CollegeModel>(
                            //   asyncItems: (String filter) async {
                            //     print("🔎 User typed: $filter");  // हर बार user type करेगा तो यह print होगा
                            //     return await fetchColleges(filter); // API call text के साथ
                            //   },
                            //   itemAsString: (c) => c.name,
                            //   selectedItem: selectedCollege,
                            //   onChanged: (val) {
                            //     setModalState(() => selectedCollege = val);
                            //     print("🎯 Selected: ${val?.id} | ${val?.name}");
                            //   },
                            //
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
                            //   popupProps: const PopupProps.menu(
                            //     showSearchBox: true,      // ✅ SearchBox visible
                            //     isFilterOnline: true,     // ✅ ये सबसे ज़रूरी है
                            //   ),
                            //   dropdownDecoratorProps: DropDownDecoratorProps(
                            //     dropdownSearchDecoration: InputDecoration(
                            //       hintText: 'Please Select',
                            //       border: OutlineInputBorder(
                            //         borderRadius: BorderRadius.all(Radius.circular(28)),
                            //       ),
                            //       fillColor: Colors.white,
                            //       filled: true,
                            //     ),
                            //   ),
                            //   dropdownButtonProps: const DropdownButtonProps(
                            //     icon: Icon(Icons.expand_more, color: Color(0xff003840), size: 28),
                            //   ),
                            // )
                            // 🔹 Round Filter → ProcessModel
                            else if (i == 2)
                              DropdownSearch<ProcessModel>(
                                items: (state is ApplicantLoaded)
                                    ? state.processList.cast<ProcessModel>()
                                    : <ProcessModel>[],
                                selectedItem: selectedRound,
                                itemAsString: (p) => p.name,
                                onChanged: (val) =>
                                    setModalState(() => selectedRound = val),
                                dropdownBuilder: (context, selectedItem) {
                                  final text =
                                      selectedItem?.name ?? 'Select Round';
                                  return Text(
                                    text,
                                    style: TextStyle(
                                      color: selectedItem != null
                                          ? Color(0xff003840)
                                          : Colors
                                                .grey[500], // 🔴 color change on selection
                                      fontWeight: selectedItem != null
                                          ? FontWeight
                                                .bold // ✅ Bold when selected
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },

                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  isFilterOnline: true,
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    hintText: 'Please Select',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                                dropdownButtonProps: const DropdownButtonProps(
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: Color(0xff003840),
                                    size: 28,
                                  ),
                                ),
                              )
                            // 🔹 Application Status Filter → ApplicationStage
                            else if (i == 3)
                              DropdownSearch<ApplicationStage>(
                                items: (state is ApplicantLoaded)
                                    ? state.applicationStages
                                          .cast<ApplicationStage>()
                                    : <ApplicationStage>[],
                                selectedItem: selectedStatus,
                                itemAsString: (s) => s.name,
                                onChanged: (val) =>
                                    setModalState(() => selectedStatus = val),
                                dropdownBuilder: (context, selectedItem) {
                                  final text =
                                      selectedItem?.name ?? 'Select Status';
                                  return Text(
                                    text,
                                    style: TextStyle(
                                      color: selectedItem != null
                                          ? Color(0xff003840)
                                          : Colors
                                                .grey[500], // 🔴 color change on selection
                                      fontWeight: selectedItem != null
                                          ? FontWeight
                                                .bold // ✅ Bold when selected
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },

                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  isFilterOnline: true,
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    hintText: 'Please Select',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                                dropdownButtonProps: const DropdownButtonProps(
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: Color(0xff003840),
                                    size: 28,
                                  ),
                                ),
                              )
                            // 🔹 Degree Filter → DegreeModel
                            else if (i == 4)
                              DropdownSearch<DegreeModel>(
                                asyncItems: (String filter) => fetchDegrees(),
                                selectedItem: selectedDegree,
                                itemAsString: (d) => d.name,
                                onChanged: (val) =>
                                    setModalState(() => selectedDegree = val),
                                dropdownBuilder: (context, selectedItem) {
                                  final text =
                                      selectedItem?.name ?? 'Select Degree';
                                  return Text(
                                    text,
                                    style: TextStyle(
                                      color: selectedItem != null
                                          ? Color(0xff003840)
                                          : Colors
                                                .grey[500], // 🔴 color change on selection
                                      fontWeight: selectedItem != null
                                          ? FontWeight
                                                .bold // ✅ Bold when selected
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },

                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  isFilterOnline: true,
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    hintText: 'Please Select',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                                dropdownButtonProps: const DropdownButtonProps(
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: Color(0xff003840),
                                    size: 28,
                                  ),
                                ),
                              )
                            // 🔹 Course Filter → FilterOption
                            else if (i == 5)
                              DropdownSearch<CourseModel>(
                                asyncItems: (String filter) {
                                  print(
                                    "🔎 User typed in course search: $filter",
                                  ); // 👈 Debug print
                                  return fetchCourses(filter);
                                },
                                selectedItem: selectedCourse,
                                itemAsString: (c) => c.courseName,
                                onChanged: (val) {
                                  setModalState(() => selectedCourse = val);
                                  print(
                                    "🎯 Selected Course: ${val?.id} - ${val?.courseName}",
                                  );
                                },
                                dropdownBuilder: (context, selectedItem) {
                                  final text =
                                      selectedItem?.courseName ??
                                      'Select Course';
                                  return Text(
                                    text,
                                    style: TextStyle(
                                      color: selectedItem != null
                                          ? Color(0xff003840)
                                          : Colors
                                                .grey[500], // 🔴 color change on selection
                                      fontWeight: selectedItem != null
                                          ? FontWeight
                                                .bold // ✅ Bold when selected
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },

                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  isFilterOnline: true,
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    hintText: 'Please Select',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                                dropdownButtonProps: const DropdownButtonProps(
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: Color(0xff003840),
                                    size: 28,
                                  ),
                                ),
                              )
                            // 🔹 Date Filter → Date Picker
                            else if (i == 6)
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate:
                                        DateTime.now(), // future date allow nahi karni
                                  );

                                  if (picked != null) {
                                    final formatted =
                                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

                                    setModalState(() {
                                      selectedDate = formatted.toString();
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedDate ?? "Select Date",
                                        style: TextStyle(
                                          color: selectedDate == null
                                              ? Colors.grey
                                              : Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Color(0xff003840),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        key: _clearBtnKey,
                        onPressed: () {
                          // 1) Bottom-sheet ke local selections saaf
                          setModalState(() {
                            selectStudent = null;
                            // selectedCollege = null;
                            selectedCollegeName = null;
                            _collegeCtrl.clear();
                            selectedRound = null;
                            selectedStatus = null;
                            selectedDegree = null;
                            selectedCourse = null;
                            selectedDate = null;
                          });

                          // 2) Parent side ka applied map/badge reset
                          appliedFilters.clear(); // ✅ global/applied map clear
                          onFiltersUpdated(0); // ✅ parent badge count 0

                          // 3) Sheet close
                          Navigator.pop(context, const {'cleared': true});

                          // 4) 🔥 MOST IMPORTANT: UI list ko reset/reload karao
                          //    OPTION A: agar tumhare paas JobModel 'job' ho (recommended)
                          // parentContext.read<ApplicantBloc>().add(
                          //   LoadDataApplicants(job: job),   // <-- job: JobModel
                          // );

                          //    OPTION B: agar sirf jobId hai (fallback; filter mode ON rahega)
                          parentContext.read<ApplicantBloc>().add(
                            ApplyApplicantFilter(
                              jobId: jobId,
                              filters: const {},
                              page: 1,
                            ),
                          );

                          // 5) Chhota feedback bubble
                          _showInlineHint(
                            parentContext,
                            _clearBtnKey,
                            'All filters cleared',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003840),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Clear',
                              style: TextStyle(color: Color(0xFFFFFFFF)),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.clear, color: Color(0xFFFFFFFF)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);

                          final appliedJson = {
                            "name": selectStudent?.name ?? "",
                            "college_name": selectedCollegeName ?? "",
                            "process_name": selectedRound?.id.toString() ?? "",
                            "application_status_name": selectedStatus?.id.toString() ?? "",
                            "current_degree": selectedDegree?.id.toString() ?? "",
                            "current_course_name": selectedCourse?.id.toString() ?? "",
                            "date": selectedDate ?? "",
                          };

                          // 👇 YAHI sabse important line: appliedFilters = appliedJson
                          appliedFilters = Map<String, String>.from(appliedJson);

                          print("📤 Final Applied Filters: $appliedJson");

                          // ✅ Filter count nikal ke parent ko bhejo
                          final nonEmptyCount = appliedJson.entries
                              .where(
                                (e) => e.value.toString().isNotEmpty,
                          )
                              .length;
                          onFiltersUpdated(nonEmptyCount);

                          // 🔔 Snackbar
                          showSuccessSnackBar(context, "Filters Applied");

                          // 👇 Bloc event dispatch
                          parentContext.read<ApplicantBloc>().add(
                            ApplyApplicantFilter(
                              jobId: jobId,
                              filters: appliedJson,
                              page: 1,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003840),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Apply',
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.check_circle, color: Colors.white),
                          ],
                        ),
                      ),

                      // ElevatedButton(
                      //   onPressed: () {
                      //     Navigator.pop(context);
                      //
                      //     appliedFilters = {
                      //       "name": selectStudent,
                      //       // "college_name": selectedCollege,
                      //       "college_name":
                      //           selectedCollegeName, // <- yahan string
                      //       "process_name": selectedRound,
                      //       "application_status_name": selectedStatus,
                      //       "current_degree": selectedDegree,
                      //       "current_course_name": selectedCourse,
                      //       "date": selectedDate,
                      //     };
                      //
                      //     final appliedJson = {
                      //       "name": selectStudent?.name ?? "",
                      //       // "college_name": selectedCollege?.id.toString() ?? "",
                      //       "college_name":
                      //           selectedCollegeName ??
                      //           "", // <- yahan bhi string
                      //       "process_name": selectedRound?.id.toString() ?? "",
                      //       "application_status_name":
                      //           selectedStatus?.id.toString() ?? "",
                      //       "current_degree":
                      //           selectedDegree?.id.toString() ?? "",
                      //       "current_course_name":
                      //           selectedCourse?.id.toString() ?? "",
                      //       "date": selectedDate ?? "",
                      //     };
                      //     print("📤 Final Applied Filters: $appliedJson");
                      //
                      //     // ✅ Filter count nikal ke parent ko bhejo
                      //     final nonEmptyCount = appliedJson.entries
                      //         .where(
                      //           (e) =>
                      //               e.value != null &&
                      //               e.value.toString().isNotEmpty,
                      //         )
                      //         .length;
                      //     onFiltersUpdated(nonEmptyCount); // 👈 UI refresh
                      //
                      //     // 🔔 Snackbar (parent)
                      //     showErrorSnackBar(context, "Filters Applied");
                      //
                      //     // 👇 Bloc event dispatch
                      //     parentContext.read<ApplicantBloc>().add(
                      //       ApplyApplicantFilter(
                      //         jobId: jobId,
                      //         filters: appliedJson,
                      //         page: 1,
                      //       ),
                      //     );
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: const Color(0xFF003840),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(24),
                      //     ),
                      //   ),
                      //   child: const Row(
                      //     children: [
                      //       Text(
                      //         'Apply',
                      //         style: TextStyle(color: Colors.white),
                      //       ),
                      //       SizedBox(width: 6),
                      //       Icon(Icons.check_circle, color: Colors.white),
                      //     ],
                      //   ),
                      // ),
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

// void showErrorSnackBar(BuildContext context, String message) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text(
//         message,
//         style: TextStyle(color: Colors.white, fontSize: 14),
//       ),
//       backgroundColor: Colors.green,
//       behavior: SnackBarBehavior.floating,
//       margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(
//           10,
//         ), // ✅ Rectangular with little radius
//       ),
//       duration: Duration(seconds: 2),
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//     ),
//   );
// }

void _showInlineHint(
  BuildContext overlayContext,
  GlobalKey targetKey,
  String text,
) {
  final overlay = Overlay.of(overlayContext);
  if (overlay == null) return;

  final targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  if (targetBox == null || overlayBox == null) return;

  // Button ke top-right ke thoda sa aage bubble place kar rahe
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
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1400)).then((_) {
    try {
      entry.remove();
    } catch (_) {}
  });
}

Future<List<CourseModel>> fetchCourses(String search) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  print("🔎 User searched course: $search");

  final response = await http.post(
    Uri.parse('${BASE_URL}master/course/list'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode({"course_name": search, "offset": 0, "limit": 200}),
  );

  print("📤 Request body: ${jsonEncode({"course_name": search, "offset": 0})}");
  print("📥 Response status: ${response.statusCode}");

  if (response.statusCode == 200) {
    final raw = jsonDecode(response.body);
    print("📥 Response: $raw");

    final List<dynamic> data = raw['data'] ?? [];
    return data.map((e) => CourseModel.fromJson(e)).toList();
  } else {
    print("❌ Error Response: ${response.body}");
    throw Exception("Failed to load courses: ${response.statusCode}");
  }
}

Future<List<CollegeModel>> fetchColleges(String search) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.post(
    Uri.parse('${BASE_URL}common/get-college-list'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      "college_id": "",
      "state_id": "",
      "city_id": "",
      "course_id": "",
      "specialization_id": "",
      "search": search, // 👈 यही text API में जाएगा
      "page": 1,
    }),
  );

  print("📤 Request Body: ${jsonEncode({"search": search, "page": 1})}");

  if (response.statusCode == 200) {
    final raw = jsonDecode(response.body);
    final List<dynamic> data = raw['data']?['options'] ?? [];
    print("🏫 Colleges Found: ${data.length}");
    return data.map((e) => CollegeModel.fromJson(e)).toList();
  } else {
    throw Exception("Failed to load colleges: ${response.statusCode}");
  }
}

Future<List<DegreeModel>> fetchDegrees() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception("⚠️ Auth token not found in SharedPreferences");
    }

    final response = await http.post(
      Uri.parse('${BASE_URL}master/degree/list'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ token from SharedPreferences
      },
      body: jsonEncode({"limit": 10}),
    );

    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      final List<dynamic> data = raw['data'] ?? [];
      return data.map((e) => DegreeModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load degrees: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("fetchDegrees error: $e");
  }
}
