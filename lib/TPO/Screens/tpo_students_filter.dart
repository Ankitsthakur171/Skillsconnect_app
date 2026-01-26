

import 'dart:async';
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Constant/constants.dart';


/// Simple filter model for Institute list
class InstituteFilter {
  final int? collegeId;
  final String? collegeName;
  final int? courseId;
  final String? courseName;
  final String? passoutYear;
  final String? studentName; // 👈 NEW
  final String? status; // "Approved" | "Denied"

  const InstituteFilter({
    this.collegeId,
    this.collegeName,
    this.courseId,
    this.courseName,
    this.passoutYear,
    this.studentName,
    this.status,
  });

  InstituteFilter copyWith({
    int? collegeId,
    String? collegeName,
    int? courseId,
    String? courseName,
    String? passoutYear,
    String? studentName,
    String? status,
  }) {
    return InstituteFilter(
      collegeId: collegeId ?? this.collegeId,
      collegeName: collegeName ?? this.collegeName,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      passoutYear: passoutYear ?? this.passoutYear,
      studentName: studentName ?? this.studentName,
      status: status ?? this.status,
    );
  }

  int get activeCount {
    int c = 0;
    if (collegeId != null) c++;
    if (courseId != null) c++;
    if (passoutYear != null && passoutYear!.trim().isNotEmpty) c++;
    if (studentName != null && studentName!.trim().isNotEmpty) c++; // 👈 NEW
    if (status != null && status!.trim().isNotEmpty) c++;
    return c;
  }

  bool get hasAny => activeCount > 0;

  static const empty = InstituteFilter();
}

class _CollegeItem {
  final int id;
  final String name;
  _CollegeItem({required this.id, required this.name});

  factory _CollegeItem.fromJson(Map<String, dynamic> json) {
    return _CollegeItem(
      id: json['id'] ?? 0,
      name: json['college_name'] ?? '',
    );
  }
}

class _CourseItem {
  final int id;
  final String name;
  _CourseItem({required this.id, required this.name});

  factory _CourseItem.fromJson(Map<String, dynamic> json) {
    return _CourseItem(
      id: json['id'] ?? 0,
      name: json['course_name'] ?? '',
    );
  }
}

/// College search API
Future<List<_CollegeItem>> _fetchColleges(String search) async {
  if (search.trim().isEmpty) return [];

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final resp = await http.post(
    Uri.parse('${BASE_URL}common/get-college-list'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    },
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

  if (resp.statusCode != 200) return [];

  final json = jsonDecode(resp.body);
  if (json['status'] != true) return [];

  final list = (json['data']?['collegeListMaster'] as List?) ?? [];
  return list.map((e) => _CollegeItem.fromJson(e as Map<String, dynamic>)).toList();
}

/// Course search API
Future<List<_CourseItem>> _fetchCourses(String search) async {
  if (search.trim().isEmpty) return [];

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final resp = await http.post(
    Uri.parse('${BASE_URL}master/course/list'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      "course_name": search,
    }),
  );

  if (resp.statusCode != 200) return [];

  final json = jsonDecode(resp.body);
  if (json['status'] != true) return [];

  final list = (json['data'] as List?) ?? [];
  return list.map((e) => _CourseItem.fromJson(e as Map<String, dynamic>)).toList();
}

/// Bottom sheet opener
Future<InstituteFilter?> showInstituteFilterBottomSheet(
    BuildContext context, {
      InstituteFilter? initial,
    }) {
  return showModalBottomSheet<InstituteFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return _InstituteFilterSheet(initial: initial ?? InstituteFilter.empty);
    },
  );
}

class _InstituteFilterSheet extends StatefulWidget {
  const _InstituteFilterSheet({required this.initial});

  final InstituteFilter initial;

  @override
  State<_InstituteFilterSheet> createState() => _InstituteFilterSheetState();
}

class _InstituteFilterSheetState extends State<_InstituteFilterSheet> {
  late TextEditingController _collegeCtrl;
  late TextEditingController _courseCtrl;
  late TextEditingController _passoutCtrl;
  late TextEditingController _studentCtrl; // 👈 NEW


  int? _selectedCollegeId;
  int? _selectedCourseId;
  String? _selectedStatus;

