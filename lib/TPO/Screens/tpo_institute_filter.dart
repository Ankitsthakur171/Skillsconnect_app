// lib/screens/institute_filter_screen.dart
// Drop-in screen: Institute list with 4 filters + server-side pagination
// Dependencies: dio, shared_preferences, dropdown_search, flutter_svg (optional for logos)

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: apne constants file ka path set karo
import '../../Constant/constants.dart'; // must provide BASE_URL

class InstituteFilterScreen extends StatefulWidget {
  const InstituteFilterScreen({Key? key}) : super(key: key);

  @override
  State<InstituteFilterScreen> createState() => _InstituteFilterScreenState();
}

/* -------------------------- Models / Helpers -------------------------- */

class _CollegeOption {
  final int id;
  final String name;
  const _CollegeOption({required this.id, required this.name});
  @override
  String toString() => name;
}

class _CourseOption {
  final int id;
  final String name;
  const _CourseOption({required this.id, required this.name});
  @override
  String toString() => name;
}

class _StudentItem {
  final String name;
  final String college;
  final String? avatar; // url (may be svg/png)
  final String course;
  final String year;
  final String status; // Approved / Denied / etc.

  _StudentItem({
    required this.name,
    required this.college,
    required this.course,
    required this.year,
    required this.status,
    this.avatar,
  });

  factory _StudentItem.fromApi(Map<String, dynamic> m) {
    return _StudentItem(
      name: (m['student_name'] ?? m['name'] ?? '').toString(),
      college: (m['college_name'] ?? '').toString(),
      course: (m['course_name'] ?? '').toString(),
      year: (m['passout_year'] ?? '').toString(),
      status: (m['status'] ?? '').toString(),
      avatar: (m['image'] ?? m['avatar'] ?? '').toString().isEmpty
          ? null
          : (m['image'] ?? m['avatar']).toString(),
    );
  }
}

Future<Map<String, String>> _authHeaders() async {
  final sp = await SharedPreferences.getInstance();
  // NOTE: tumhare project me actual token key 'auth_token' hota hai
  final token = sp.getString('auth_token');
  return {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };
}

Future<List<_CollegeOption>> _fetchColleges(String search) async {
  // TODO: Agar tumhara endpoint alag ho to URL/keys replace karo
  final resp = await Dio().post(
    '${BASE_URL}common/get-college-list',
    options: Options(headers: await _authHeaders()),
    data: {
      "college_id": "",
      "state_id": "",
      "city_id": "",
      "course_id": "",
      "specialization_id": "",
      "search": search,
      "page": 1,
    },
  );
  if (resp.statusCode != 200) return [];
  final data = resp.data;
  final List list = data['data']?['options'] ?? [];
  return list.map<_CollegeOption>((e) {
    final id = e['id'] is int ? e['id'] : int.tryParse('${e['id']}') ?? 0;
    final name = (e['name'] ?? '').toString();
    return _CollegeOption(id: id, name: name);
  }).toList();
}

Future<List<_CourseOption>> _fetchCourses(String search) async {
  // TODO: Agar tumhara course endpoint alag ho to URL/keys replace karo
  final resp = await Dio().post(
    '${BASE_URL}common/get-course-list',
    options: Options(headers: await _authHeaders()),
    data: {
      "search": search,
      "page": 1,
    },
  );
  if (resp.statusCode != 200) return [];
  final data = resp.data;
  final List list = data['data']?['options'] ?? [];
  return list.map<_CourseOption>((e) {
    final id = e['id'] is int ? e['id'] : int.tryParse('${e['id']}') ?? 0;
    final name = (e['name'] ?? '').toString();
    return _CourseOption(id: id, name: name);
  }).toList();
}

/* ------------------------------ Screen ------------------------------ */

class _InstituteFilterScreenState extends State<InstituteFilterScreen> {
  // active filters
  String _collegeName = '';
  int? _courseId;
  String _passoutYear = '';
  String _studentName = '';

  // list state
  final List<_StudentItem> _items = [];
  final ScrollController _scroll = ScrollController();

  // pagination
  static const int _pageSize = 5; // tumne 5-5 bola tha
  int _page = 1;
  bool _isFetching = false;
  bool _hasMore = true;

