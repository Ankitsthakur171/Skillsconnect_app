import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Constant/constants.dart';
import '../bloc/College_invitation/college_bloc.dart';
import '../bloc/College_invitation/college_event.dart';
import '../model/college_invitation_model.dart';
import 'EnterOtpScreen.dart';

/// -------------------- MODELS --------------------

class FilterOption {
  final int id;
  final String name;

  FilterOption({required this.id, required this.name});

  @override
  String toString() => name;

  factory FilterOption.fromJson(Map<String, dynamic> json, String field) {
    return FilterOption(
      id: json['id'] ?? json['college_id'] ?? 0,
      name: json[field] ?? '',
    );
  }
}

class StateModel {
  final int id;
  final String name;

  StateModel({required this.id, required this.name});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(id: json['id'] ?? 0, name: json['name'] ?? '');
  }

  @override
  String toString() => name;
}

class CityModel {
  final int id;
  final String name;
  final int stateId;

  CityModel({required this.id, required this.name, required this.stateId});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      stateId: json['state_id'] ?? 0,
    );
  }

  @override
  String toString() => name;
}

class SpecializationModel {
  final int id;
  final String name;
  final String status;
  final int courseId;

  SpecializationModel({
    required this.id,
    required this.name,
    required this.status,
    required this.courseId,
  });

  factory SpecializationModel.fromJson(Map<String, dynamic> json) {
    return SpecializationModel(
      id: json['id'] ?? 0,
      name: json['specilization_name'] ?? '',
      status: json['status'] ?? '',
      courseId: json['course_id'] ?? 0,
    );
  }

  @override
  String toString() => name;
}

/// -------------------- API CALLS --------------------

Future<List<FilterOption>> fetchColleges(String query, int jobId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final body = {
    "college_name": query,
    "college_id": 0,
    "job_id": jobId,
    "type": "invitation",
    "page": 1,
  };

  final response = await http.post(
    Uri.parse("${BASE_URL}job/dashboard/college-invite"),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body)['data'] ?? [];
    return data.map((e) => FilterOption.fromJson(e, "college_name")).toList();
  } else {
    return [];
  }
}

Future<List<StateModel>> fetchStates(String query) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.post(
    Uri.parse("${BASE_URL}master/state/list"),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode({"state_name": query}),
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body)['data'] ?? [];
    return data.map((e) => StateModel.fromJson(e)).toList();
  } else {
    return [];
  }
}

Future<List<CityModel>> fetchCities(String query) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.post(
    Uri.parse("${BASE_URL}master/city/list"),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode({"city_name": query}),
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body)['data'] ?? [];
    return data.map((e) => CityModel.fromJson(e)).toList();
  } else {
    return [];
  }
}

Future<List<CollegeModel>> fetchCollege(String search) async {
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
      "search": search, // 👈 yaha search keyword jayega
      "page": 1,
    }),
  );

  if (response.statusCode == 200) {
    final raw = jsonDecode(response.body);
    final List<dynamic> data = raw['data']?['options'] ?? [];
    return data.map((e) => CollegeModel.fromJson(e)).toList();
  } else {
    throw Exception("Failed to load colleges: ${response.statusCode}");
  }
}

Future<List<SpecializationModel>> fetchSpecializations(String query) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.post(
    Uri.parse("${BASE_URL}master/courses-specilization/list"),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      "specilization_name": query,
      "course_id": "",
      "status": "",
    }),
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body)['data'] ?? [];
    return data.map((e) => SpecializationModel.fromJson(e)).toList();
  } else {
    return [];
  }
}

