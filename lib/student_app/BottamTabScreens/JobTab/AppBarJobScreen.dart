import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../AllFilters/JobFilters/JobListFilters.dart';
import '../../Pages/Notification_icon_Badge.dart';
import '../../Utilities/JobLocationsApi.dart';
import '../../blocpage/jobFilterBloc/jobFilter_event.dart';
import '../../blocpage/jobFilterBloc/jobFilter_logic.dart';
import '../../blocpage/jobFilterBloc/jobFilter_state.dart';

class Appbarjobscreen extends StatefulWidget implements PreferredSizeWidget {
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onClear;

  final Map<String, dynamic> currentFilters;

  final ValueChanged<Map<String, dynamic>>? onFiltersApplied;

  final bool hasActiveFilters;

  final VoidCallback? onClearFilters;

  const Appbarjobscreen({
    super.key,
    this.onQueryChanged,
    this.onClear,
    this.currentFilters = const {},
    this.onFiltersApplied,
    this.hasActiveFilters = false,
    this.onClearFilters,
  });

  @override
  Size get preferredSize => Size.fromHeight(64.h);

  @override
  State<Appbarjobscreen> createState() => _AppbarjobscreenState();
}

class _AppbarjobscreenState extends State<Appbarjobscreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        widget.onQueryChanged?.call(_controller.text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JobFilterBloc, JobFilterState>(
      listener: (context, state) async {
        if (state is JobFilterSheetVisible) {
          print(
              "Appbarjobscreen → JobFilterSheetVisible. Opening bottom sheet with currentFilters=${widget.currentFilters}");

          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => Joblistfilters(
              currentFilters: widget.currentFilters,
            ),
          );

          print("Appbarjobscreen → Bottom sheet closed. Result: $result");

          if (result == null) return;

          int? _resolveId(dynamic v) {
            if (v == null) return null;
            if (v is int) return v;
            return int.tryParse(v.toString());
          }

          String _normalizeName(dynamic v) {
            return v?.toString().trim() ?? '';
          }

          int? jobTypeId = _resolveId(
              result['job_type'] ?? result['jobTypeId'] ?? result['jobType']);
          int? courseId = _resolveId(
              result['course'] ?? result['courseId'] ?? result['courseId']);
          int? locationId = _resolveId(result['location'] ??
              result['locationId'] ??
              result['locationId']);

          final String locationName = _normalizeName(result['locationName'] ??
              result['location'] ??
              result['location_name']);

          if (locationId == null && locationName.isNotEmpty) {
            try {
              final rawLocations = await JobLocationsApi.fetchLocationsRaw();
              final List<Map<String, dynamic>> locs = [];
              for (final item in rawLocations) {
                final mapItem = Map<String, dynamic>.from(item as Map);
                final dynamic rawId = mapItem['id'] ??
                    mapItem['location_id'] ??
                    mapItem['city_id'];
                final name = (mapItem['name'] ??
                        mapItem['city_name'] ??
                        mapItem['location_name'] ??
                        mapItem['label'] ??
                        '')
                    .toString()
                    .trim();
                if (name.isNotEmpty) {
                  final int? id =
                      rawId == null ? null : int.tryParse(rawId.toString());
                  locs.add({'id': id, 'name': name});
                }
              }

              final normalized = locationName.toLowerCase();
              final found = locs.firstWhere(
                  (loc) =>
                      (loc['name']?.toString().trim().toLowerCase() ?? '') ==
                      normalized,
                  orElse: () => {'id': null});
              final raw = found['id'];
              if (raw is int) {
                locationId = raw;
              } else if (raw is String) {
                locationId = int.tryParse(raw);
              }

              print(
                  "Appbarjobscreen → Resolved locationName='$locationName' -> id=$locationId (via JobLocationsApi)");
            } catch (e) {
              print(
                  "Appbarjobscreen → Failed to resolve location name -> id: $e");
            }
          }

          // Build a normalized result map that contains both frontend and backend keys.
          final normalizedResult = <String, dynamic>{
            // original raw values (best effort)
            ...result,

            // canonical frontend keys
            'jobTypeId': jobTypeId,
            'courseId': courseId,
            'locationId': locationId,
            'jobTypeName': _normalizeName(result['jobTypeName']),
            'courseName': _normalizeName(result['courseName']),
            'locationName': locationName,

            // canonical backend keys expected by API
            'job_type': jobTypeId,
            'course': courseId,
            'location': locationId,
          };

          // Dispatch to bloc and notify parent
          context.read<JobFilterBloc>().add(ApplyJobFilters(normalizedResult));

          if (widget.onFiltersApplied != null) {
            print(
                "Appbarjobscreen → Calling onFiltersApplied with: $normalizedResult");
            widget.onFiltersApplied!(normalizedResult);
          } else {
            print(
                "Appbarjobscreen → WARNING: onFiltersApplied is null. JobScreen will NOT update.");
          }
        }
      },
      child: SafeArea(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(17.w, 17.h, 17.w, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.4),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide:
                            const BorderSide(color: Color(0xFF005E6A)),
                      ),
                      prefixIcon: Icon(Icons.search, size: 18.sp),
                      hintText: 'Search job title',
                      hintStyle:
                          TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clear,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  print(
                      "Appbarjobscreen → Filter icon tapped. Dispatching ShowJobFilterSheet");
                  context.read<JobFilterBloc>().add(ShowJobFilterSheet());
                },
                child: Icon(Icons.filter_list, size: 26.sp),
              ),
              if (widget.hasActiveFilters) ...[
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: () {
                    print("Appbarjobscreen → Clear filters tapped");
                    widget.onClearFilters?.call();
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.close, size: 26.sp, color: Colors.red),
                        // SizedBox(width: 2.w),
                        // Text(
                        //   'Clear',
                        //   style: TextStyle(
                        //     fontSize: 16.sp,
                        //     color: Colors.red,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
              const NotificationBell(),
            ],
          ),
        ),
      ),
    );
  }
}