  // search debounce
  Timer? _debounce;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadFirstPage();

    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        _loadNextPage();
      }
    });

    _searchCtrl.addListener(() {
      // student_name ko live search se map karte hain
      _studentName = _searchCtrl.text.trim();
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        _resetAndFetch();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    _page = 1;
    _hasMore = true;
    _items.clear();
    setState(() {});
    await _fetchPage(_page);
  }

  Future<void> _loadNextPage() async {
    if (_isFetching || !_hasMore) return;
    await _fetchPage(_page + 1);
  }

  Future<void> _resetAndFetch() async {
    _page = 1;
    _hasMore = true;
    _items.clear();
    setState(() {});
    await _fetchPage(_page);
  }

  Future<void> _fetchPage(int pageNo) async {
    if (_isFetching) return;
    _isFetching = true;
    setState(() {});

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: await _authHeaders(),
      ));

      final body = {
        "college_name": _collegeName,
        "course_id": _courseId?.toString() ?? "",
        "passout_year": _passoutYear,
        "student_name": _studentName,
        "status": "",             // (as per your schema)
        "limit": _pageSize,       // server-side paging
        "offset": (_pageSize * (pageNo - 1)),
        "page": pageNo,
      };

      final resp = await dio.post(
        '${BASE_URL}tpo/student-listing',
        data: jsonEncode(body),
      );

      if (resp.statusCode == 200) {
        // Expected structure: { status:true, data:{ list:[...] , total: ... } }
        final data = resp.data;
        final List list = data['data']?['list'] ?? data['list'] ?? [];
        final items = list.map<_StudentItem>((e) => _StudentItem.fromApi(e)).toList();

        setState(() {
          _items.addAll(items);
          _page = pageNo;
          _hasMore = items.length == _pageSize;
        });
      } else {
        // non-200 -> treat as no more
        setState(() => _hasMore = false);
      }
    } on DioException catch (e) {
      // log + stop further attempts this cycle
      // ignore: avoid_print
      print('fetch error: ${e.response?.statusCode} ${e.response?.data}');
      setState(() => _hasMore = false);
    } finally {
      _isFetching = false;
      setState(() {});
    }
  }

  void _openFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initCollegeName: _collegeName,
        initCourseId: _courseId,
        initPassoutYear: _passoutYear,
        initStudentName: _studentName,
        onApply: ({
          required String collegeName,
          required int? courseId,
          required String passoutYear,
          required String studentName,
        }) {
          _collegeName = collegeName;
          _courseId = courseId;
          _passoutYear = passoutYear;
          _studentName = studentName;
          _searchCtrl.text = studentName; // sync search box
          _resetAndFetch();
        },
        onClear: () {
          _collegeName = '';
          _courseId = null;
          _passoutYear = '';
          _studentName = '';
          _searchCtrl.clear();
          _resetAndFetch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canLoadMore = _hasMore && !_isFetching;

    return Scaffold(
      backgroundColor: const Color(0xffEBF6F7),
      appBar: AppBar(
        backgroundColor: const Color(0xffEBF6F7),
        elevation: 0,
        title: const Text(
          'Institute Filter',
          style: TextStyle(color: Color(0xff003840)),
        ),
        iconTheme: const IconThemeData(color: Color(0xff003840)),
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
          ),
        ],
      ),

      body: Column(
        children: [
          // Search (Student Name live)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by student name',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFirstPage,
              child: ListView.builder(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length + (canLoadMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    // loader row
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final it = _items[index];
                  return _StudentTile(item: it);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ Widgets ------------------------------ */

class _StudentTile extends StatelessWidget {
  final _StudentItem item;
  const _StudentTile({Key? key, required this.item}) : super(key: key);

  Widget _avatar(String? url) {
    if (url == null || url.isEmpty) {
      return const CircleAvatar(
        radius: 22,
        child: Icon(Icons.person_outline),
      );
    }
    if (url.toLowerCase().endsWith('.svg')) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child: SvgPicture.network(
          url,
          width: 30, height: 30, fit: BoxFit.contain,
        ),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final pillColor = item.status.toLowerCase() == 'approved'
        ? Colors.green
        : (item.status.toLowerCase() == 'denied'
        ? Colors.red
        : Colors.grey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: _avatar(item.avatar),
        title: Text(
          item.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff003840),
          ),
        ),
        subtitle: Text(
          '${item.college}\n${item.course} • ${item.year}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: pillColor.withOpacity(.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: pillColor.withOpacity(.5)),
          ),
          child: Text(
            item.status.isEmpty ? '—' : item.status,
            style: TextStyle(
              color: pillColor.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------------- Filter Sheet --------------------------- */

class _FilterSheet extends StatefulWidget {
  final String initCollegeName;
  final int? initCourseId;
  final String initPassoutYear;
  final String initStudentName;

  final void Function({
  required String collegeName,
  required int? courseId,
  required String passoutYear,
  required String studentName,
  }) onApply;

  final VoidCallback onClear;

  const _FilterSheet({
    Key? key,
    required this.initCollegeName,
    required this.initCourseId,
    required this.initPassoutYear,
    required this.initStudentName,
    required this.onApply,
    required this.onClear,
  }) : super(key: key);

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  _CollegeOption? _selectedCollege;
  _CourseOption? _selectedCourse;
  late final TextEditingController _passoutCtrl;
  late final TextEditingController _studentCtrl;

  @override
  void initState() {
    super.initState();
    _selectedCollege = widget.initCollegeName.isNotEmpty
        ? _CollegeOption(id: 0, name: widget.initCollegeName)
        : null;
    _selectedCourse = widget.initCourseId != null
        ? _CourseOption(id: widget.initCourseId!, name: 'Selected')
        : null;
    _passoutCtrl = TextEditingController(text: widget.initPassoutYear);
    _studentCtrl = TextEditingController(text: widget.initStudentName);
  }

  @override
  void dispose() {
    _passoutCtrl.dispose();
    _studentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = const BorderRadius.vertical(top: Radius.circular(20));

    return Container(
      height: MediaQuery.of(context).size.height * .9,
      decoration: BoxDecoration(
        color: const Color(0xffEBF6F7),
        borderRadius: radius,
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          Container(
            width: 42, height: 5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black26, borderRadius: BorderRadius.circular(999),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text('Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(height: 16),

          // College
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("College", style: TextStyle(color: Color(0xff003840))),
          ),
          const SizedBox(height: 6),
          DropdownSearch<_CollegeOption>(
            asyncItems: (s) => _fetchColleges(s),
            itemAsString: (c) => c.name,
            selectedItem: _selectedCollege,
            compareFn: (a,b) => a.id == b.id && a.name == b.name,
            popupProps: const PopupProps.menu(showSearchBox: true, isFilterOnline: true),
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: 'Select College',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
              ),
            ),
            dropdownBuilder: (ctx, item) => Text(
              item?.name ?? 'Select College',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item == null ? Colors.grey[500] : const Color(0xff003840),
                fontWeight: item == null ? FontWeight.normal : FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onChanged: (v) => setState(() => _selectedCollege = v),
          ),
          const SizedBox(height: 12),

          // Course
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Course", style: TextStyle(color: Color(0xff003840))),
          ),
          const SizedBox(height: 6),
          DropdownSearch<_CourseOption>(
            asyncItems: (s) => _fetchCourses(s),
            itemAsString: (c) => c.name,
            selectedItem: _selectedCourse,
            compareFn: (a,b) => a.id == b.id,
            popupProps: const PopupProps.menu(showSearchBox: true, isFilterOnline: true),
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: 'Select Course',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
              ),
            ),
            dropdownBuilder: (ctx, item) => Text(
              item?.name ?? 'Select Course',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item == null ? Colors.grey[500] : const Color(0xff003840),
                fontWeight: item == null ? FontWeight.normal : FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onChanged: (v) => setState(() => _selectedCourse = v),
          ),
          const SizedBox(height: 12),

          // Passout Year
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Passout Year", style: TextStyle(color: Color(0xff003840))),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _passoutCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 2022',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Student Name
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Student Name", style: TextStyle(color: Color(0xff003840))),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _studentCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Type name (no dropdown)',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
            ),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                label: const Text('Clear', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xff003840),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  widget.onClear();
                  Navigator.pop(context);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                label: const Text('Apply', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff003840),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  widget.onApply(
                    collegeName: _selectedCollege?.name ?? '',
                    courseId: _selectedCourse?.id,
                    passoutYear: _passoutCtrl.text.trim(),
                    studentName: _studentCtrl.text.trim(),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
