import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:skillsconnect/utils/session_guard.dart';
import '../../../Pages/Notification_icon_Badge.dart';
import '../../../Utilities/ApiConstants.dart';
import '../../../Utilities/JobDetail_Api.dart';
import '../../../Utilities/BookMark_add_api.dart';
import 'WebviewScreen.dart';

class JobDetailPage2 extends StatefulWidget {
  final String jobToken;
  final int moduleId;
  final String? slug;
  final bool isAlreadyApplied;

  const JobDetailPage2({
    super.key,
    required this.jobToken,
    required this.moduleId,
    this.slug,
    this.isAlreadyApplied = false,
  });

  @override
  State<JobDetailPage2> createState() => _JobDetailPage2State();
}

class _JobDetailPage2State extends State<JobDetailPage2> {
  Map<String, dynamic>? jobDetail;
  bool isLoading = true;
  String? error;
  bool isLocationExpanded = false;
  bool isBookmarked = false;
  bool _snackBarShown = false;
  int? _moduleIdEffective;
  bool _fetching = false;
  bool _bookmarkChanged = false;
  bool _initialIsBookmarkedSet = false;
  bool _initialIsBookmarked = false;
  bool _bookmarkUpdating = false;

  @override
  void initState() {
    super.initState();
    print(
        '[JD.initState] jobToken=${widget.jobToken}, moduleId=${widget.moduleId}');
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant JobDetailPage2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobToken != widget.jobToken ||
        oldWidget.moduleId != widget.moduleId) {
      print('[JD.didUpdateWidget] detected prop change → refresh');
      _moduleIdEffective = null;
      isBookmarked = false;
      _snackBarShown = false;
      jobDetail = null;
      error = null;
      isLocationExpanded = false;
      _initialIsBookmarkedSet = false;
      _initialIsBookmarked = false;
      _bookmarkChanged = false;
      _bootstrap();
      setState(() {});
    }
  }

  final TextStyle headingStyle = TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF003840),
  );

  final TextStyle subHeadingStyle = TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF003840),
  );

  final TextStyle infoStyle = TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF003840),
  );

  final TextStyle infoLightStyle = TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: Colors.grey[700],
  );

  Future<void> _bootstrap() async {
    print('[JD._bootstrap] start');
    await _fetchJobDetail();
  }

  void _showSnackBarOnceBookmark(BuildContext context, String message,
      {int cooldownMilliseconds = 500}) {
    print('[DEBUG] _showSnackBarOnceBookmark called with message: "$message"');
    print('[DEBUG] _showSnackBarOnceBookmark _snackBarShown: $_snackBarShown');

    if (_snackBarShown) {
      print('[DEBUG] _showSnackBarOnceBookmark blocked - snackbar already shown');
      return;
    }

    _snackBarShown = true;
    print('[DEBUG] _showSnackBarOnceBookmark showing snackbar');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 12.4.sp)),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: cooldownMilliseconds),
      ),
    );
    Future.delayed(Duration(seconds: 1), () {
      print('[DEBUG] _showSnackBarOnceBookmark resetting _snackBarShown to false');
      _snackBarShown = false;
    });
  }

  void _showSnackBarOnce(BuildContext context, String message,
      {int cooldownSeconds = 3}) {
    if (_snackBarShown) return;
    _snackBarShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 12.4.sp)),
        backgroundColor: Colors.green,
        duration: Duration(seconds: cooldownSeconds),
      ),
    );
    Future.delayed(Duration(seconds: cooldownSeconds), () {
      _snackBarShown = false;
    });
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == '1' || s == 'true' || s == 'yes';
    }
    return false;
  }

  Future<void> _fetchJobDetail() async {
    if (_fetching) {
      print('[JD._fetchJobDetail] already fetching → skip');
      return;
    }
    _fetching = true;
    print(
        '[JD._fetchJobDetail] start with jobToken=${widget.jobToken}, moduleId=${widget.moduleId}');
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      if (widget.jobToken.isEmpty) {
        print('[JD._fetchJobDetail][ERROR] jobToken is empty');
        throw Exception('Job token is missing');
      }

      print('[JD._fetchJobDetail] calling JobDetailApi.fetchJobDetail...');
      final data = await JobDetailApi.fetchJobDetail(
          token: widget.jobToken, moduleId: widget.moduleId);
      print('[JD._fetchJobDetail] raw response: $data');
      print('[JD._fetchJobDetail] response keys: ${data.keys.toList()}');

      final int effectiveId = widget.moduleId != 0
          ? widget.moduleId
          : (data['job_id'] as int?) ?? (data['id'] as int?) ?? 0;
      _moduleIdEffective = effectiveId;
      print('[JD._fetchJobDetail] effective moduleId=$_moduleIdEffective');

      final resolvedIsBookmarked =
          (data['bookmarkStatus']?.toString().toLowerCase() == "bookmarked");
      print('[JD._fetchJobDetail] resolvedIsBookmarked=$resolvedIsBookmarked');

      if (!_initialIsBookmarkedSet) {
        _initialIsBookmarked = resolvedIsBookmarked;
        _initialIsBookmarkedSet = true;
        print(
            '[JD._fetchJobDetail] captured initial bookmark=$_initialIsBookmarked');
      }

      if (!mounted) return;

      final Map<String, dynamic> normalized = Map<String, dynamic>.from(data);

      final postedRaw =
          data['posted_on'] ?? data['postedOn'] ?? data['created_on'] ?? '';
      final endDateRaw =
          data['end_date'] ?? data['endDate'] ?? data['expiry'] ?? '';

      final locations = data['job_location_detail'] ??
          data['locations'] ??
          normalized['locations'] ??
          [];

      final salaryCandidates = <dynamic>[
        data['salary'],
        data['salary_raw'],
        data['cost_to_company'],
        data['costToCompany'],
        data['cost_to_company_raw'],
        normalized['salary'],
        normalized['salary_raw']
      ];
      
      String resolvedSalaryRaw = '';
      for (final cand in salaryCandidates) {
        if (cand == null) continue;
        final s = cand.toString().trim();
        if (s.isNotEmpty &&
            s.toLowerCase() != '0' &&
            s.toLowerCase() != '0.0') {
          resolvedSalaryRaw = s;
          break;
        }
      }

      final ctcBreakDown = data['ctc_break_down'] ?? data['ctcBreakDown'] ?? '';
      final fixedPay = data['fixed_pay'] ?? data['fixedPay'] ?? '';
      final variablePay = data['variable_pay'] ?? data['variablePay'] ?? '';
      final otherIncentives =
          data['other_incentives'] ?? data['otherIncentives'] ?? '';

      final probationDuration = data['probation_duration'] ??
          data['probationDuration'] ??
          data['probation_period'] ??
          '';
      final joiningDate = data['joining_date'] ?? data['joiningDate'] ?? '';

      int openings = 0;
      if (data['openings'] != null) {
        try {
          openings = int.tryParse(data['openings'].toString()) ?? openings;
        } catch (_) {}
      } else if (data['job_location_detail'] is List &&
          (data['job_location_detail'] as List).isNotEmpty) {
        try {
          final first = (data['job_location_detail'] as List).first;
          openings =
              int.tryParse(first['opening']?.toString() ?? '') ?? openings;
        } catch (_) {}
      }

      final responsibilities = (data['responsibilities'] as List<dynamic>?)
              ?.cast<String>() ??
          (normalized['responsibilities'] as List<dynamic>?)?.cast<String>() ??
          [];
      final requirements =
          (data['requirements'] as List<dynamic>?)?.cast<String>() ??
              (normalized['requirements'] as List<dynamic>?)?.cast<String>() ??
              [];
      final niceToHave =
          (data['niceToHave'] as List<dynamic>?)?.cast<String>() ??
              (normalized['niceToHave'] as List<dynamic>?)?.cast<String>() ??
              [];

      final applicationProcess =
          data['process'] ?? data['application_process'] ?? [];

      final appliedVal = data['applied'] ?? normalized['applied'];
      final appliedBool = _toBool(appliedVal);

      if (kDebugMode) {
        print(
            '[JD._fetchJobDetail] resolved applied=$appliedVal -> $appliedBool');
        print(
            '[JD._fetchJobDetail] resolvedSalaryRaw="$resolvedSalaryRaw" (candidates: $salaryCandidates)');
      }

      setState(() {
        final rawCourses = data['job_course_detail'] ??
            data['job_course'] ??
            normalized['job_course_detail'] ??
            [];

        final List<Map<String, String>> qualifications = [];
        try {
          if (rawCourses is List) {
            for (final it in rawCourses) {
              if (it is Map) {
                final course = (it['course_name'] ??
                        it['course_name'] ??
                        it['course'] ??
                        '')
                    .toString()
                    .trim();
                final spec = (it['specialization_name'] ??
                        it['specialization_name'] ??
                        it['specialization'] ??
                        '')
                    .toString()
                    .trim();
                if (course.isNotEmpty || spec.isNotEmpty) {
                  qualifications.add({
                    'course_name': course,
                    'specialization_name': spec,
                  });
                }
              }
            }
          }
        } catch (_) {}

        jobDetail = {
          'id': data['id'] ?? 0,
          'job_id': data['job_id'] ?? data['id'] ?? 0,
          'title': data['title'] ?? 'Untitled',
          'company':
              data['company'] ?? data['company_name'] ?? 'Unknown Company',
          'location': data['location'] ?? '',
          'logoUrl': data['logoUrl'] ?? data['company_logo'] ?? '',
          'slug': data['slug'] ??
              data['titleSlug'] ??
              data['job_slug'] ??
              normalized['job_slug'] ??
              '',
          'job_invitation_token': data['job_invitation_token'] ??
              normalized['job_invitation_token'] ??
              '',
          'applied': appliedBool,
          'responsibilities': responsibilities,
          'terms': (data['terms'] as List<dynamic>?)?.cast<String>() ?? [],
          'requirements': requirements,
          'niceToHave': niceToHave,
          'aboutCompany': (data['aboutCompany'] as List<dynamic>?)
                  ?.cast<String>() ??
              (normalized['aboutCompany'] as List<dynamic>?)?.cast<String>() ??
              [],
          'tags': (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
          'skills': data['skills'] ?? [],
          'posted_on_raw': postedRaw ?? '',
          'end_date_raw': endDateRaw ?? '',
          'locations': locations,
          'job_course_detail': rawCourses,
          'qualification': qualifications,
          'ctc_break_down': ctcBreakDown?.toString() ?? '',
          'fixed_pay': fixedPay?.toString() ?? '',
          'variable_pay': variablePay?.toString() ?? '',
          'other_incentives': otherIncentives?.toString() ?? '',
          'probation_duration': probationDuration?.toString() ?? '',
          'joining_date': joiningDate?.toString() ?? '',
          'openings': openings,
          'salary_raw': resolvedSalaryRaw,
          'application_process': applicationProcess,
          'postTime': data['postTime'] ?? '',
          'expiry': data['expiry'] ?? '',
          'bookmarkStatus': data['bookmarkStatus'] ?? '',
          'job_type': data['job_type'] ?? '',
        };
        isBookmarked = resolvedIsBookmarked;
        isLoading = false;
      });

      print('[JD._fetchJobDetail] setState done. jobDetail=$jobDetail');
    } catch (e, st) {
      if (!mounted) return;
      print('[JD._fetchJobDetail][EXCEPTION] $e');
      print('[JD._fetchJobDetail][STACKTRACE] $st');
      setState(() {
        error = 'Failed to load job details: $e';
        isLoading = false;
      });
    } finally {
      _fetching = false;
      print('[JD._fetchJobDetail] END');
    }
  }

  Future<void> _toggleBookmark() async {
    print('[DEBUG] _toggleBookmark() STARTED');

    if (_moduleIdEffective == null || _moduleIdEffective == 0) {
      print('[DEBUG] _toggleBookmark() ERROR: invalid moduleId = $_moduleIdEffective');
      _showSnackBarOnceBookmark(context, "Unable to bookmark: invalid job id");
      return;
    }

    print('[DEBUG] _toggleBookmark() moduleId valid: $_moduleIdEffective');

    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    print('[DEBUG] _toggleBookmark() authToken length: ${authToken.length}');
    print('[DEBUG] _toggleBookmark() connectSid length: ${connectSid.length} (optional)');

    if (authToken.isEmpty) {
      print('[DEBUG] _toggleBookmark() ERROR: authToken is empty');
      _showSnackBarOnceBookmark(context, "Error, Please login again");
      return;
    }

    print('[DEBUG] _toggleBookmark() authToken valid, proceeding (connectSid optional)');

    if (_bookmarkUpdating) {
      print('[DEBUG] _toggleBookmark() already updating, returning');
      return;
    }

    print('[DEBUG] _toggleBookmark() not updating, proceeding');

    print(
        '[JD._toggleBookmark] tap. current=$isBookmarked, moduleId=$_moduleIdEffective');

    final previous = isBookmarked;
    setState(() {
      isBookmarked = !isBookmarked;
     });

    print('[DEBUG] _toggleBookmark() UI updated - previous: $previous, new: $isBookmarked, updating: $_bookmarkUpdating');

    try {
      print('[DEBUG] _toggleBookmark() calling BookmarkApi.toggleBookmark');
      final result = await BookmarkApi.toggleBookmark(
        module: 'Job',
        moduleId: _moduleIdEffective!,
        authToken: authToken,
        connectSid: connectSid,
        currentlyBookmarked: previous,
      );

      print('[DEBUG] _toggleBookmark() BookmarkApi returned: ${result != null ? 'success' : 'null'}');

      if (result != null) {
        if (!mounted) {
          print('[DEBUG] _toggleBookmark() widget not mounted, returning');
          return;
        }
        setState(() {
          isBookmarked = result.isBookmarked;
          _bookmarkUpdating = false;
        });

        if (!_initialIsBookmarkedSet) {
          _initialIsBookmarked = !isBookmarked;
          _initialIsBookmarkedSet = true;
        }

        _bookmarkChanged = (_initialIsBookmarked != isBookmarked);
        print(
            '[JD._toggleBookmark] bookmarkChanged=$_bookmarkChanged (initial=$_initialIsBookmarked, current=$isBookmarked)');

        _showSnackBarOnceBookmark(
          context,
          result.isBookmarked
              ? "Job bookmarked successfully"
              : "Bookmark removed",
        );
      } else {
        print('[DEBUG] _toggleBookmark() result is null, reverting UI');
        if (!mounted) return;
        setState(() {
          isBookmarked = previous;
          _bookmarkUpdating = false;
        });
        // Don't show error if session guard is handling logout
        if (!SessionGuard.isLoggingOut) {
          print('[DEBUG] _toggleBookmark() showing error message');
          _showSnackBarOnceBookmark(context, "Failed to toggle bookmark");
        } else {
          print('[DEBUG] _toggleBookmark() session guard logging out, not showing error');
        }
      }
    } catch (e, st) {
      print('[DEBUG] _toggleBookmark() EXCEPTION: $e');
      print('[DEBUG] _toggleBookmark() STACKTRACE: $st');
      if (!mounted) return;
      setState(() {
        isBookmarked = previous;
        _bookmarkUpdating = false;
      });
      // Don't show error if session guard is handling logout
      if (!SessionGuard.isLoggingOut) {
        print('[DEBUG] _toggleBookmark() showing error message from catch');
        _showSnackBarOnceBookmark(context, "Failed to toggle bookmark");
      } else {
        print('[DEBUG] _toggleBookmark() session guard logging out in catch, not showing error');
      }
    }

    print('[DEBUG] _toggleBookmark() COMPLETED');
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_bookmarkChanged);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
            backgroundColor: Colors.white,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(55.h),
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: AppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                  titleSpacing: 0,
                  title: Text(
                    "Job Detail",
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: const Color(0xFF003840),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  leading: Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1.w),
                      ),
                      child: Center(
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            size: 18.sp,
                            color: const Color(0xFF003840),
                          ),
                          onPressed: () =>
                              Navigator.pop(context, _bookmarkChanged),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    // Padding(
                    //   padding: EdgeInsets.only(right: 8.w),
                    //   child: Container(
                    //     width: 40.w,
                    //     height: 40.w,
                    //     decoration: BoxDecoration(
                    //       shape: BoxShape.circle,
                    //       border:
                    //           Border.all(color: Colors.grey.shade300, width: 1.w),
                    //     ),
                    //     child: Center(
                    //       child: IconButton(
                    //         padding: EdgeInsets.zero,
                    //         constraints: const BoxConstraints(),
                    //         icon: Icon(
                    //           Icons.share,
                    //           size: 18.sp,
                    //           color: const Color(0xFF003840),
                    //         ),
                    //         onPressed: () async {
                    //           try {
                    //             final prefs =
                    //                 await SharedPreferences.getInstance();
                    //             final jwt = prefs.getString('authToken') ?? '';
                    //
                    //             if (jwt.isEmpty) {
                    //               _showSnackBarOnce(
                    //                   context, 'Please login to share');
                    //               return;
                    //             }
                    //
                    //             final String slug =
                    //                 (jobDetail?['slug'] as String?)
                    //                             ?.trim()
                    //                             .isNotEmpty ==
                    //                         true
                    //                     ? jobDetail!['slug'].toString().trim()
                    //                     : (widget.slug?.trim() ?? '');
                    //
                    //             final String invitationToken =
                    //                 (jobDetail?['job_invitation_token']
                    //                                 as String?)
                    //                             ?.trim()
                    //                             .isNotEmpty ==
                    //                         true
                    //                     ? jobDetail!['job_invitation_token']
                    //                         .toString()
                    //                         .trim()
                    //                     : widget.jobToken;
                    //
                    //             if (slug.isEmpty || invitationToken.isEmpty) {
                    //               _showSnackBarOnce(
                    //                   context, 'Unable to share job link');
                    //               return;
                    //             }
                    //             final String shareUrl =
                    //                 'https://api.skillsconnect.in/job-profile/$slug/$invitationToken';
                    //             print("🔗 Sharing link → $shareUrl");
                    //             await Share.share(
                    //               'Checkout this job opportunity:\n$shareUrl',
                    //               subject: 'Job Opportunity',
                    //             );
                    //           } catch (e) {
                    //             _showSnackBarOnce(context,
                    //                 'Something went wrong while sharing');
                    //           }
                    //         },
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    SizedBox(width: 10.w),
                    NotificationBell(),
                  ],
                ),
              ),
            ),
            body: isLoading
                ? Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: _buildShimmer(),
                  )
                : error != null
                    ? Center(
                        child: Text(
                            error!,
                            style: const TextStyle(color: Colors.red)))
                    : SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(jobDetail),
                              _jobSummaryExtras(jobDetail),
                              _sectionTitle(
                                  'Responsibilities of the Candidate:'),
                              _bulletSection(
                                  jobDetail?['responsibilities'] ?? []),
                              _sectionTitle('Requirements:'),
                              _bulletSection(jobDetail?['requirements'] ?? []),
                              _sectionTitle('Nice to Have:'),
                              _bulletSection(jobDetail?['niceToHave'] ?? []),
                              _sectionTitle('About Company'),
                              _bulletSection(jobDetail?['aboutCompany'] ?? []),
                              _sectionTitle('Application Process'),
                              _applicationProcessScroll(
                                  jobDetail?['application_process'] ?? []),
                            ],
                          ),
                        ),
                      ),
            bottomNavigationBar: SafeArea(
              minimum: EdgeInsets.only(bottom: 8.h),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100.w,
                      height: 45.h,
                      child: Builder(
                        builder: (_) {
                          final bool applied = widget.isAlreadyApplied ||
                              (jobDetail?['applied'] == true);
                          return ElevatedButton(
                            onPressed: applied
                                ? null
                                : () async {
                                    try {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final jwt =
                                          prefs.getString('authToken') ?? '';
                                      if (jwt.isEmpty) {
                                        _showSnackBarOnce(
                                            context, 'Please login to apply');
                                        return;
                                      }

                                      final String slug =
                                          (jobDetail?['slug'] as String?)
                                                      ?.trim()
                                                      .isNotEmpty ==
                                                  true
                                              ? (jobDetail!['slug'] as String)
                                                  .trim()
                                              : widget.slug?.trim() ?? '';

                                      final String invitationToken =
                                          (jobDetail?['job_invitation_token']
                                                          as String?)
                                                      ?.trim()
                                                      .isNotEmpty ==
                                                  true
                                              ? (jobDetail![
                                                          'job_invitation_token']
                                                      as String)
                                                  .trim()
                                              : widget.jobToken;

                                      if (slug.isEmpty ||
                                          invitationToken.isEmpty) {
                                        _showSnackBarOnce(context,
                                            'Unable to open apply page (missing slug or token)');
                                        return;
                                      }

                                      final String applyUrl =
                                          '${ApiConstantsStu.jobApplyUrlLink}$slug/$invitationToken?apply=true&token=$jwt';

                                      if (!mounted) return;
                                      print(
                                          "🔗 Navigating to Apply WebView → $applyUrl");

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AppWebViewScreen(
                                            title: 'Apply',
                                            url: applyUrl,
                                          ),
                                        ),
                                      );
                                    } catch (_) {
                                      _showSnackBarOnce(context,
                                          'Something went wrong while opening apply page');
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: applied
                                  ? Colors.grey.shade400
                                  : const Color(0xFF005E6A),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              applied ? "Applied" : "Apply Now",
                              style: TextStyle(
                                  fontSize: 14.sp, fontWeight: FontWeight.w700
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    Container(
                      width: 45.w,
                      height: 45.w,
                      margin: EdgeInsets.only(right: 12.w),
                      decoration: BoxDecoration(
                        color: Color(0xFF005E6A),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1.w),
                      ),
                      child: Center(
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.share,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final jwt = prefs.getString('authToken') ?? '';

                              if (jwt.isEmpty) {
                                _showSnackBarOnce(
                                    context, 'Please login to share'
                                );
                                return;
                              }

                              final String slug =
                                  (jobDetail?['slug'] as String?)
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? jobDetail!['slug'].toString().trim()
                                      : (widget.slug?.trim() ?? '');

                              final String invitationToken =
                                  (jobDetail?['job_invitation_token']
                                                  as String?)
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? jobDetail!['job_invitation_token']
                                          .toString()
                                          .trim()
                                      : widget.jobToken;

                              if (slug.isEmpty || invitationToken.isEmpty) {
                                _showSnackBarOnce(
                                    context, 'Unable to share job link');
                                return;
                              }

                              final String shareUrl =
                                  '${ApiConstantsStu.jobApplyUrlLink}$slug/$invitationToken';

                              print("🔗 Sharing link → $shareUrl");

                              await Share.share(
                                'Checkout this job opportunity:\n$shareUrl',
                                subject: 'Job Opportunity',
                              );
                            } catch (e) {
                              _showSnackBarOnce(context,
                                  'Something went wrong while sharing');
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100.withOpacity(0.6),
      direction: ShimmerDirection.ltr,
      period: const Duration(seconds: 2),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 52.w, height: 52.h, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 20.h,
                          width: double.infinity,
                          color: Colors.white),
                      SizedBox(height: 8.h),
                      Container(
                          height: 16.h, width: 200.w, color: Colors.white),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              height: 28.h, width: 90.w, color: Colors.white),
                          Container(
                              width: 28.w, height: 28.w, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            Wrap(
              spacing: 10.w,
              runSpacing: 8.h,
              children: List.generate(
                  5,
                  (_) => Container(
                        height: 30.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      )),
            ),

            SizedBox(height: 20.h),

            Row(
              children: [
                Expanded(
                    child: Container(
                        height: 70.h,
                        color: Colors.white,
                        margin: EdgeInsets.only(right: 6.w))),
                Expanded(child: Container(height: 70.h, color: Colors.white)),
              ],
            ),

            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                    child: Container(
                        height: 74.h,
                        color: Colors.white,
                        margin: EdgeInsets.only(right: 6.w))),
                Expanded(child: Container(height: 74.h, color: Colors.white)),
              ],
            ),

            SizedBox(height: 16.h),

            Container(
                height: 60.h, width: double.infinity, color: Colors.white),

            SizedBox(height: 16.h),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                  color: const Color(0xFFEBF6F7),
                  borderRadius: BorderRadius.circular(10.r)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18.h, width: 140.w, color: Colors.white),
                  SizedBox(height: 12.h),
                  Container(
                      height: 14.h,
                      width: double.infinity,
                      color: Colors.white),
                  SizedBox(height: 8.h),
                  Container(
                      height: 14.h,
                      width: double.infinity,
                      color: Colors.white),
                  SizedBox(height: 8.h),
                  Container(height: 14.h, width: 200.w, color: Colors.white),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                  color: const Color(0xFFEBF6F7),
                  borderRadius: BorderRadius.circular(10.r)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18.h, width: 120.w, color: Colors.white),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 8.h,
                    children: List.generate(
                        4,
                        (_) => Container(
                              height: 32.h,
                              width: 140.w,
                              color: Colors.white,
                            )),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Location Block
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                  color: const Color(0xFFEBF6F7),
                  borderRadius: BorderRadius.circular(10.r)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18.h, width: 80.w, color: Colors.white),
                  SizedBox(height: 12.h),
                  Container(
                      height: 16.h,
                      width: double.infinity,
                      color: Colors.white),
                  SizedBox(height: 8.h),
                  Container(
                      height: 16.h,
                      width: double.infinity,
                      color: Colors.white),
                  SizedBox(height: 8.h),
                  Container(height: 16.h, width: 200.w, color: Colors.white),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Section blocks (Responsibilities, Requirements, etc.)
            ...List.generate(
                4,
                (_) => Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEBF6F7),
                            borderRadius: BorderRadius.circular(10.r)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 18.h,
                                width: 180.w,
                                color: Colors.white),
                            SizedBox(height: 12.h),
                            Container(
                                height: 14.h,
                                width: double.infinity,
                                color: Colors.white),
                            SizedBox(height: 8.h),
                            Container(
                                height: 14.h,
                                width: double.infinity,
                                color: Colors.white),
                            SizedBox(height: 8.h),
                            Container(
                                height: 14.h,
                                width: 280.w,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    )),

            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? job) {
    final company = job?['company'] ?? 'Company';

    final titleText = Text(
      job?['title'] ?? 'Untitled',
      style: headingStyle.copyWith(
        fontSize: 18.sp,
        color: const Color(0xFF005E6A),
        height: 1.05,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: job?['logoUrl'] != null &&
                          (job?['logoUrl'] as String).isNotEmpty
                      ? Image.network(
                          job!['logoUrl'],
                          height: 45.h,
                          width: 45.w,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/google.png',
                            height: 45.h,
                            width: 45.w,
                          ),
                        )
                      : Image.asset('assets/google.png',
                          height: 45.h, width: 45.w),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: titleText),
                          GestureDetector(
                            onTap: (isLoading || _bookmarkUpdating)
                                ? null
                                : _toggleBookmark,
                            child: SizedBox(
                              width: 28.w,
                              height: 28.w,
                              child: _bookmarkUpdating
                                  ? Padding(
                                      padding: EdgeInsets.all(4.w),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.w,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                const Color(0xFF005E6A)),
                                      ),
                                    )
                                  : Icon(
                                      isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_add_outlined,
                                      size: 25.w,
                                      color: const Color(0xFF005E6A),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        company,
                        style: infoStyle.copyWith(
                          fontSize: 14.sp,
                          height: 1.2,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: _renderTags(job),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget jobTypeTag(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      // decoration: BoxDecoration(
      //   color: const Color(0xFF005E6A),
      //   borderRadius: BorderRadius.circular(16.r),
      // ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(0xFF005E6A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<Widget> _renderTags(Map<String, dynamic>? job) {
    if (job == null) return [];

    final String jobType = job['job_type']?.toString().trim() ?? '';
    final List<dynamic> skills = (job['skills'] ?? []) as List<dynamic>;

    List<Widget> widgets = [];

    if (jobType.isNotEmpty) {
      widgets.add(jobTypeTag(jobType));
    }

    for (final s in skills) {
      final skill = s.toString().trim();
      if (skill.isNotEmpty) {
        widgets.add(_Tag(label: skill));
      }
    }

    return widgets;
  }

  Widget _sectionTitle(String title) => Padding(
        padding: EdgeInsets.only(top: 12.h, bottom: 6.h),
        child: Text(
          title,
          style: headingStyle,
        ),
      );

  Widget _bulletSection(List<String> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBF6F7),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
      margin: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((text) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• ",
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF003840),
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF003840),
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _Tag({required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F9),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF005E6A),
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _jobSummaryExtras(Map<String, dynamic>? job) {
    if (job == null) return const SizedBox.shrink();

    String formatHumanDate(String raw, {String fallback = 'N/A'}) {
      if (raw.toString().trim().isEmpty) return fallback;
      try {
        final s = raw.toString().trim();
        DateTime parsed;
        if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(s)) {
          final parts = s.split('-');
          parsed = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } else {
          parsed = DateTime.parse(s);
          parsed = DateTime(parsed.year, parsed.month, parsed.day);
        }
        return DateFormat('d MMMM yyyy').format(parsed);
      } catch (e) {
        if ((job['postTime'] ?? '').toString().isNotEmpty &&
            raw == job['posted_on_raw']) {
          return job['postTime']?.toString() ?? fallback;
        }
        if ((job['expiry'] ?? '').toString().isNotEmpty &&
            raw == job['end_date_raw']) {
          final alt =
              job['end_date_raw']?.toString() ?? job['expiry']?.toString();
          if (alt != null && alt.isNotEmpty) {
            try {
              final p = DateTime.parse(alt);
              final norm = DateTime(p.year, p.month, p.day);
              return DateFormat('d MMMM yyyy').format(norm);
            } catch (_) {}
          }
          return job['expiry']?.toString() ?? fallback;
        }
        if ((raw ?? '').toString().isNotEmpty) return raw.toString();
        return fallback;
      }
    }

    final postedHuman =
        formatHumanDate(job['posted_on_raw'] ?? job['postTime'] ?? '');
    final deadlineHuman =
        formatHumanDate(job['end_date_raw'] ?? job['expiry'] ?? '');

    final ctcRaw =
        (job['salary_raw'] ?? job['salary'] ?? job['cost_to_company'] ?? '')
            .toString();
    final fixedPayRaw = job['fixed_pay']?.toString() ?? '';
    final variablePayRaw = job['variable_pay']?.toString() ?? '';
    final otherIncentivesRaw = job['other_incentives']?.toString() ?? '';
    final probationDuration = job['probation_duration']?.toString() ?? '';
    final joiningDateRaw = job['joining_date']?.toString() ?? '';
    bool isCtcPaid() {
      final digits = RegExp(r'\d+')
          .allMatches(ctcRaw)
          .map((m) => m.group(0))
          .where((s) => s != null)
          .toList();
      if (digits.isEmpty) return false;
      try {
        for (final d in digits) {
          final n = int.tryParse(d ?? '0') ?? 0;
          if (n > 0) return true;
        }
      } catch (_) {}
      return false;
    }

    final ctcDisplay =
        isCtcPaid() ? (ctcRaw.isNotEmpty ? ctcRaw : 'N/A') : 'Unpaid';

    String percentify(String raw) {
      if (raw.isEmpty) return '';
      final trimmed = raw.trim();
      if (trimmed.endsWith('%')) return trimmed;
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed)) {
        return '$trimmed%';
      }
      return trimmed;
    }

    final fixedPay = percentify(fixedPayRaw);
    final variablePay = percentify(variablePayRaw);
    final otherIncentives = percentify(otherIncentivesRaw);

    Widget unifiedInfoTool(String label, String value) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
          decoration: BoxDecoration(
            color: Color(0xFFEBF6F7),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF6B6B6B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF003840),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            unifiedInfoTool('Posted on', postedHuman),
            SizedBox(width: 12.w),
            unifiedInfoTool('Application deadline', deadlineHuman),
          ],
        ),
        SizedBox(
          height: 12.h,
        ),
        Row(
          children: [
            unifiedInfoTool('CTC', ctcDisplay),
            SizedBox(width: 10.w),
            unifiedInfoTool(
              'Expected joining date',
              joiningDateRaw.isNotEmpty
                  ? _formatJoiningDate(joiningDateRaw)
                  : 'N/A',
            ),
          ],
        ),
        _sectionTitle('Probation Duration'),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF6F7),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            probationDuration.isNotEmpty ? probationDuration : 'N/A',
            style: subHeadingStyle.copyWith(fontSize: 14.sp),
          ),
        ),
        _sectionTitle('CTC Breakdown'),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF6F7),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fixedPay.isNotEmpty) _keyValueRow('Fixed pay', fixedPay),
              if (variablePay.isNotEmpty)
                _keyValueRow('Variable pay', variablePay),
              if (otherIncentives.isNotEmpty)
                _keyValueRow('Other incentives', otherIncentives),
              if (fixedPay.isEmpty &&
                  variablePay.isEmpty &&
                  otherIncentives.isEmpty)
                Text('Not specified', style: infoLightStyle),
            ],
          ),
        ),
        _sectionTitle('Qualification'),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF6F7),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _qualificationWidget(job),
        ),
        _sectionTitle('Location'),
        _locationBlock(job),
      ],
    );
  }

  Widget _qualificationWidget(Map<String, dynamic>? job) {
    final raw = job?['qualification'];
    final List<Map<String, String>> list = [];

    try {
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final course =
                (item['course_name'] ?? item['course'] ?? '').toString().trim();
            final spec =
                (item['specialization_name'] ?? item['specialization'] ?? '')
                    .toString()
                    .trim();
            if (course.isEmpty && spec.isEmpty) continue;
            list.add({'course': course, 'spec': spec});
          }
        }
      }
    } catch (_) {}

    // fallback if list empty
    if (list.isEmpty) {
      final rawCourses = job?['job_course_detail'];
      if (rawCourses is List && rawCourses.isNotEmpty) {
        for (final it in rawCourses) {
          if (it is Map) {
            final course =
                (it['course_name'] ?? it['course'] ?? '').toString().trim();
            final spec =
                (it['specialization_name'] ?? it['specialization'] ?? '')
                    .toString()
                    .trim();
            if (course.isEmpty && spec.isEmpty) continue;
            list.add({'course': course, 'spec': spec});
          }
        }
      }
    }

    if (list.isEmpty) {
      return Text('Not specified',
          style: infoStyle.copyWith(color: Colors.grey[700]));
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: list.map((m) {
        final course = m['course'] ?? '';
        final spec = m['spec'] ?? '';
        final label = course.isNotEmpty && spec.isNotEmpty
            ? '$course - $spec'
            : course + spec;

        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 1.w),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF8F9),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(label, style: infoStyle),
        );
      }).toList(),
    );
  }

  String _formatJoiningDate(String raw) {
    try {
      final s = raw.trim();
      DateTime parsed;
      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(s)) {
        final parts = s.split('-');
        parsed = DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } else {
        parsed = DateTime.parse(s);
      }
      return DateFormat('d MMMM yyyy').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  Widget _keyValueRow(String key, String val) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
              child: Text(key,
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF003840),
                      fontWeight: FontWeight.w600))),
          Text(val,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF003840),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _locationBlock(Map<String, dynamic>? job) {
    final locs = job?['locations'];
    final Map<String, Set<String>> grouped = {};
    try {
      if (locs is List && locs.isNotEmpty) {
        for (final item in locs) {
          if (item is Map) {
            final state =
                (item['state_name'] ?? item['state'] ?? '').toString().trim();
            final city =
                (item['city_name'] ?? item['city'] ?? '').toString().trim();
            if (state.isEmpty && city.isEmpty) continue;
            final stateKey = state.isEmpty ? 'Other' : state;
            grouped.putIfAbsent(stateKey, () => <String>{});
            if (city.isNotEmpty) grouped[stateKey]!.add(city);
          } else if (item is String) {
            grouped.putIfAbsent('Other', () => <String>{});
            grouped['Other']!.add(item);
          }
        }
      }
    } catch (_) {}
    final List<String> lines = [];
    if (grouped.isNotEmpty) {
      grouped.forEach((state, cities) {
        final cityList = cities.toList()..sort();
        if (cityList.isEmpty) {
          lines.add(state);
        } else {
          lines.add('$state - ${cityList.join(', ')}');
        }
      });
    } else {
      final fallback = (job?['location'] as String?)?.trim() ?? 'N/A';
      lines.add(fallback.isNotEmpty ? fallback : 'N/A');
    }
    const collapsed = 2;
    final bool needToggle = lines.length > collapsed;
    final List<String> shown = (!needToggle || isLocationExpanded)
        ? lines
        : lines.sublist(0, collapsed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF6F7),
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              ...shown.map((l) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(l,
                        style: infoStyle.copyWith(color: Colors.grey[800])),
                  )),
              if (needToggle)
                GestureDetector(
                  onTap: () =>
                      setState(() => isLocationExpanded = !isLocationExpanded),
                  child: Padding(
                    padding: EdgeInsets.only(top: 0),
                    child: Text(
                      isLocationExpanded ? 'Show less' : 'Show more',
                      style: headingStyle.copyWith(
                        fontSize: 14.sp,
                        color: const Color(0xFF005E6A),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _applicationProcessScroll(List<dynamic> process) {
    if (process.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'No application process specified',
          style: infoStyle.copyWith(color: Colors.grey[700]),
        ),
      );
    }

    return SizedBox(
      height: 64.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: process.length,
        separatorBuilder: (_, __) => Container(
          width: 32.w,
          alignment: Alignment.center,
          child: Icon(
            Icons.chevron_right,
            size: 20.w,
            color: Colors.grey[400],
          ),
        ),
        itemBuilder: (context, index) {
          final step = process[index];

          final name = (step is Map && step['name'] != null)
              ? step['name'].toString()
              : step.toString();

          final type = (step is Map && step['type'] != null)
              ? step['type'].toString()
              : '';

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F9),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Step Name
                Text(
                  name,
                  style: headingStyle.copyWith(
                    fontSize: 13.sp,
                    color: const Color(0xFF005E6A),
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4.h),

                /// Step Type (Optional)
                if (type.isNotEmpty)
                  Text(
                    type,
                    style: infoStyle.copyWith(
                      fontSize: 11.sp,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