Future<List<CourseModel>> fetchCourse(String search) async {
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

/// -------------------- BOTTOMSHEET --------------------

Future<Map<String, dynamic>?> showCollegeFilterBottomSheet(
  BuildContext context,
  int jobId, {
  Map<String, dynamic>? initial, // 👈 add this
}) async {
  // Prefill from `initial` (both id + name)
  CollegeModel? selectedCollege =
      (initial?['college_id'] != null ||
          (initial?['college_name'] ?? '').toString().isNotEmpty)
      ? CollegeModel(
          id: (initial?['college_id'] ?? 0) as int,
          name: (initial?['college_name'] ?? '') as String,
        )
      : null;
  // ⬇️ NEW: College text controller (prefill with initial)
  final TextEditingController _collegeCtrl = TextEditingController(
    text: (initial?['college_name'] ?? '').toString(),
  );

  FilterOption? selectedInstituteType =
      (initial?['institute_type'] ?? '').toString().isNotEmpty
      ? FilterOption(id: 0, name: initial!['institute_type'])
      : null;

  StateModel? selectedState =
      (initial?['state_id'] != null ||
          (initial?['state_name'] ?? '').toString().isNotEmpty)
      ? StateModel(
          id: (initial?['state_id'] ?? 0) as int,
          name: (initial?['state_name'] ?? '') as String,
        )
      : null;

  CityModel? selectedCity =
      (initial?['city_id'] != null ||
          (initial?['city_name'] ?? '').toString().isNotEmpty)
      ? CityModel(
          id: (initial?['city_id'] ?? 0) as int,
          name: (initial?['city_name'] ?? '') as String,
          stateId: selectedState?.id ?? 0,
        )
      : null;

  CourseModel? selectedCourse =
      (initial?['course_id'] != null ||
          (initial?['course_name'] ?? '').toString().isNotEmpty)
      ? CourseModel(
          id: (initial?['course_id'] ?? 0) as int,
          courseName: (initial?['course_name'] ?? '') as String,
        )
      : null;

  SpecializationModel? selectedSpecialization =
      (initial?['specialization_id'] != null ||
          (initial?['specialization_name'] ?? '').toString().isNotEmpty)
      ? SpecializationModel(
          id: (initial?['specialization_id'] ?? 0) as int,
          name: (initial?['specialization_name'] ?? '') as String,
          status: '',
          courseId: 0,
        )
      : null;

  FilterOption? selectedNAAcGrade =
      (initial?['naac_grade'] ?? '').toString().isNotEmpty
      ? FilterOption(id: 0, name: initial!['naac_grade'])
      : null;

  final List<Map<String, String>> filters = [
    {"label": "College", "key": "college_name"},
    {"label": "Institute Type", "key": "institute_type"},
    {"label": "State", "key": "state_name"},
    {"label": "City", "key": "city_name"},
    {"label": "Course", "key": "current_course_name"},
    {"label": "Specialization", "key": "specialization"},
    {"label": "NAAC Grade", "key": "naac_grade"},
  ];
  final GlobalKey _clearBtnKey = GlobalKey();

  final List<String> naacGrades = [
    "A",
    "A+",
    "A++",
    "B",
    "B+",
    "B++",
    "C",
    "D",
    "Not graded",
    "Unknown",
  ];

  final List<String> instuteType = [
    "College",
    "ITI-Institute",
    "Professional-Institute",
    "Training-institute",
    "University",
  ];

  final result = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
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
                      final label = filters[i]["label"]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(color: Color(0xff003840)),
                            ),
                            const SizedBox(height: 6),

                            // College Filter

                            // if (i == 0)
                            //   DropdownSearch<CollegeModel>(
                            //     asyncItems: (String filter) =>
                            //         fetchCollege(filter),
                            //     selectedItem: selectedCollege,
                            //     itemAsString: (c) => c.name,
                            //     compareFn: (a, b) => a.id == b.id, // 👈
                            //
                            //     onChanged: (val) =>
                            //         setModalState(() => selectedCollege = val),
                            //
                            //     dropdownBuilder: (context, selectedItem) {
                            //       final text = selectedItem?.name ?? 'Select College';
                            //       return Text(
                            //         text,
                            //         style: TextStyle(
                            //             color: selectedItem != null ? Color(0xff003840) : Colors.grey[500], // 🔴 color change on selection
                            //             fontWeight: selectedItem != null
                            //                 ? FontWeight.bold           // ✅ Bold when selected
                            //                 : FontWeight.normal,
                            //             fontSize: 14
                            //         ),
                            //         overflow: TextOverflow.ellipsis,
                            //       );
                            //     },
                            //
                            //     popupProps: const PopupProps.menu(
                            //       showSearchBox: true,      // ✅ SearchBox visible
                            //       isFilterOnline: true,     // ✅ ये सबसे ज़रूरी है
                            //     ),
                            //     dropdownDecoratorProps: DropDownDecoratorProps(
                            //       dropdownSearchDecoration: InputDecoration(
                            //         hintText: 'Please Select',
                            //         border: OutlineInputBorder(
                            //           borderRadius: BorderRadius.circular(28),
                            //         ),
                            //         fillColor: Colors.white,
                            //         filled: true,
                            //       ),
                            //     ),
                            //     dropdownButtonProps: const DropdownButtonProps(
                            //       icon: Icon(Icons.expand_more,
                            //           color: Color(0xff003840), size: 28),
                            //     ),
                            //
                            //   )
                            if (i == 0)
                              TextField(
                                controller: _collegeCtrl,
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
                            //   DropdownSearch<FilterOption>(
                            //     asyncItems: (String filter) =>
                            //         fetchColleges(filter, jobId),
                            //     selectedItem: selectedCollege,
                            //     itemAsString: (u) => u.name,
                            //     onChanged: (val) =>
                            //         setModalState(() => selectedCollege = val),
                            //     popupProps:
                            //     const PopupProps.menu(showSearchBox: true),
                            //     dropdownDecoratorProps: DropDownDecoratorProps(
                            //       dropdownSearchDecoration: InputDecoration(
                            //         labelText: 'Select College',
                            //         border: OutlineInputBorder(
                            //           borderRadius: BorderRadius.circular(28),
                            //         ),
                            //         fillColor: Colors.white,
                            //         filled: true,
                            //       ),
                            //     ),
                            //   )
                            // Institute Type Filter
                            else if (i == 1)
                              DropdownSearch<String>(
                                items: instuteType,
                                selectedItem: selectedInstituteType?.name,
                                itemAsString: (u) => u,
                                onChanged: (val) => setModalState(() {
                                  selectedInstituteType = FilterOption(
                                    id: 0,
                                    name: val ?? "",
                                  );
                                }),
                                dropdownBuilder: (context, selectedItem) {
                                  final isSelected =
                                      selectedItem != null &&
                                      selectedItem.isNotEmpty;
                                  final text = isSelected
                                      ? selectedItem
                                      : 'Select Institute Type';
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
                                  showSearchBox: false,
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    hintText: 'Select Institute Type',
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
                            // State Filter
                            else if (i == 2)
                              DropdownSearch<StateModel>(
                                asyncItems: (String filter) =>
                                    fetchStates(filter),
                                itemAsString: (u) => u.name,
                                compareFn: (a, b) => a.id == b.id, // 👈

                                selectedItem: selectedState,
                                onChanged: (val) =>
                                    setModalState(() => selectedState = val),
                                dropdownBuilder: (context, selectedItem) {
                                  final text =
                                      selectedItem?.name ?? 'Select State';
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
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    hintText: 'Select State',
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
                            // City Filter
                            else if (i == 3)
                              DropdownSearch<CityModel>(
                                asyncItems: (String filter) =>
                                    fetchCities(filter),
                                itemAsString: (u) => u.name,
                                compareFn: (a, b) => a.id == b.id, // 👈

                                selectedItem: selectedCity,
                                onChanged: (val) =>
                                    setModalState(() => selectedCity = val),

                                // ✅ Selected value (field) ko red dikhao
                                dropdownBuilder: (context, selectedItem) {
                                  final text =
                                      selectedItem?.name ?? 'Select City';
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
                                    hintText: 'Select City',
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
                            else if (i == 4)
                              DropdownSearch<CourseModel>(
                                asyncItems: (String filter) {
                                  print(
                                    "🔎 User typed in course search: $filter",
                                  ); // 👈 Debug print
                                  return fetchCourse(filter);
                                },
                                selectedItem: selectedCourse,
                                itemAsString: (c) => c.courseName,
                                compareFn: (a, b) => a.id == b.id, // 👈

                                onChanged: (val) {
                                  setModalState(() {
                                    selectedCourse = val;
                                    // ✅ course badla/hataya → specialization reset + disable trigger
                                    selectedSpecialization = null;
                                  });
                                  print(
                                    "🎯 Selected Course: ${val?.id} - ${val?.courseName}",
                                  );
                                },

                                // ✅ Selected value (field) ko red dikhao
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
                                          ? FontWeight.bold
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
                                    hintText: 'Select Course',
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
                            // Specialization Filter
                            else if (i == 5)
                              InkWell(
                                // 👈 NEW
                                onTap: () {
                                  if (selectedCourse == null) {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder: (_) {
                                        return Container(
                                          margin: const EdgeInsets.all(16),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(width: 10),
                                              Text(
                                                "Please select Course first",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );

                                    // ✅ 6 seconds baad bottom sheet auto close
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                      }
                                    });
                                  }
                                },


                                child: DropdownSearch<SpecializationModel>(
                                  // ✅ agar course select nahi hai to empty list (fetch call nahi hogi)
                                  asyncItems: (String filter) =>
                                      selectedCourse == null
                                      ? Future.value([])
                                      : fetchSpecializations(filter),
                                  // ✅ yahi par enable/disable
                                  enabled: selectedCourse != null,
                                  itemAsString: (u) => u.name,
                                  compareFn: (a, b) => a.id == b.id, // 👈

                                  selectedItem: selectedSpecialization,
                                  onChanged: (val) => setModalState(
                                    () => selectedSpecialization = val,
                                  ),

                                  // ✅ Custom dropdown builder (for text color changes)
                                  dropdownBuilder: (context, selectedItem) {
                                    final isSelected = selectedItem != null;
                                    final text = isSelected
                                        ? selectedItem.name
                                        : (selectedCourse == null
                                              ? 'Select Course first'
                                              : 'Select Specialization');

                                    return Text(
                                      text,
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xff003840)
                                            : Colors
                                                  .grey[500], // 👈 grey when not selected
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight
                                                  .normal, // bold on select
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
                                      // // ✅ user ko hint: pehle course chuno
                                      // hintText: selectedCourse == null
                                      //     ? 'Select Course first'
                                      //     : 'Select Specialization',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                  ),
                                  dropdownButtonProps:
                                      const DropdownButtonProps(
                                        icon: Icon(
                                          Icons.expand_more,
                                          color: Color(0xff003840),
                                          size: 28,
                                        ),
                                      ),
                                ),
                              )
                            // NAAC Grade Filter
                            else if (i == 6)
                              DropdownSearch<String>(
                                items: naacGrades,
                                selectedItem: selectedNAAcGrade?.name,
                                itemAsString: (u) => u,
                                onChanged: (val) => setModalState(() {
                                  selectedNAAcGrade = FilterOption(
                                    id: 0,
                                    name: val ?? "",
                                  );
                                }),
                                dropdownBuilder: (context, selectedItem) {
                                  final isSelected =
                                      selectedItem != null &&
                                      selectedItem.isNotEmpty;
                                  final text = isSelected
                                      ? selectedItem
                                      : 'Select NAAC Grade';
                                  return Text(
                                    text,
                                    style: TextStyle(
                                      color: selectedItem != null
                                          ? Color(0xff003840)
                                          : Colors
                                                .grey[500], // 🔴 color change on selection
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight
                                                .normal, // bold on select                                                    fontSize: 14
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },

                                popupProps: const PopupProps.menu(
                                  showSearchBox: false,
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    hintText: 'Select NAAC Grade',
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
                        key: _clearBtnKey, // ⬅️ add this
                        onPressed: () {
                          setModalState(() {
                            selectedCollege = null;
                            selectedInstituteType = null;
                            selectedState = null;
                            selectedCity = null;
                            selectedCourse = null;
                            selectedSpecialization = null;
                            selectedNAAcGrade = null;
                          });
                          _showInlineHint(
                            context,
                            _clearBtnKey,
                            'All filters cleared',
                          );

                          // ⬇️  CLEAR के तुरंत बाद sheet बंद कर दो
                          Navigator.pop(context, const {'cleared': true});
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
                        // onPressed: () {
                        //   Navigator.pop(context);
                        //
                        //   context.read<CollegeInviteBloc>().add(
                        //     ApplyFilterCollegeEvent(
                        //       jobId: jobId,
                        //       collegeName: selectedCollege?.name,
                        //       instituteType: selectedInstituteType?.name,
                        //       selectedState: selectedState?.id?.toString(),
                        //       selectedcity: selectedCity?.id?.toString(),
                        //       course: selectedCourse?.id?.toString(),
                        //       specialization: selectedSpecialization?.name,
                        //       naacgrade: selectedNAAcGrade?.name,
                        //       type: "invitation",
                        //     ),
                        //   );
                        // },

                        // onPressed: () {
                        //   final applied = <String, dynamic>{
                        //     // 👇 name vs id — BLoC/API ko jo chahiye wahi bhej rahe
                        //     "college_name":   selectedCollege?.name,
                        //     "institute_type": selectedInstituteType?.name,
                        //     "state_id":       selectedState?.id,
                        //     "city_id":        selectedCity?.id,
                        //     "course_name":    selectedCourse?.courseName,
                        //     "specialization": selectedSpecialization?.name,
                        //     "naac_grade":     selectedNAAcGrade?.name,
                        //   };
                        onPressed: () {
                          final applied = <String, dynamic>{
                            // 'college_id'          : selectedCollege?.id,
                            // 'college_name'        : selectedCollege?.name,
                            // ⬇️ College अब सिर्फ़ name से जाएगा (TextField का)
                            'college_name': _collegeCtrl.text.trim(),

                            'institute_type': selectedInstituteType?.name,

                            'state_id': selectedState?.id,
                            'state_name': selectedState?.name,

                            'city_id': selectedCity?.id,
                            'city_name': selectedCity?.name,

                            'course_id': selectedCourse?.id,
                            'course_name': selectedCourse?.courseName,

                            'specialization_id': selectedSpecialization?.id,
                            'specialization_name': selectedSpecialization?.name,

                            'naac_grade': selectedNAAcGrade?.name,
                          };
                          print('Filters Applied : $applied');
                          Navigator.pop(context, applied);
                          showSuccessSnackBar(context, "Filters Applied");
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
  return result;
}

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
