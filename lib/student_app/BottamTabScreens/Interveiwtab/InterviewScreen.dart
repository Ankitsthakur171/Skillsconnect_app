import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Model/InterviewScreen_Model.dart';
import '../../Pages/Notification_icon_Badge.dart';
import '../../Pages/bottombar.dart';
import '../../Pages/noInternetPage_jobs.dart';
import '../../Utilities/JoinInterviewApi.dart';
import '../../Utilities/Services/InterviewsRepository.dart';
import 'Interview_Bottom_Sheet.dart';
import 'interviewCard.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  int _selectedIndex = 0;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _hasInternet = true;
  bool _isRetrying = false;
  bool _showShimmer = true;

  final InterviewsRepository _repo = InterviewsRepository();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkInternetAndLoad();
    _repo.backgroundCheckAndUpdate();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _showShimmer = false);
    });
  }

  Future<void> _checkInternetAndLoad() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (!mounted) return;
        setState(() => _hasInternet = true);
        await _repo.getInterviews();
      } else {
        if (!mounted) return;
        setState(() => _hasInternet = false);
        await _repo.getInterviews();
      }
    } on SocketException {
      if (!mounted) return;
      setState(() => _hasInternet = false);
      await _repo.getInterviews();
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasInternet = false);
      await _repo.getInterviews();
    }
  }

  Future<void> _retryConnection() async {
    if (!mounted) return;
    setState(() {
      _isRetrying = true;
      _showShimmer = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _showShimmer = false);
    });

    await _checkInternetAndLoad();

    if (!mounted) return;
    setState(() => _isRetrying = false);
  }

  Future<void> _refreshInterviewList() async {
    if (!_hasInternet) {
      await _retryConnection();
      return;
    }
    setState(() => _showShimmer = true);
    await _repo.getInterviews(forceRefresh: true);
    if (!mounted) return;
    setState(() => _showShimmer = false);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF005E6A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Color(0xFFEBF6F7),
            ),
            dialogBackgroundColor: const Color(0xFFEBF6F7),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showSnack("Could not open link");
    }
  }

  Future<void> _joinAndOpen(InterviewModel item) async {
    final int? meetingId =
    item.moderator.isNotEmpty ? item.moderator.first.meetingId : null;

    if (meetingId == null) {
      if (!mounted) return;
      _showSnack('Meeting id not available', isError: true);
      return;
    }

    if (!mounted) return;
    _showSnack("Joining Interview...");

    final res = await JoinInterviewApi.joinInterview(
      meetingId: meetingId.toString(),
    );

    if (!mounted) return;
    if (res.ok && res.url != null) {
      await _openExternal(res.url!);
    } else {
      _showSnack('Failed to join interview', isError: true);
    }
  }
  void _showOfficeDetailSheet(InterviewModel m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return InOfficeDetailSheet(
          model: m,
          meetingMapLink: m.meetingMapLink,
          meetingAddress: m.meetingAddress,
          contactPerson: m.contactPerson,
        );
      },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.tealAccent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        color: const Color(0xFFEBF6F7),
        child: RefreshIndicator(
          onRefresh: _refreshInterviewList,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(64.h),
              child: SafeArea(child: _buildAppBar()),
            ),
            body: SafeArea(
              child: !_hasInternet
                  ? (_showShimmer
                  ? _buildShimmerList()
                  : NoInternetPage(onRetry: _retryConnection))
                  : ValueListenableBuilder<List<InterviewModel>?>(
                valueListenable: _repo.notifier,
                builder: (context, data, _) {
                  if (data == null) return _buildShimmerList();

                  if (data.isEmpty) {
                    return _showShimmer
                        ? _buildShimmerList()
                        : const Center(child: Text("No interviews Scheduled yet"));
                  }

                  List<InterviewModel> filteredData;
                  if (_startDate != null && _endDate != null) {
                    filteredData = data.where((item) {
                      DateTime interviewDate;
                      try {
                        interviewDate =
                            DateFormat('dd MMM yyyy').parse(item.date);
                      } catch (_) {
                        interviewDate =
                            DateTime.tryParse(item.date) ?? DateTime(1970);
                      }
                      return !interviewDate.isBefore(_startDate!) &&
                          !interviewDate.isAfter(_endDate!);
                    }).toList();
                  } else {
                    filteredData = data;
                  }

                  if (filteredData.isEmpty) {
                    return _showShimmer
                        ? _buildShimmerList()
                        : const Center(
                        child: Text('No interviews found',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey)));
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 8.h),
                    child: Column(
                      children: filteredData.map((item) {
                        final isOffice =
                        item.meetingMode.toLowerCase().contains('office');
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: InterviewCard(
                            model: item,
                            onJoinTap: () {
                              if (isOffice) {
                                _showOfficeDetailSheet(item);
                              } else {
                                _joinAndOpen(item);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(64.h),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          height: 64.h,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(17.w, 17.h, 17.w, 0.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _pickDateRange,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Row(
                        children: [
                          Icon(Icons.date_range,
                              color: Colors.black, size: 18.sp),
                          SizedBox(width: 8.w),

                          Expanded(
                            child: Text(
                              _startDate != null && _endDate != null
                                  ? "${_startDate!.toLocal().toString().split(' ')[0]} → ${_endDate!.toLocal().toString().split(' ')[0]}"
                                  : "Select date range",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),

                          SizedBox(width: 6.w),
                          Icon(Icons.arrow_drop_down,
                              color: Colors.black, size: 18.sp),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (_startDate != null && _endDate != null) ...[
                SizedBox(width: 6.w),
                _iconCircleButton(Icons.close, onTap: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _repo.getInterviews();
                }),
              ],

              SizedBox(width: 10.w),
             NotificationBell(),

            ],
          ),
        ),
      ),
    );
  }

  Widget _iconCircleButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 18.w, color: Colors.black),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 8.h),
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
              child: Column(
                children: [
                  Row(children: [
                    Container(
                        width: 34.w,
                        height: 34.h,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7.r))),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 15.h, width: 100.w, color: Colors.white),
                            SizedBox(height: 5.h),
                            Container(height: 12.h, width: 150.w, color: Colors.white),
                          ]),
                    ),
                    SizedBox(width: 7.w),
                    Container(height: 14.h, width: 44.w, color: Colors.white),
                  ]),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 7.w,
                    runSpacing: 7.h,
                    children: List.generate(3, (index) {
                      return Container(
                        height: 18.h,
                        width: 50.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 7.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 12.h, width: 70.w, color: Colors.white),
                  Container(height: 12.h, width: 50.w, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// without the  custom bottom nav bar


class InterviewScreenCustom extends StatefulWidget {
  const InterviewScreenCustom({super.key});

  @override
  State<InterviewScreenCustom> createState() => _InterviewScreenCustomState();
}

class _InterviewScreenCustomState extends State<InterviewScreenCustom> {
  int _selectedIndex = 0;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _hasInternet = true;
  bool _isRetrying = false;
  bool _showShimmer = true;

  final InterviewsRepository _repo = InterviewsRepository();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkInternetAndLoad();
    _repo.backgroundCheckAndUpdate();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _showShimmer = false);
    });
  }

  Future<void> _checkInternetAndLoad() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (!mounted) return;
        setState(() => _hasInternet = true);
        await _repo.getInterviews();
      } else {
        if (!mounted) return;
        setState(() => _hasInternet = false);
        await _repo.getInterviews();
      }
    } on SocketException {
      if (!mounted) return;
      setState(() => _hasInternet = false);
      await _repo.getInterviews();
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasInternet = false);
      await _repo.getInterviews();
    }
  }

  Future<void> _retryConnection() async {
    if (!mounted) return;
    setState(() {
      _isRetrying = true;
      _showShimmer = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _showShimmer = false);
    });

    await _checkInternetAndLoad();

    if (!mounted) return;
    setState(() => _isRetrying = false);
  }

  Future<void> _refreshInterviewList() async {
    if (!_hasInternet) {
      await _retryConnection();
      return;
    }
    setState(() => _showShimmer = true);
    await _repo.getInterviews(forceRefresh: true);
    if (!mounted) return;
    setState(() => _showShimmer = false);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF005E6A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Color(0xFFEBF6F7),
            ),
            dialogBackgroundColor: const Color(0xFFEBF6F7),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showSnack("Could not open link");
    }
  }

  Future<void> _joinAndOpen(InterviewModel item) async {
    final int? meetingId =
    item.moderator.isNotEmpty ? item.moderator.first.meetingId : null;

    if (meetingId == null) {
      if (!mounted) return;
      _showSnack('Meeting id not available', isError: true);
      return;
    }

    if (!mounted) return;
    _showSnack("Joining Interview...");

    final res = await JoinInterviewApi.joinInterview(
      meetingId: meetingId.toString(),
    );

    if (!mounted) return;
    if (res.ok && res.url != null) {
      await _openExternal(res.url!);
    } else {
      _showSnack('Failed to join interview', isError: true);
    }
  }
  void _showOfficeDetailSheet(InterviewModel m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return InOfficeDetailSheet(
          model: m,
          meetingMapLink: m.meetingMapLink,
          meetingAddress: m.meetingAddress,
          contactPerson: m.contactPerson,
        );
      },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.tealAccent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        color: const Color(0xFFEBF6F7),
        child: RefreshIndicator(
          onRefresh: _refreshInterviewList,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(64.h),
              child: SafeArea(child: _buildAppBar()),
            ),
            body: SafeArea(
              child: !_hasInternet
                  ? (_showShimmer
                  ? _buildShimmerList()
                  : NoInternetPage(onRetry: _retryConnection))
                  : ValueListenableBuilder<List<InterviewModel>?>(
                valueListenable: _repo.notifier,
                builder: (context, data, _) {
                  if (data == null) return _buildShimmerList();

                  if (data.isEmpty) {
                    return _showShimmer
                        ? _buildShimmerList()
                        : const Center(child: Text("No interviews Scheduled yet"));
                  }

                  List<InterviewModel> filteredData;
                  if (_startDate != null && _endDate != null) {
                    filteredData = data.where((item) {
                      DateTime interviewDate;
                      try {
                        interviewDate =
                            DateFormat('dd MMM yyyy').parse(item.date);
                      } catch (_) {
                        interviewDate =
                            DateTime.tryParse(item.date) ?? DateTime(1970);
                      }
                      return !interviewDate.isBefore(_startDate!) &&
                          !interviewDate.isAfter(_endDate!);
                    }).toList();
                  } else {
                    filteredData = data;
                  }

                  if (filteredData.isEmpty) {
                    return _showShimmer
                        ? _buildShimmerList()
                        : const Center(
                        child: Text('No interviews found',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey)));
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 8.h),
                    child: Column(
                      children: filteredData.map((item) {
                        final isOffice =
                        item.meetingMode.toLowerCase().contains('office');
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: InterviewCard(
                            model: item,
                            onJoinTap: () {
                              if (isOffice) {
                                _showOfficeDetailSheet(item);
                              } else {
                                _joinAndOpen(item);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            // bottomNavigationBar: CustomBottomNavBar(
            //   currentIndex: _selectedIndex,
            //   onTap: _onItemTapped,
            // ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(64.h),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          height: 64.h,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(17.w, 17.h, 17.w, 0.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _pickDateRange,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Row(
                        children: [
                          Icon(Icons.date_range,
                              color: Colors.black, size: 18.sp),
                          SizedBox(width: 8.w),

                          Expanded(
                            child: Text(
                              _startDate != null && _endDate != null
                                  ? "${_startDate!.toLocal().toString().split(' ')[0]} → ${_endDate!.toLocal().toString().split(' ')[0]}"
                                  : "Select date range",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),

                          SizedBox(width: 6.w),
                          Icon(Icons.arrow_drop_down,
                              color: Colors.black, size: 18.sp),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (_startDate != null && _endDate != null) ...[
                SizedBox(width: 6.w),
                _iconCircleButton(Icons.close, onTap: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _repo.getInterviews();
                }),
              ],

              SizedBox(width: 10.w),
             NotificationBell(),

            ],
          ),
        ),
      ),
    );
  }

  Widget _iconCircleButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 18.w, color: Colors.black),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 8.h),
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
              child: Column(
                children: [
                  Row(children: [
                    Container(
                        width: 34.w,
                        height: 34.h,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7.r))),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 15.h, width: 100.w, color: Colors.white),
                            SizedBox(height: 5.h),
                            Container(height: 12.h, width: 150.w, color: Colors.white),
                          ]),
                    ),
                    SizedBox(width: 7.w),
                    Container(height: 14.h, width: 44.w, color: Colors.white),
                  ]),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 7.w,
                    runSpacing: 7.h,
                    children: List.generate(3, (index) {
                      return Container(
                        height: 18.h,
                        width: 50.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 7.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 12.h, width: 70.w, color: Colors.white),
                  Container(height: 12.h, width: 50.w, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