  // suggestions
  List<_CollegeItem> _collegeSuggestions = [];
  List<_CourseItem> _courseSuggestions = [];
  bool _loadingColleges = false;
  bool _loadingCourses = false;

  Timer? _collegeDebounce;
  Timer? _courseDebounce;

  @override
  void initState() {
    super.initState();
    _collegeCtrl = TextEditingController(text: widget.initial.collegeName ?? '');
    _courseCtrl = TextEditingController(text: widget.initial.courseName ?? '');
    _passoutCtrl = TextEditingController(text: widget.initial.passoutYear ?? '');
    _studentCtrl = TextEditingController(text: widget.initial.studentName ?? ''); // 👈 NEW
    _selectedCollegeId = widget.initial.collegeId;
    _selectedCourseId = widget.initial.courseId;
    _selectedStatus = widget.initial.status;
  }

  @override
  void dispose() {
    _collegeCtrl.dispose();
    _courseCtrl.dispose();
    _passoutCtrl.dispose();
    _collegeDebounce?.cancel();
    _courseDebounce?.cancel();
    _studentCtrl.dispose(); // 👈 NEW
    super.dispose();
  }

  // Without Using DropDown

  void _onCollegeChanged(String value) {
    // ab yeh sirf ID reset karega, koi API call / suggestion nahi
    _selectedCollegeId = null;
    _collegeDebounce?.cancel();

    if (_collegeSuggestions.isNotEmpty) {
      setState(() {
        _collegeSuggestions = []; // safety: agar pehle kuch bacha ho
      });
    }
  }

  // Using DropDown

  // void _onCollegeChanged(String value) {
  //   _selectedCollegeId = null;
  //   _collegeDebounce?.cancel();
  //
  //   if (value.trim().isEmpty) {
  //     setState(() {
  //       _collegeSuggestions = [];
  //     });
  //     return;
  //   }
  //
  //   _collegeDebounce = Timer(const Duration(milliseconds: 400), () async {
  //     setState(() => _loadingColleges = true);
  //     final res = await _fetchColleges(value);
  //     if (!mounted) return;
  //     setState(() {
  //       _loadingColleges = false;
  //       _collegeSuggestions = res;
  //     });
  //   });
  // }

