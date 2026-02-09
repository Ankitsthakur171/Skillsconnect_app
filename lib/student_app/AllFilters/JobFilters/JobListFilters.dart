import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Utilities/JobFilterOptionsApi.dart';
import '../../Utilities/JobLocationsApi.dart';
import '../../BottamTabScreens/AccountsTab/BottomSheets/CustomDropDowns/CustomDropdownJobFilters.dart';

class Joblistfilters extends StatefulWidget {
  final Map<String, dynamic> currentFilters;

  const Joblistfilters({
    super.key,
    this.currentFilters = const {},
  });

  @override
  State<Joblistfilters> createState() => _JoblistfiltersState();
}

class _JoblistfiltersState extends State<Joblistfilters>
    with SingleTickerProviderStateMixin {
  late TextEditingController jobTitleController;
  late TextEditingController companyNameController;
  DateTime? _startDate;
  DateTime? _endDate;

  String selectedJobTypeName = "Full-Time";
  String selectedCourseName = "Select Course";
  String selectedLocationName = "All Locations";
  int? selectedJobTypeId;
  int? selectedCourseId;
  int? selectedLocationId;
  List<Map<String, dynamic>> jobTypes = [];
  List<Map<String, dynamic>> courses = [];
  List<String> locationNames = [];
  List<Map<String, dynamic>> locationsData = [];
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Global keys for dropdown management
  final GlobalKey _jobTypeDropdownKey = GlobalKey();
  final GlobalKey _courseDropdownKey = GlobalKey();
  final GlobalKey _locationDropdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    jobTitleController = TextEditingController(
      text: widget.currentFilters['jobTitle']?.toString() ?? '',
    );
    companyNameController = TextEditingController(
      text: widget.currentFilters['company_name']?.toString() ?? '',
    );
    _startDate = _parseDate((widget.currentFilters['posted_on'] ??
        widget.currentFilters['start_date'])
      ?.toString());
    _endDate =
      _parseDate(widget.currentFilters['end_date']?.toString());

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _loadAllFilters();
  }

  @override
  void dispose() {
    jobTitleController.dispose();
    companyNameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  int? _extractIdFromFilters(List<String> possibleKeys) {
    for (final key in possibleKeys) {
      final val = widget.currentFilters[key];
      if (val == null) continue;
      if (val is int) return val;
      final parsed = int.tryParse(val.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  int? _findLocationIdByName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final n = name.trim().toLowerCase();
    try {
      final found = locationsData.firstWhere((loc) {
        final ln = (loc['name']?.toString() ?? '').trim().toLowerCase();
        return ln == n;
      });
      final raw = found['id'];
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw);
    } catch (_) {}
    return null;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate({required bool isStart}) async {
    _closeAllDropdowns();
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }

      if (_startDate != null && _endDate != null) {
        if (_endDate!.isBefore(_startDate!)) {
          final temp = _startDate;
          _startDate = _endDate;
          _endDate = temp;
        }
      }
    });
  }

  Future<void> _loadAllFilters() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print("JobListFilters → Loading filter options + locations...");
      }
      final filterResult = await JobFilterOptionsApi.fetchFilterOptions();
      final rawLocations = await JobLocationsApi.fetchLocationsRaw();

      if (kDebugMode) {
        print("JobListFilters → filterResult: $filterResult");
      }

      if (kDebugMode) {
        print("JobListFilters → rawLocations: $rawLocations");
      }

      final List<Map<String, dynamic>> rawCourses =
          List<Map<String, dynamic>>.from(
        (filterResult['courses'] as List),
      );

      final dynamic jtRaw =
          filterResult['jobTypes'] ?? filterResult['job_type'];

      if (jtRaw is! Map) {
        throw Exception(
            "JobListFilters → jobTypes is not a map. Received: $jtRaw");
      }

      final Map<String, dynamic> jobTypesMap = Map<String, dynamic>.from(jtRaw);
      if(kDebugMode){
        print("JobListFilters → jobTypes raw map: $jobTypesMap");
      }

      final List<Map<String, dynamic>> loadedJobTypes = [];
      jobTypesMap.forEach((key, value) {
        int? id;
        String? name;

        final intKey = int.tryParse(key.toString());
        final intValue = int.tryParse(value.toString());

        if (intKey != null && intValue == null) {
          id = intKey;
          name = value.toString();
        } else if (intKey == null && intValue != null) {
          id = intValue;
          name = key.toString();
        } else {
          id = intValue ?? 0;
          name = key.toString();
        }

        loadedJobTypes.add({
          'id': id ?? 0,
          'name': name ?? '',
        });
      });

      loadedJobTypes
          .sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

      if (loadedJobTypes.isNotEmpty) {
        print(
            "JobListFilters → Normalized jobTypes sample: ${loadedJobTypes.first}");
      }

      final List<Map<String, dynamic>> loadedLocationsData = [];
      final List<String> loadedLocationNames = [];

      for (final item in rawLocations) {
        final mapItem = Map<String, dynamic>.from(item as Map);
        final dynamic rawId =
            mapItem['id'] ?? mapItem['location_id'] ?? mapItem['city_id'];

        final String name = (mapItem['name'] ??
                mapItem['city_name'] ??
                mapItem['location_name'] ??
                mapItem['label'] ??
                '')
            .toString()
            .trim();

        if (name.isNotEmpty) {
          final int? id = rawId == null ? null : int.tryParse(rawId.toString());
          loadedLocationsData.add({'id': id, 'name': name});
          loadedLocationNames.add(name);
        }
      }

      final int? initialJobTypeId = _extractIdFromFilters([
        'jobTypeId',
        'job_type',
        'job_type_id',
        'jobType',
      ]);

      final int? initialCourseId = _extractIdFromFilters([
        'courseId',
        'course',
        'course_id',
      ]);

      final int? initialLocationId = _extractIdFromFilters([
        'locationId',
        'location',
        'location_id',
        'city_id',
      ]);

      setState(() {
        jobTypes = loadedJobTypes;
        courses = rawCourses;
        locationsData = loadedLocationsData;
        locationNames = ['All Locations', ...loadedLocationNames];

        if (kDebugMode) {
          print("JobListFilters → Loaded ${courses.length} courses");
          print("JobListFilters → Loaded ${locationsData.length} locations");
          print("JobListFilters → Loaded ${jobTypes.length} job types");
          if (courses.isNotEmpty) {
            print("JobListFilters → First course: ${courses.first}");
          }
          if (locationsData.isNotEmpty) {
            print("JobListFilters → First location: ${locationsData.first}");
          }
        }

        selectedJobTypeId = initialJobTypeId;
        selectedCourseId = initialCourseId;
        selectedLocationId = initialLocationId;

        selectedJobTypeName = _resolveInitialJobTypeName(
          jobTypes,
          selectedJobTypeId,
          widget.currentFilters['jobTypeName'] as String?,
        );

        selectedCourseName = _resolveInitialCourseName(
          courses,
          selectedCourseId,
          widget.currentFilters['courseName'] as String?,
        );

        selectedLocationName = _resolveInitialLocationName(
          locationsData,
          locationNames,
          selectedLocationId,
          widget.currentFilters['locationName'] as String?,
        );

        print(
            "JobListFilters → Initial selections → jobType: $selectedJobTypeName ($selectedJobTypeId), course: $selectedCourseName ($selectedCourseId), location: $selectedLocationName ($selectedLocationId)");

        isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      print("JobListFilters → ERROR while loading filters: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load filters: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _resolveInitialJobTypeName(
    List<Map<String, dynamic>> jobTypes,
    int? jobTypeId,
    String? storedName,
  ) {
    if (jobTypeId != null) {
      try {
        final match = jobTypes.firstWhere(
          (jt) => jt['id'] == jobTypeId,
        );
        return match['name']?.toString() ?? 'Please Select';
      } catch (_) {}
    }
    if (storedName != null && storedName.trim().isNotEmpty) {
      return storedName;
    }
    // Don't auto-select first item, show placeholder instead
    return 'Please Select';
  }

  String _resolveInitialCourseName(
    List<Map<String, dynamic>> courses,
    int? courseId,
    String? storedName,
  ) {
    if (courseId != null) {
      try {
        final match = courses.firstWhere(
          (c) => c['id'] == courseId,
        );
        return match['course_name']?.toString() ?? 'Select Course';
      } catch (_) {}
    }
    if (storedName != null && storedName.trim().isNotEmpty) {
      return storedName;
    }
    return 'Select Course';
  }

  String _resolveInitialLocationName(
    List<Map<String, dynamic>> locationsData,
    List<String> locationNames,
    int? locationId,
    String? storedName,
  ) {
    if (locationId != null) {
      try {
        final match = locationsData.firstWhere(
          (loc) => loc['id'] == locationId,
        );
        final name = match['name']?.toString();
        if (name != null && name.isNotEmpty) {
          return name;
        }
      } catch (_) {}
    }
    if (storedName != null &&
        storedName.trim().isNotEmpty &&
        locationNames.contains(storedName)) {
      return storedName;
    }
    return 'All Locations';
  }

  void _closeAllDropdowns() {
    // Close all dropdowns when opening one
    (_jobTypeDropdownKey.currentState as dynamic)?.closeDropdown();
    (_courseDropdownKey.currentState as dynamic)?.closeDropdown();
    (_locationDropdownKey.currentState as dynamic)?.closeDropdown();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.92,
      minChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          child: isLoading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF005E6A)),
                      SizedBox(height: 16),
                      Text("Loading filters...",
                          style: TextStyle(fontSize: 15)),
                    ],
                  ),
                )
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            "Failed to load",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _loadAllFilters,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.only(
                          bottom:
                              MediaQuery.of(context).viewInsets.bottom + 40.h,
                        ),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF003840),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Color(0xFF005E6A),
                                  size: 24,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const Divider(
                            thickness: 1.2,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 20),
                          _label("Job Title"),
                          TextField(
                            controller: jobTitleController,
                            onTap: _closeAllDropdowns,
                            decoration: InputDecoration(
                              hintText: "Title",
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 14.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF005E6A),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _label("Company Name"),
                          TextField(
                            controller: companyNameController,
                            onTap: _closeAllDropdowns,
                            decoration: InputDecoration(
                              hintText: "Company",
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 14.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF005E6A),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label("Posted On"),
                                    GestureDetector(
                                      onTap: () => _pickDate(isStart: true),
                                      child: SizedBox(
                                        height: 48.h,
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14.w,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          child: Text(
                                            _startDate == null
                                                ? "Select posted date"
                                                : _formatDate(_startDate),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: _startDate == null
                                                  ? Colors.grey.shade600
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label("End Date"),
                                    GestureDetector(
                                      onTap: () => _pickDate(isStart: false),
                                      child: SizedBox(
                                        height: 48.h,
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14.w,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          child: Text(
                                            _endDate == null
                                                ? "Select end date"
                                                : _formatDate(_endDate),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: _endDate == null
                                                  ? Colors.grey.shade600
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _label("Job Type"),
                          CustomFiledJobFilterNoSearch(
                            jobTypes.map((e) => e['name'] as String).toList(),
                            selectedJobTypeName,
                            (val) {
                              if (val != null) {
                                print(
                                    "JobListFilters → Job Type changed to: $val");
                                final selected = jobTypes.firstWhere(
                                  (jt) => jt['name'] == val,
                                  orElse: () => {'id': null},
                                );
                                setState(() {
                                  selectedJobTypeName = val;
                                  selectedJobTypeId = selected['id'] as int?;
                                });
                                print(
                                    "JobListFilters → Selected jobType: $selectedJobTypeName ($selectedJobTypeId)");
                              }
                            },
                            key: _jobTypeDropdownKey,
                            label: 'Select Job Type',
                            onBeforeOpen: _closeAllDropdowns,
                          ),
                          const SizedBox(height: 20),
                          _label("Course"),
                          CustomFieldJobFilter(
                            [
                              'Select Course',
                              ...courses.map((c) => c['course_name'] as String)
                            ],
                            selectedCourseName,
                            (val) {
                              if (kDebugMode) {
                                print(
                                    "JobListFilters → Course changed to: $val");
                              }
                              if (val == null || val == "Select Course") {
                                setState(() {
                                  selectedCourseName = "Select Course";
                                  selectedCourseId = null;
                                });
                              } else {
                                final selected = courses.firstWhere(
                                  (c) => c['course_name'] == val,
                                  orElse: () => {'id': null},
                                );
                                setState(() {
                                  selectedCourseName = val;
                                  selectedCourseId = selected['id'] as int?;
                                });
                              }
                            },
                            key: _courseDropdownKey,
                            label: "Select Course",
                            forceOpenUpward: true,
                            onBeforeOpen: _closeAllDropdowns,
                          ),
                          const SizedBox(height: 20),
                          _label("Location"),
                          CustomFieldJobFilter(
                            locationNames,
                            selectedLocationName,
                            (val) {
                              print(
                                  "JobListFilters → Location changed to: $val");

                              if (val == null ||
                                  val.trim().isEmpty ||
                                  val == "All Locations") {
                                setState(() {
                                  selectedLocationName = "All Locations";
                                  selectedLocationId = null;
                                });
                                print(
                                    "JobListFilters → Location reset to All Locations");
                                return;
                              }

                              final normalizedVal = val.trim().toLowerCase();
                              final found = locationsData.firstWhere(
                                (loc) {
                                  final ln = loc['name']
                                          ?.toString()
                                          .trim()
                                          .toLowerCase() ??
                                      '';
                                  return ln == normalizedVal;
                                },
                                orElse: () => {'id': null, 'name': val},
                              );

                              int? resolvedId;
                              final rawId = found['id'];
                              if (rawId is int) {
                                resolvedId = rawId;
                              } else if (rawId is String) {
                                resolvedId = int.tryParse(rawId);
                              } else {
                                resolvedId = null;
                              }

                              setState(() {
                                selectedLocationName = val.trim();
                                selectedLocationId = resolvedId;
                              });

                              print(
                                  "JobListFilters → Selected location: $selectedLocationName (raw id: ${found['id']}, resolvedId: $resolvedId)");
                            },
                            key: _locationDropdownKey,
                            label: "Select Location",
                            forceOpenUpward: true,
                            onBeforeOpen: _closeAllDropdowns,
                          ),
                          const SizedBox(height: 50),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                final int? finalLocationId =
                                    selectedLocationId ??
                                        _findLocationIdByName(
                                            selectedLocationName);

                                final result = <String, dynamic>{
                                  'jobTitle': jobTitleController.text.trim(),
                                    'company_name':
                                      companyNameController.text.trim(),
                                  'posted_on': _formatDate(_startDate),
                                  'start_date': _formatDate(_startDate),
                                  'end_date': _formatDate(_endDate),
                                  'jobTypeId': selectedJobTypeId,
                                  'courseId': selectedCourseId,
                                  'locationId': finalLocationId,
                                  'jobTypeName': selectedJobTypeName,
                                  'courseName':
                                      selectedCourseName == "Select Course"
                                          ? ""
                                          : selectedCourseName,
                                  'locationName':
                                      selectedLocationName == "All Locations"
                                          ? ""
                                          : selectedLocationName,
                                    'job_type': selectedJobTypeId,
                                    'course': selectedCourseId,
                                    'location': finalLocationId,
                                };

                                print(
                                    "JobListFilters → Applied Filters → $result");
                                Navigator.pop(context, result);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005E6A),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 60.w,
                                  vertical: 16.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                              ),
                              child: Text(
                                "Show Results",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.5.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF003840),
        ),
      ),
    );
  }
}
