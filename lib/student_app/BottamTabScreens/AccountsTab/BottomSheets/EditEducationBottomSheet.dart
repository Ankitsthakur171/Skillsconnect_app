
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../../Model/EducationDetail_Model.dart';
import '../../../Utilities/AllCourse_Api.dart';
import '../../../Utilities/ApiConstants.dart';
import '../../../Utilities/CollegeList_Api.dart';
import '../../../Utilities/MyAccount_Get_Post/EducationDetail_Api.dart';
import '../../../Utilities/Specialization_Api.dart';
import 'CustomDropDowns/AsyncSearchDropDownField.dart';
import 'CustomDropDowns/CustomDropdownEducation.dart';
import '../../../Utilities/DegreeApi.dart';
import '../../../Utilities/BoardApi.dart';
import '../../../Utilities/MediumApi.dart';

class EditEducationBottomSheet extends StatefulWidget {
  final EducationDetailModel? initialData;
  final Function(Map<String, dynamic> data) onSave;
  final List<String>? existingDegrees;

  const EditEducationBottomSheet({
    super.key,
    required this.onSave,
    this.initialData,
    this.existingDegrees,
  });

  @override
  State<EditEducationBottomSheet> createState() =>
      _EditEducationBottomSheetState();
}

class _EditEducationBottomSheetState extends State<EditEducationBottomSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _marksController;
  late TextEditingController _boardNameController;
  late TextEditingController _percentageController;
  String degreeName = '';
  String? degreeId;
  String? boardId;
  String? mediumId;
  String? selectedBoard;
  String? selectedMedium;
  late String collegeName;
  late String courseName;
  late String specializationName;
  late String passingYear;
  late String passingMonth;
  late String courseType;
  late String gradingSystem;
  bool isLoading = true;
  bool _loadingBoards = false;
  bool _loadingMediums = false;
  bool _saving = false;
  final GlobalKey _marksFieldKey = GlobalKey();
  final FocusNode _marksFocusNode = FocusNode();
  bool _marksInvalid = false;
  String? _marksError;
  bool _percentageInvalid = false;
  String? _percentageError;
  List<Map<String, String>> specializationItems = [];
  List<String> specializationList = [];
  String? selectedSpecializationId;
  List<Map<String, String>> courseItems = [];
  List<String> courseList = [];
  String? selectedCourseId;
  List<String> collegeList = [];
  List<Map<String, dynamic>> degreeItems = [];
  List<String> degreeList = [];
  List<Map<String, dynamic>> boardItems = [];
  List<String> boardList = [];
  List<Map<String, dynamic>> mediumItems = [];
  List<String> mediumList = [];
  List<Map<String, String>> collegeItems = [];
  String? selectedCollegeId;

  final List<String> courseTypeList = [
    'Full-Time',
    'Part-Time',
    'Corresponding/Distance',
  ];

  final List<String> gradingSystemList = [
    'GPA out of 10',
    'GPA out of 4',
    'Percentage',
  ];

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  bool _snackBarShown = false;
  OverlayEntry? _overlayEntry;

  void _showSnackBarOnce(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.red,
    int cooldownSeconds = 2,
  }) {
    if (_snackBarShown) return;
    _snackBarShown = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(Duration(seconds: cooldownSeconds), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _snackBarShown = false;
    });
  }

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    _marksController = TextEditingController(text: data?.marks ?? '');
    _boardNameController = TextEditingController(text: data?.boardName ?? '');
    _percentageController = TextEditingController(text: data?.grade ?? '');

    degreeName = data?.degreeName ?? '';
    collegeName = data?.collegeMasterName ?? '';
    courseName = data?.courseName ?? '';
    specializationName = data?.specializationName ?? '';
    passingYear = data?.passingYear ?? (DateTime.now().year.toString());
    passingMonth = data?.passingMonth ?? 'Jan';
    courseType = data?.courseType ?? 'Full-Time';
    gradingSystem = data?.gradeName ?? 'Percentage';

    _marksFocusNode.addListener(_handleMarksFocusChange);
    _marksController.addListener(_validateMarks);
    _percentageController.addListener(_validatePercentage);

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });

    _initData();
  }

  @override
  void dispose() {
    _marksFocusNode.removeListener(_handleMarksFocusChange);
    _marksFocusNode.dispose();
    _marksController.removeListener(_validateMarks);
    _percentageController.removeListener(_validatePercentage);
    _marksController.dispose();
    _boardNameController.dispose();
    _percentageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      await Future.wait([
        _fetchDegreeListUsingApi(),
        _fetchCollegeList(),
        _fetchCourseList(),
        _fetchSpecializationList(),
      ]);
      if (_isSchoolDegree && mounted) {
        await _fetchBoardsAndMediums();
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String? _findIdByNameSimple(
      List<Map<String, dynamic>> items, String nameKey, String? name
      )
  {
    if (name == null || name.trim().isEmpty) return null;
    for (final item in items) {
      try {
        final itemName = (item[nameKey] ?? '').toString().trim();
        if (itemName == name.trim()) {
          final id = item['id'];
          return id?.toString();
        }
      } catch (_) {}
    }
    return null;
  }

  void _handleMarksFocusChange() {
    if (_marksFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_marksFieldKey.currentContext != null) {
          Scrollable.ensureVisible(
            _marksFieldKey.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _fetchBoardsAndMediums() async {
    setState(() {
      _loadingBoards = true;
      _loadingMediums = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final boards = await BoardApi.fetchBoards(
          authToken: authToken, connectSid: connectSid, limit: 100);
      final mediums = await MediumApi.fetchMediums(
          authToken: authToken, connectSid: connectSid, limit: 100);

      if (!mounted) return;

      setState(() {
        boardItems = boards;
        boardList = boardItems
            .map((e) => (e['board_name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        if (boardList.isEmpty) boardList = ['No Boards Available'];

        mediumItems = mediums;
        mediumList = mediumItems
            .map((e) => (e['medium_name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        if (mediumList.isEmpty) mediumList = ['No Mediums Available'];

        selectedBoard = (widget.initialData?.boardName != null &&
                widget.initialData!.boardName!.isNotEmpty)
            ? widget.initialData!.boardName
            : (boardList.isNotEmpty ? boardList[0] : null);
        boardId = _findIdByNameSimple(boardItems, 'board_name', selectedBoard);

        selectedMedium = (widget.initialData?.mediumName != null &&
                widget.initialData!.mediumName!.isNotEmpty)
            ? widget.initialData!.mediumName
            : (mediumList.isNotEmpty ? mediumList[0] : null);
        mediumId =
            _findIdByNameSimple(mediumItems, 'medium_name', selectedMedium);
      });
    } catch (e, st) {
      debugPrint('Error fetching boards/mediums: $e\n$st');
      if (!mounted) return;
      setState(() {
        boardItems = [];
        boardList = ['No Boards Available'];
        mediumItems = [];
        mediumList = ['No Mediums Available'];
        selectedBoard = null;
        selectedMedium = null;
        boardId = null;
        mediumId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingBoards = false;
          _loadingMediums = false;
        });
      }
    }
  }

  Future<void> _fetchDegreeListUsingApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final fetched = await DegreeApi.fetchDegrees(
          authToken: authToken, connectSid: connectSid, limit: 200);
      if (!mounted) return;

      if (fetched.isNotEmpty) {
        setState(() {
          degreeItems = fetched;
          degreeList =
              degreeItems.map((e) => e['degree_name'].toString()).toList();
          if (widget.initialData?.degreeName != null &&
              widget.initialData!.degreeName!.isNotEmpty &&
              degreeList.contains(widget.initialData!.degreeName)) {
            degreeName = widget.initialData!.degreeName!;
            final matched = degreeItems.firstWhere(
                (e) => e['degree_name'] == degreeName,
                orElse: () => {});
            degreeId = matched['id']?.toString();
          } else {
            degreeName = degreeList.isNotEmpty ? degreeList[0] : '';
            degreeId = degreeItems.isNotEmpty
                ? degreeItems[0]['id']?.toString()
                : null;
          }
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        degreeItems = [];
        degreeList = ['No Degrees Available'];
        degreeName = degreeList[0];
        degreeId = null;
      });
    }
  }

  Future<void> _fetchCollegeList({String? query, int page = 1}) async {
    debugPrint("🔵 _fetchCollegeList() START -------------------------");
    debugPrint(
        "📤 Calling ApiService.fetchCollegeList(page:$page, query:'$query')");

    try {
      final items = await ApiService.fetchCollegeList(
        page: page,
        query: query,
      );

      debugPrint("📥 API returned:");
      debugPrint("➡️ items.length = ${items.length}");
      debugPrint("➡️ items = $items");

      if (!mounted) {
        debugPrint("⛔ Widget not mounted. RETURN");
        return;
      }

      setState(() {
        debugPrint("✔ Updating UI state with fetched college items");

        collegeItems = items;

        collegeList = collegeItems
            .map((e) => e['text'] ?? '')
            .where((s) => s.isNotEmpty)
            .toList();

        debugPrint("📌 collegeList.length = ${collegeList.length}");
        debugPrint("📌 collegeList = $collegeList");

        // ------------------------------------------------------
        // CASE 1 → No colleges
        // ------------------------------------------------------
        if (collegeList.isEmpty) {
          debugPrint("⚠️ No colleges returned — setting fallback");

          collegeList = ['No Colleges Available'];
          selectedCollegeId = null;
          collegeName = collegeList[0];

          debugPrint("selectedCollegeId = $selectedCollegeId");
          debugPrint("collegeName = $collegeName");
          return;
        }

        // ------------------------------------------------------
        // CASE 2 → There is some collegeName in state
        // ------------------------------------------------------
        debugPrint("🔍 Checking existing collegeName = '$collegeName'");

        if (collegeName.isNotEmpty) {
          debugPrint("🔎 Searching for matching collegeName...");

          final match = collegeItems.firstWhere(
            (e) => (e['text'] ?? '').toLowerCase() == collegeName.toLowerCase(),
            orElse: () => {},
          );

          debugPrint("🟣 match = $match");

          if (match.isNotEmpty && (match['id'] ?? '').toString().isNotEmpty) {
            selectedCollegeId = match['id']?.toString();
            collegeName = match['text'] ?? collegeName;

            debugPrint("✅ Existing selection FOUND");
            debugPrint("selectedCollegeId = $selectedCollegeId");
            debugPrint("collegeName = $collegeName");
          } else {
            debugPrint("❌ No match found. Using first college item");

            selectedCollegeId = collegeItems.first['id']?.toString();
            collegeName = collegeItems.first['text'] ?? collegeName;

            debugPrint("selectedCollegeId = $selectedCollegeId");
            debugPrint("collegeName = $collegeName");
          }

          return;
        }

        // ------------------------------------------------------
        // CASE 3 → No old selection, just pick first item
        // ------------------------------------------------------
        debugPrint("ℹ️ No previous collegeName. Auto-selecting first item.");

        selectedCollegeId = collegeItems.first['id']?.toString();
        collegeName = collegeItems.first['text'] ?? '';

        debugPrint("selectedCollegeId = $selectedCollegeId");
        debugPrint("collegeName = $collegeName");
      });

      debugPrint("🟢 _fetchCollegeList() END -------------------------");
    } catch (e, st) {
      debugPrint("🔥 ERROR in _fetchCollegeList: $e");
      debugPrint("STACKTRACE:\n$st");

      if (!mounted) {
        debugPrint("⛔ Widget unmounted during error.");
        return;
      }

      setState(() {
        debugPrint("🔧 Setting fallback values due to error");

        collegeItems = [];
        collegeList = ['No Colleges Available'];
        selectedCollegeId = null;

        if (collegeName.isEmpty) {
          collegeName = collegeList[0];
        }

        debugPrint("selectedCollegeId = $selectedCollegeId");
        debugPrint("collegeName = $collegeName");
      });
    }
  }

  Future<void> _fetchCourseList() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    try {
      final items = await CourseListApi.fetchCoursesWithIds(
        authToken: authToken,
        connectSid: connectSid,
      );
      if (!mounted) return;
      setState(() {
        courseItems = items;
        courseList = courseItems.map((m) => m['text'] ?? '').toList();
        if (courseName.isEmpty ||
            !courseList.contains(courseName) ||
            courseList.isEmpty) {
          courseName = courseList.isNotEmpty ? courseList[0] : '';
          selectedCourseId =
              courseItems.isNotEmpty ? courseItems[0]['id'] : null;
        } else {
          final match = courseItems.firstWhere(
            (m) => (m['text'] ?? '').toLowerCase() == courseName.toLowerCase(),
            orElse: () => {},
          );
          selectedCourseId = match.isNotEmpty ? match['id'] : null;
        }
        if (courseList.isEmpty) courseList = ['No Courses Available'];
      });
    } catch (e, st) {
      debugPrint('Error in _fetchCourseList: $e\n$st');
      if (!mounted) return;
      setState(() {
        courseItems = [];
        courseList = ['No Courses Available'];
        selectedCourseId = null;
        if (courseName.isEmpty) courseName = '';
      });
    }
  }

  Future<void> _fetchSpecializationList() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    String courseId = '';
    if ((selectedCourseId ?? '').isNotEmpty) {
      courseId = selectedCourseId!;
    } else {
      courseId = await _resolveCourseId(courseName);
    }

    if (courseId.isEmpty) {
      if (!mounted) return;
      setState(() {
        specializationItems = [];
        specializationList = ['No Specializations Available'];
        selectedSpecializationId = null;
        specializationName = '';
      });
      return;
    }

    try {
      final items = await SpecializationListApi.fetchSpecializationsWithIds(
        specializationName: '',
        courseId: courseId,
        authToken: authToken,
        connectSid: connectSid,
      );
      if (!mounted) return;
      setState(() {
        specializationItems = items;
        specializationList =
            specializationItems.map((m) => m['text'] ?? '').toList();
        if (specializationName.isNotEmpty) {
          final match = specializationItems.firstWhere(
            (m) =>
                (m['text'] ?? '').toLowerCase() ==
                specializationName.toLowerCase(),
            orElse: () => {},
          );
          selectedSpecializationId = match.isNotEmpty ? match['id'] : null;
        }
        if (selectedSpecializationId == null) {
          selectedSpecializationId = specializationItems.isNotEmpty
              ? specializationItems[0]['id']
              : null;
          if (specializationList.isNotEmpty && specializationName.isEmpty) {
            specializationName =
                specializationList.isNotEmpty ? specializationList[0] : '';
          }
        }
        if (specializationList.isEmpty) {
          specializationList = ['No Specializations Available'];
          specializationName = '';
          selectedSpecializationId = null;
        }
      });
    } catch (e, st) {
      debugPrint('❌ _fetchSpecializationList error: $e\n$st');
      if (!mounted) return;
      setState(() {
        specializationItems = [];
        specializationList = ['No Specializations Available'];
        selectedSpecializationId = null;
        specializationName = '';
      });
    }
  }

  Future<String> _resolveCourseId(String courseName) async {
    if (courseName.isEmpty || courseName == 'No Courses Available') return '';
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstantsStu.subUrl}master/course/list'),
            headers: {
              'Content-Type': 'application/json',
              'Cookie': 'authToken=$authToken; connect.sid=$connectSid'
            },
            body: jsonEncode({"course_name": courseName}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true &&
            data['data'] is List &&
            data['data'].isNotEmpty) {
          return data['data'][0]['id'].toString();
        }
      }
    } catch (_) {}
    return '';
  }

  bool get _isSchoolDegree {
    final name = degreeName.toLowerCase();
    return name.contains('class x') ||
        name.contains('class xii') ||
        name.contains('class 10') ||
        name.contains('class 12');
  }

  void _validateMarks() {
    final txt = _marksController.text.trim();
    if (txt.isEmpty) {
      if (_marksInvalid) {
        setState(() {
          _marksInvalid = false;
          _marksError = null;
        });
      }
      return;
    }

    final value = double.tryParse(txt.replaceAll(',', '.'));
    if (value == null) {
      setState(() {
        _marksInvalid = true;
        _marksError = 'Invalid number';
      });
      return;
    }

    double limit = 100.0;
    final gs = gradingSystem.toLowerCase();
    if (gs.contains('10')) {
      limit = 10.0;
    } else if (gs.contains('4')) {
      limit = 4.0;
    } else if (gs.contains('percentage')) {
      limit = 100.0;
    }

    if (value > limit || value < 0) {
      setState(() {
        _marksInvalid = true;
        _marksError = 'Maximum $limit allowed';
      });
    } else if (_marksInvalid) {
      setState(() {
        _marksInvalid = false;
        _marksError = null;
      });
    }
  }

  void _validatePercentage() {
    final txt = _percentageController.text.trim();
    if (txt.isEmpty) {
      if (_percentageInvalid) {
        setState(() {
          _percentageInvalid = false;
          _percentageError = null;
        });
      }
      return;
    }

    final value = double.tryParse(txt.replaceAll(',', '.'));
    if (value == null) {
      setState(() {
        _percentageInvalid = true;
        _percentageError = 'Invalid number';
      });
      return;
    }

    if (value > 100.0 || value < 0) {
      setState(() {
        _percentageInvalid = true;
        _percentageError = 'Maximum 100 allowed';
      });
    } else if (_percentageInvalid) {
      setState(() {
        _percentageInvalid = false;
        _percentageError = null;
      });
    }
  }

  void _debugLog(String msg) {
    final now = DateTime.now().toIso8601String();
    debugPrint('[$now] $msg');
  }

  Future<void> _attemptPostAndSave(Map<String, dynamic> payload) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    bool posted = false;
    final stopwatch = Stopwatch()..start();
    _debugLog('🔔 _attemptPostAndSave START');

    try {
      final payloadJson = jsonEncode(payload);
      _debugLog('🔎 Incoming payload: $payloadJson');
      _debugLog('_isSchoolDegree? $_isSchoolDegree');

      if (_isSchoolDegree) {
        final Map<String, dynamic> body = {};
        body['degreeType'] = payload['degreeType']?.toString() ?? '5';

        if (boardId != null && boardId!.isNotEmpty) {
          body['boardName'] = boardId;
        } else if (payload['boardId'] != null) {
          body['boardName'] = payload['boardId'].toString();
        } else if (payload['boardName'] != null) {
          body['boardName'] = payload['boardName'].toString();
        }

        if (mediumId != null && mediumId!.isNotEmpty) {
          body['medium'] = mediumId;
        } else if (payload['mediumId'] != null) {
          body['medium'] = payload['mediumId'].toString();
        } else if (payload['medium'] != null) {
          body['medium'] = payload['medium'].toString();
        }

        body['marks'] = payload['percentage']?.toString() ??
            payload['marks']?.toString() ??
            _percentageController.text.trim();
        body['month'] = payload['month']?.toString() ?? passingMonth;
        body['year'] = payload['yearOfPassing']?.toString() ??
            payload['year']?.toString() ??
            passingYear;

        if (payload['basic_education_id'] != null) {
          body['basic_education_id'] = payload['basic_education_id'].toString();
        } else if (payload['basicEducationId'] != null) {
          body['basic_education_id'] = payload['basicEducationId'].toString();
        } else if (widget.initialData?.basicEducationId != null &&
            widget.initialData!.basicEducationId! > 0) {
          body['basic_education_id'] =
              widget.initialData!.basicEducationId!.toString();
        }

        try {
          final swInner = Stopwatch()..start();
          posted =
              await EducationDetailApi.postBasicEducationSimple(body: body);
          swInner.stop();
          _debugLog(
              'BasicEducation POST result: $posted (elapsed=${swInner.elapsedMilliseconds}ms)');
        } catch (e, st) {
          posted = false;
          _debugLog('🔥 Exception BasicEducation POST: $e\n$st');
        }
      } else {
        final Map<String, dynamic> body = {};

        if (degreeId != null && degreeId!.isNotEmpty) {
          body['degreeType'] = degreeId;
        } else if (payload['degreeType'] != null) {
          body['degreeType'] = payload['degreeType'].toString();
        }

        if (courseType.isNotEmpty) body['course_type'] = courseType;

        if (gradingSystem.isNotEmpty) {
          final gs = gradingSystem.toLowerCase();
          if (gs.contains('10')) {
            body['grading_system'] = '1';
          } else if (gs.contains('4')) {
            body['grading_system'] = '2';
          } else {
            body['grading_system'] = '3';
          }
        }

        if (_marksController.text.trim().isNotEmpty) {
          body['marks'] = _marksController.text.trim();
        } else if (payload['marks'] != null) {
          body['marks'] = payload['marks'].toString();
        }

        body['month'] = payload['month']?.toString() ?? passingMonth;
        body['year'] = payload['year']?.toString() ?? passingYear;

        if (payload['educationid'] != null) {
          body['educationid'] = payload['educationid'].toString();
        } else if (widget.initialData?.educationId != null &&
            widget.initialData!.educationId! > 0) {
          body['educationid'] = widget.initialData!.educationId.toString();
        }

        body['college_id'] =
            (selectedCollegeId ?? payload['college_id'] ?? '').toString();
        body['course'] =
            (selectedCourseId ?? payload['course'] ?? '').toString();
        body['specialization'] =
            (selectedSpecializationId ?? payload['specialization'] ?? '')
                .toString();

        try {
          final swInner = Stopwatch()..start();
          posted =
              await EducationDetailApi.postHigherEducationSimple(body: body);
          swInner.stop();
          _debugLog(
              'HigherEducation POST result: $posted (elapsed=${swInner.elapsedMilliseconds}ms)');
        } catch (e, st) {
          posted = false;
          _debugLog('🔥 Exception HigherEducation POST: $e\n$st');
        }
      }
    } catch (e, st) {
      posted = false;
      _debugLog('🔥 Error in _attemptPostAndSave: $e');
      _debugLog('Stacktrace:\n$st');
    } finally {
      stopwatch.stop();
      if (!mounted) return;
      setState(() => isLoading = false);
      _debugLog('========== END POST ATTEMPT ==========');
      _debugLog(
          'Total elapsed: ${stopwatch.elapsedMilliseconds}ms, posted=$posted');
    }

    if (posted) {
      _showSnackBarOnce(context, 'Saved successfully.',
          backgroundColor: Colors.green);
    } else {
      _showSnackBarOnce(context, 'Save failed. Check console logs for details.',
          cooldownSeconds: 6);
    }

    try {
      widget.onSave(payload);
    } catch (e) {
      _debugLog("⚠️ onSave callback failed: $e");
    }
  }

  void _onSavePressed() {
    _debugLog('🔔 _onSavePressed START');

    final existing = widget.existingDegrees ?? [];
    final normalizedExisting =
        existing.map((e) => e.toLowerCase().trim()).toList();
    final candidate = degreeName.toLowerCase().trim();
    final bool isEditingSame = widget.initialData != null &&
        (widget.initialData!.degreeName?.toLowerCase().trim() ?? '') ==
            candidate;

    if (normalizedExisting.contains(candidate) && !isEditingSame) {
      _showSnackBarOnce(context,
          'You have already added "$degreeName". Duplicate entries are not allowed.');
      _debugLog('Duplicate entry detected, closing dialog');
      Navigator.of(context).pop();
      return;
    }

    if (!_isSchoolDegree) {
      final bool collegeResolved = (selectedCollegeId?.isNotEmpty ?? false) ||
          (collegeName.isNotEmpty && !collegeName.startsWith('No '));
      final bool courseResolved =
          (selectedCourseId?.toString().isNotEmpty ?? false) ||
              (courseName.isNotEmpty && !courseName.startsWith('No '));
      final bool specResolved =
          (selectedSpecializationId?.isNotEmpty ?? false) ||
              (specializationName.isNotEmpty &&
                  !specializationName.startsWith('No '));
      if (!collegeResolved || !courseResolved || !specResolved) {
        _showSnackBarOnce(context,
            'Please ensure College, Course and Specialization are selected/loaded');
        return;
      }
      if (_marksInvalid) {
        _showSnackBarOnce(context, _marksError ?? 'Please fix marks value');
        return;
      }
    } else {
      if ((selectedBoard == null || selectedBoard!.trim().isEmpty) ||
          (selectedMedium == null || selectedMedium!.trim().isEmpty) ||
          _percentageController.text.trim().isEmpty ||
          (passingYear.isEmpty)) {
        _showSnackBarOnce(
            context, 'Please fill board, medium, percentage and year');
        return;
      }
      if (_percentageInvalid) {
        _showSnackBarOnce(
            context, _percentageError ?? 'Please fix percentage value');
        return;
      }
    }

    final payload = <String, dynamic>{
      'degreeId': degreeId,
      'degreeName': degreeName,
      'passingYear': passingYear,
      'passingMonth': passingMonth,
      'courseType': courseType,
      'gradingSystem': gradingSystem,
      'marks': _marksController.text.trim(),
      'collegeName': collegeName,
      'courseName': courseName,
      'specializationName': specializationName,
    };

    if (_isSchoolDegree) {
      payload.addAll({
        'boardName': selectedBoard ?? _boardNameController.text.trim(),
        'boardId': boardId,
        'medium': selectedMedium,
        'mediumId': mediumId,
        'percentage': _percentageController.text.trim(),
        'yearOfPassing': passingYear,
        'basic_education_id': widget.initialData?.basicEducationId != null &&
                widget.initialData!.basicEducationId! > 0
            ? widget.initialData!.basicEducationId!.toString()
            : null,
      });
    } else {
      if ((selectedCollegeId ?? '').isNotEmpty)
        payload['college_id'] = selectedCollegeId;
      if ((selectedCourseId ?? '').isNotEmpty)
        payload['course'] = selectedCourseId;
      if ((selectedSpecializationId ?? '').isNotEmpty)
        payload['specialization'] = selectedSpecializationId;
      payload.addAll({
        'month': passingMonth,
        'year': passingYear,
        'course_type': courseType,
        'grading_system': gradingSystem,
        'educationid': widget.initialData?.educationId != null &&
                widget.initialData!.educationId! > 0
            ? widget.initialData!.educationId!.toString()
            : null,
      });
    }

    setState(() => _saving = true);
    _attemptPostAndSave(payload).whenComplete(() {
      if (mounted) setState(() => _saving = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.9,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: EdgeInsets.only(
                left: 18.1.w,
                right: 18.1.w,
                top: 18.1.h,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(18.1.r)),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit Education Details',
                              style: TextStyle(
                                fontSize: 16.2.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF003840),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  color: const Color(0xFF005E6A), size: 17.7.w),

                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              top: 9.h,
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 24.h,
                            ),
                            children: [
                              _buildLabel('Degree Type'),
                              SearchableDropdownField(
                                value: degreeName,
                                items: degreeList.isNotEmpty
                                    ? degreeList
                                    : ['No Degrees Available'],
                                onChanged: (val) async {
                                  setState(() {
                                    degreeName = val ?? '';
                                    final matched = degreeItems.firstWhere(
                                      (e) => e['degree_name'] == degreeName,
                                      orElse: () => {},
                                    );
                                    degreeId = matched['id']?.toString();
                                    selectedCourseId = null;
                                    courseName = '';
                                    specializationName = '';
                                    selectedSpecializationId = null;
                                  });
                                  if (_isSchoolDegree) {
                                    await _fetchBoardsAndMediums();
                                  }
                                },
                              ),
                              if (_isSchoolDegree) ...[
                                _buildLabel('Board name'),
                                _loadingBoards
                                    ? _buildShimmerBoard()
                                    : SearchableDropdownField(
                                        value: selectedBoard ??
                                            (boardList.isNotEmpty
                                                ? boardList[0]
                                                : null),
                                        items: boardList,
                                        onChanged: (val) {
                                          setState(() {
                                            selectedBoard = val;
                                            _boardNameController.text =
                                                val ?? '';
                                            boardId = _findIdByNameSimple(
                                                boardItems,
                                                'board_name',
                                                selectedBoard);
                                          });
                                        },
                                      ),
                                _buildLabel('Medium'),
                                _loadingMediums
                                    ? _buildShimmerMedium()
                                    : SearchableDropdownField(
                                        value: selectedMedium ??
                                            (mediumList.isNotEmpty
                                                ? mediumList[0]
                                                : null),
                                        items: mediumList,
                                        onChanged: (val) {
                                          setState(() {
                                            selectedMedium = val;
                                            mediumId = _findIdByNameSimple(
                                                mediumItems,
                                                'medium_name',
                                                selectedMedium);
                                          });
                                        },
                                      ),
                                _buildLabel('Your percentage'),
                                _buildTextField(
                                    'Enter percentage', _percentageController,
                                    keyboardType: TextInputType.number),
                                _buildLabel('Year of passing'),
                                SearchableDropdownField(
                                  value: passingYear,
                                  items: const [
                                    '2019',
                                    '2020',
                                    '2021',
                                    '2022',
                                    '2023',
                                    '2024',
                                    '2025',
                                    '2026',
                                    '2027',
                                    '2028',
                                    '2029'
                                  ],
                                  onChanged: (val) => setState(
                                      () => passingYear = val ?? passingYear),
                                ),
                              ] else ...[
                                _buildLabel('College'),
                                AsyncSearchableDropdownField(
                                  value: selectedCollegeId != null
                                      ? {
                                          'id': selectedCollegeId!,
                                          'text': collegeName
                                        }
                                      : null,
                                  fetcher: ({int page = 1, String? query}) =>
                                      ApiService.fetchCollegeList(
                                          page: page, query: query),
                                  onChanged: (item) {
                                    setState(() {
                                      if (item != null) {
                                        selectedCollegeId = item['id'];
                                        collegeName = item['text'] ?? '';
                                      } else {
                                        selectedCollegeId = null;
                                        collegeName = '';
                                      }
                                    });
                                  },
                                  label: 'Select College',
                                ),
                                _buildLabel('Course'),
                                AsyncSearchableDropdownField(
                                  key: ValueKey(
                                      'courses_for_degree_${degreeId ?? 'none'}'),
                                  value: selectedCourseId != null
                                      ? {
                                          'id': selectedCourseId!,
                                          'text': courseName
                                        }
                                      : null,
                                  fetcher: (
                                      {int page = 1, String? query}) async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final authToken =
                                        prefs.getString('authToken') ?? '';
                                    final connectSid =
                                        prefs.getString('connectSid') ?? '';
                                    return await CourseListApi
                                        .fetchCoursesWithIds(
                                      page: page,
                                      query: query,
                                      degreeId: degreeId,
                                      authToken: authToken,
                                      connectSid: connectSid,
                                    );
                                  },
                                  onChanged: (item) {
                                    setState(() {
                                      if (item != null) {
                                        selectedCourseId = item['id'];
                                        courseName = item['text'] ?? '';
                                      } else {
                                        selectedCourseId = null;
                                        courseName = '';
                                      }
                                    });
                                    _fetchSpecializationList();
                                  },
                                  label: 'Select Course',
                                ),
                                _buildLabel('Specialization'),
                                SearchableDropdownField(
                                  value: specializationName,
                                  items: specializationList,
                                  onChanged: (val) {
                                    setState(() {
                                      specializationName = val ?? '';
                                      final match =
                                          specializationItems.firstWhere(
                                        (m) =>
                                            (m['text'] ?? '') ==
                                            specializationName,
                                        orElse: () => {},
                                      );
                                      selectedSpecializationId =
                                          match.isNotEmpty
                                              ? match['id']
                                              : selectedSpecializationId;
                                    });
                                  },
                                ),
                                _buildLabel('Course Type'),
                                SearchableDropdownField(
                                  value: courseType,
                                  items: courseTypeList,
                                  onChanged: (val) =>
                                      setState(() => courseType = val ?? ''),
                                ),
                                _buildLabel('Grading System'),
                                SearchableDropdownField(
                                  value: gradingSystem,
                                  items: gradingSystemList,
                                  onChanged: (val) {
                                    setState(() => gradingSystem = val ?? '');
                                    _validateMarks();
                                  },
                                ),
                                _buildLabel('Marks'),
                                _buildTextField(
                                    'Enter percentage or grade',
                                    _marksController,
                                    keyboardType: TextInputType.number,
                                    key: _marksFieldKey,
                                    focusNode: _marksFocusNode
                                ),
                                _buildLabel('Year of Passing'),
                                SearchableDropdownField(
                                  value: passingYear,
                                  items: const [
                                    '2019',
                                    '2020',
                                    '2021',
                                    '2022',
                                    '2023',
                                    '2024',
                                    '2025',
                                    '2026',
                                    '2027',
                                    '2028',
                                    '2029'
                                  ],
                                  onChanged: (val) =>
                                      setState(() => passingYear = val ?? ''),
                                ),
                                _buildLabel('Month of Passing'),
                                SearchableDropdownField(
                                  value: passingMonth,
                                  items: const [
                                    'Jan',
                                    'Feb',
                                    'Mar',
                                    'Apr',
                                    'May',
                                    'Jun',
                                    'Jul',
                                    'Aug',
                                    'Sep',
                                    'Oct',
                                    'Nov',
                                    'Dec'
                                  ],
                                  onChanged: (val) =>
                                      setState(() => passingMonth = val ?? ''),
                                ),
                              ],
                              SizedBox(height: 27.1.h),
                              ElevatedButton(
                                onPressed: _saving ? null : _onSavePressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF005E6A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27.1.r),
                                  ),
                                  minimumSize: Size.fromHeight(45.1.h),
                                ),
                                child: _saving
                                    ? SizedBox(
                                        height: 18.1.h,
                                        width: 18.1.w,
                                        child: const CircularProgressIndicator(
                                            strokeWidth: 1.8,
                                            color: Colors.white
                                        ),
                                      )
                                    : Text(
                                    'Save',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.7.sp)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ===== UI helpers =====
  Widget _buildLabel(String text) => Padding(
        padding: EdgeInsets.only(top: 14.4.h, bottom: 5.4.h),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 14.4.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF003840)),
        ),
      );

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    Key? key,
    FocusNode? focusNode,
  }) {
    String? error;
    if (controller == _marksController) {
      error = _marksInvalid ? _marksError : null;
    } else if (controller == _percentageController) {
      error = _percentageInvalid ? _percentageError : null;
    }

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      focusNode: focusNode,
      key: key,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12.4.sp),
        errorText: error,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.8.r)),
      ),
      style: TextStyle(fontSize: 12.4.sp),
    );
  }

  Widget _buildShimmerBoard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
    );
  }

  Widget _buildShimmerMedium() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
    );
  }
}