  void _onCourseChanged(String value) {
    _selectedCourseId = null;
    _courseDebounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _courseSuggestions = [];
      });
      return;
    }

    _courseDebounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _loadingCourses = true);
      final res = await _fetchCourses(value);
      if (!mounted) return;
      setState(() {
        _loadingCourses = false;
        _courseSuggestions = res;
      });
    });
  }

  // 🔁 College ko API se resolve karke ID bhejne wala apply
  Future<void> _apply() async {
    final rawCollege = _collegeCtrl.text.trim();

    int? resolvedCollegeId = _selectedCollegeId;
    String? resolvedCollegeName =
    rawCollege.isEmpty ? null : rawCollege; // default typed name

    // 🔹 Sirf tab API call karo jab user ne kuch type kiya ho
    if (rawCollege.isNotEmpty) {
      setState(() => _loadingColleges = true);
      try {
        final colleges = await _fetchColleges(rawCollege);

        if (colleges.isNotEmpty) {
          // exact name match ho toh wahi, warna first result
          final match = colleges.firstWhere(
                (c) => c.name.toLowerCase() == rawCollege.toLowerCase(),
            orElse: () => colleges.first,
          );

          resolvedCollegeId = match.id;
          resolvedCollegeName = match.name; // canonical name from API
        } else {
          // ❌ koi college nahi mila → aisi ID bhejo jisse backend "no data" de
          resolvedCollegeId = -1;
          resolvedCollegeName = rawCollege;

          // optional info user ko
          showSuccesSnackBar(
            context,
            "No college found for \"$rawCollege\". Result may be empty.",
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loadingColleges = false);
        }
      }
    }

    final filter = InstituteFilter(
      collegeId: resolvedCollegeId,
      collegeName: resolvedCollegeName,
      courseId: _selectedCourseId,
      courseName:
      _courseCtrl.text.trim().isEmpty ? null : _courseCtrl.text.trim(),
      passoutYear:
      _passoutCtrl.text.trim().isEmpty ? null : _passoutCtrl.text.trim(),
      studentName:
      _studentCtrl.text.trim().isEmpty ? null : _studentCtrl.text.trim(),
      status: _selectedStatus,
    );

    Navigator.pop(context, filter);
    showSuccesSnackBar(context, "Filters Applied");
  }

  // void _apply() {
  //   final filter = InstituteFilter(
  //     collegeId: _selectedCollegeId,
  //     collegeName: _collegeCtrl.text.trim().isEmpty ? null : _collegeCtrl.text.trim(),
  //     courseId: _selectedCourseId,
  //     courseName: _courseCtrl.text.trim().isEmpty ? null : _courseCtrl.text.trim(),
  //     passoutYear: _passoutCtrl.text.trim().isEmpty ? null : _passoutCtrl.text.trim(),
  //     studentName: _studentCtrl.text.trim().isEmpty ? null : _studentCtrl.text.trim(), // 👈 NEW
  //     status: _selectedStatus,
  //   );
  //   Navigator.pop(context, filter);
  //   showSuccesSnackBar(context, "Filters Applied");
  //
  // }

  void _reset() {
    // 1) local state clear (ye UI ke liye hai, optional but thik hai)
    setState(() {
      _collegeCtrl.clear();
      _courseCtrl.clear();
      _passoutCtrl.clear();
      _studentCtrl.clear(); // 👈 student name bhi
      _selectedCollegeId = null;
      _selectedCourseId = null;
      _selectedStatus = null;
      _collegeSuggestions = [];
      _courseSuggestions = [];
    });

    // 2) parent screen ko "saare filters empty ho gaye" return karo
    const cleared = InstituteFilter.empty; // ya: const InstituteFilter();

    Navigator.pop(context, cleared);   // 👈 IMPORTANT: value pass karo

    // 3) snackbar (optional)
    showSuccesSnackBar(context, "All filters cleared");
  }


  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    InputDecoration _pillDecoration({
      required String hint,
      Widget? suffix,
    }) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9BA6A8),
          fontSize: 14,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: suffix ??
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xff003840),
              ),
        ),
        suffixIconConstraints:
        const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: Color(0xFFB8D5D8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: Color(0xFFB8D5D8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: Color(0xff003840),
            width: 1.3,
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height, // full height
        decoration: const BoxDecoration(
          color: Color(0xffEBF6F7),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Scrollable content upar
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Header: title + close
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff003840),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xff003840),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),

                      const SizedBox(height: 12),

                      // 🏫 College
                      const Text(
                        'College Name',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff003840),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _collegeCtrl,
                        // Typed text → bold + colored
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff003840),
                          fontSize: 14,
                        ),
                        onChanged: _onCollegeChanged,
                        decoration: _pillDecoration(
                          hint: 'Select College',
                          suffix: _loadingColleges
                              ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                              : const Icon(
                            Icons.search,
                            color: Color(0xff003840),
                          ),
                        ).copyWith(
                          // 👇 HINT TEXT NORMAL (not bold)
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xff003840),   // 👈 border color
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xff003840),   // 👈 focus border color
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Using dropdown code

                      // if (_collegeSuggestions.isNotEmpty) ...[
                      //   const SizedBox(height: 6),
                      //   Container(
                      //     constraints:
                      //     const BoxConstraints(maxHeight: 180),
                      //     decoration: BoxDecoration(
                      //       color: Colors.white,
                      //       borderRadius: BorderRadius.circular(12),
                      //       border: Border.all(
                      //           color: Colors.grey.shade200),
                      //     ),
                      //     child: ListView.builder(
                      //       shrinkWrap: true,
                      //       itemCount: _collegeSuggestions.length,
                      //       itemBuilder: (context, index) {
                      //         final item = _collegeSuggestions[index];
                      //         return ListTile(
                      //           dense: true,
                      //           title: Text(
                      //             item.name,
                      //             style:
                      //             const TextStyle(fontSize: 13),
                      //           ),
                      //           onTap: () {
                      //             setState(() {
                      //               _selectedCollegeId = item.id;
                      //               _collegeCtrl.text = item.name;
                      //               _collegeSuggestions = [];
                      //             });
                      //           },
                      //         );
                      //       },
                      //     ),
                      //   ),
                      // ],

                      const SizedBox(height: 16),

                      // 🎓 Course
                      const Text(
                        'Course',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff003840),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _courseCtrl,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff003840),
                          fontSize: 14,
                        ),
                        onChanged: _onCourseChanged,
                        decoration: _pillDecoration(
                          hint: 'Select Course',
                          suffix: _loadingCourses
                              ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                              : const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xff003840),
                          ),
                        ).copyWith(
                          // 👇 HINT TEXT NORMAL (not bold)
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xff003840),  // 👈 Border color
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xff003840),  // 👈 Focus border
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      if (_courseSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          constraints:
                          const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Color(0xFF003840)),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _courseSuggestions.length,
                            itemBuilder: (context, index) {
                              final item = _courseSuggestions[index];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  item.name,
                                  style:
                                  const TextStyle(fontSize: 13),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCourseId = item.id;
                                    _courseCtrl.text = item.name;
                                    _courseSuggestions = [];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      // 👤 Student Name (NEW)
                      const Text(
                        'Student Name',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff003840),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _studentCtrl,

                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff003840),
                          fontSize: 14,
                        ),

                        decoration: _pillDecoration(
                          hint: 'Enter Student Name',
                          suffix: const Icon(
                            Icons.search,
                            color: Color(0xff003840),
                          ),
                        ).copyWith(
                          hintStyle: TextStyle(          // 👈 HINT STYLE yahan likho
                            color: Colors.grey[500],
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xff003840),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xff003840),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),


                      const SizedBox(height: 16),

                      // 📅 Passout Year
                      const Text(
                        'Passout Year',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff003840),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passoutCtrl,
                        // Typed text → bold + colored
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff003840),
                          fontSize: 14,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: _pillDecoration(
                          hint: 'Select Year',
                          suffix: const Icon(
                            Icons.search,
                            color: Color(0xff003840),
                          ),
                        ).copyWith(
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xff003840),   // 👈 same border color
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xff003840),   // 👈 focus border color
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ Status
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff003840),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownSearch<String>(
                        items: const ['Approved', 'Denied'],
                        selectedItem: _selectedStatus,
                        // select hone par state update
                        onChanged: (v) {
                          setState(() => _selectedStatus = v);
                        },

                        // 👇 Text design – same as Process Listing example
                        dropdownBuilder: (context, selectedItem) {
                          final text = selectedItem ?? 'Select Status';
                          final isSelected = selectedItem != null;

                          return Text(
                            text,
                            style: TextStyle(
                              color: isSelected ? const Color(0xff003840) : Colors.grey[500],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },

                        // 👇 yahan height + borderRadius dono control karo
                        popupProps: PopupProps.menu(
                          showSearchBox: false,
                          fit: FlexFit.loose,
                          constraints: const BoxConstraints(
                            maxHeight: 220,      // dropdown ki max height kam
                          ),
                        ),


                        // 👇 Same rounded pill InputDecoration
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: _pillDecoration(
                            hint: 'Select Status',
                            suffix: const SizedBox.shrink(),
                          ).copyWith(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(
                                color: Color(0xFF003840),  // 👈 Border color added
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(
                                color: Color(0xFF003840),  // 👈 Focus border color
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),


                        // 👇 Right side arrow icon style
                        dropdownButtonProps: const DropdownButtonProps(
                          icon: Icon(
                            Icons.expand_more,
                            color: Color(0xff003840),
                            size: 28,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // 🔘 Bottom fixed buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 120,
                    child: TextButton.icon(
                      onPressed: _reset,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        backgroundColor: const Color(0xff003840),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Clear', style: TextStyle(fontSize: 14)),
                    ),
                  ),

                  SizedBox(
                    width: 120,
                    child: TextButton.icon(
                      onPressed: _apply,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        backgroundColor: const Color(0xff003840),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Apply', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              )

            ],
          ),
        ),
      ),
    );
  }


  void showSuccesSnackBar(BuildContext context, String message) {
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

}
