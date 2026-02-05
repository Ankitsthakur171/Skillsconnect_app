
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/student_app/Utilities/auth/StudentAuth.dart';
import 'package:skillsconnect/student_app/blocpage/NotificationBloc/notification_bloc.dart';
import 'package:skillsconnect/student_app/blocpage/NotificationBloc/notification_event.dart';
import 'package:skillsconnect/student_app/blocpage/bloc_event.dart';
import '../../Model/AccountScreen_Image_Name_Model.dart';
import '../../Pages/Notification_icon_Badge.dart';
import '../../Pages/bottombar.dart';
import '../../ProfileLogic/ProfileEvent.dart';
import '../../ProfileLogic/ProfileLogic.dart';
import '../../Utilities/MyAccount_Get_Post/AccountImageApi.dart';
import '../../Utilities/auth/LoginUserApi.dart';
import 'package:shimmer/shimmer.dart';
import '../../Utilities/auth/Logout_Api.dart';
import '../../blocpage/bloc_logic.dart';
import '../../blocpage/bloc_state.dart';
import '../../blocpage/BookmarkBloc/bookmarkLogic.dart';
import '../../blocpage/BookmarkBloc/bookmarkEvent.dart';
import '../../blocpage/jobFilterBloc/jobFilter_logic.dart';
import '../../blocpage/jobFilterBloc/jobFilter_event.dart';
import 'Assessments/Assessment_page.dart';
import 'MyInterviewVid/MyInterviewVideos.dart';
import 'MyJobs/AppliedJobs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/HR/screens/splash_screen.dart';
import 'Myaccount/MyAccount.dart';
import 'Settings/Settings_file.dart';
import 'WatchListScreen/WatchList.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AcountScreenImageModel? _profileData;
  int _selectedIndex = 0;
  bool _isLoggingOut = false;
  bool _snackBarShown = false;
  bool _isLoading = true;

  final List<Map<String, dynamic>> options = [
    {"icon": Icons.person_outline, "label": "My Account"},
    {"icon": Icons.business_center_outlined, "label": "My Jobs"},
    {"icon": Icons.bookmark_add_outlined, "label": "Watchlist"},
    {"icon": Icons.assessment_outlined, "label": "Assessment"},
    {"icon": Icons.ondemand_video_sharp, "label": "My Intro videos"},
    {"icon": Icons.settings_outlined, "label": "Account Settings"},
    {"icon": Icons.logout, "label": "Logout"},
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _showSnackBarOnce(
      BuildContext context, String message,
      {int cooldownSeconds = 3})
  {
    if (_snackBarShown) return;
    _snackBarShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 13.sp)),
        backgroundColor: Colors.red,
        duration: Duration(seconds: cooldownSeconds),
      ),
    );
    Future.delayed(
        Duration(seconds: cooldownSeconds), () => _snackBarShown = false);
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Confirm Logout', style: TextStyle(fontSize: 18.sp)),
        content: Text('Are you sure you want to logout?',
            style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.black, fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Logout',
                style: TextStyle(color: Colors.black, fontSize: 14.sp)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    if (!await _hasInternetConnection()) {
      _showSnackBarOnce(context, "No internet connection");
      return;
    }

    if (!mounted) return;
    setState(() => _isLoggingOut = true);

    try {
      final resp = await LogoutApi.logout();
      if (resp['success'] == true) {
        final apiData = resp['data'];
        final serverSaysSuccess = apiData is Map &&
            (apiData['success'] == true ||
                apiData['message'] == "Logged out successfully." ||
                apiData['msg'] == "Logged out successfully.");

        if (serverSaysSuccess) {
          // Clear ALL stored data comprehensively
          final prefs = await SharedPreferences.getInstance();
          
          // Clear authentication tokens (all formats)
          await prefs.remove('auth_token');      // HR/TPO format
          await prefs.remove('authToken');       // Legacy student format
          await prefs.remove('connectSid');      // Legacy student format
          
          // Clear user data
          await prefs.remove('user_data');       // Encrypted user data
          await prefs.remove('user_id');         // User ID
          
          // Clear company data (HR)
          await prefs.remove('company_name');
          await prefs.remove('company_logo');
          
          // Clear TPO profile data
          await prefs.remove('tpo_profile_name');
          await prefs.remove('tpo_profile_role');
          await prefs.remove('tpo_profile_image');
          await prefs.remove('tpo_college_name');
          await prefs.remove('tpo_img');
          
          // Clear call-related data
          await prefs.remove('pending_join');
          await prefs.remove('last_callkit_ch');
          
          // Clear any other session data
          await prefs.remove('fcm_token');
          
          // Also clear using StudentAuth for completeness
          await StudentAuth.clearAuth();
          
          // Clear legacy student tokens
          final loginService = loginUser();
          await loginService.clearToken();

          if (!mounted) return;

          // Reset all BLoC states to clear navigation and session data
          if (context.mounted) {
            context.read<NavigationBloc>().add(ResetNavigation());
            context.read<ProfileBloc>().add(ResetProfileData());
            context.read<BookmarkBloc>().add(ResetBookmarksEvent());
            context.read<JobFilterBloc>().add(ResetJobFilters());
            context.read<NotificationBloc>().add(ResetNotifications()); // ✅ Clear notifications
          }

          // Navigate to HR/TPO SplashScreen (unified login flow)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SplashScreen()),
                (route) => false,
          );
        } else {
          String message = 'Logout failed';
          if (apiData is Map &&
              (apiData['message'] != null || apiData['msg'] != null)) {
            message = (apiData['message'] ?? apiData['msg']).toString();
          }
          if (context.mounted) _showSnackBarOnce(context, message);
        }
      } else {
        final message = resp['message'] ?? 'Logout failed';
        if (context.mounted) _showSnackBarOnce(context, message.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final data = await AccountImageApi.fetchAccountScreenData();
    if (mounted) {
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    context.read<ProfileBloc>().add(LoadProfileData());
    await Future.delayed(const Duration(seconds: 1));
    await _loadProfileData();
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dob);
      final today = DateTime.now();
      int age = today.year - date.year;
      if (today.month < date.month ||
          (today.month == date.month && today.day < date.day)) {
        age--;
      }
      if (age < 0 || age > 120) return 'N/A';
      return '$age years old';
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true);

    final accent = const Color(0xFF005E6A);
    final borderColor = const Color(0xFFD0DDDC);

    return BlocListener<NavigationBloc, NavigationState>(
      listener: (_, __) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: ConsistentAppBar(
          left: Text(
            "Account",
            style: TextStyle(
              fontSize: 25.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF003840),
            ),
          ),
        ),

        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Column(
                  children: [
                    SizedBox(
                      child: Center(
                        child: _isLoading
                            ? _buildProfileShimmer()
                            : _profileData == null
                            ? Text(
                            "No profile data",
                            style: TextStyle(
                                fontSize: 14.sp, color: Colors.grey))
                            : _buildProfileBlock(accent),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Divider(color: borderColor, thickness: 1),
                    SizedBox(height: 8.h),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: accent,
                        backgroundColor: Colors.white,
                        child: ListView.separated(
                          itemCount: options.length,
                          separatorBuilder: (_, __) => SizedBox(height: 6.h),
                          padding: EdgeInsets.only(top: 6.h, bottom: 12.h),
                          itemBuilder: (context, index) {
                            final opt = options[index];
                            final label = opt['label'] as String;
                            final iconData = opt['icon'] as IconData;
                            final isLogout = label.toLowerCase() == 'logout';
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.w),
                              child: Material(
                                color: Colors.white,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10.r),
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    if (!isLogout) {
                                      final connected =
                                      await _hasInternetConnection();
                                      if (!connected) {
                                        _showSnackBarOnce(
                                            context, "No internet connection"
                                        );
                                        return;
                                      }
                                    }
                                    switch (label) {
                                      case 'Logout':
                                        _logout();
                                        break;
                                      case 'My Account':
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                const MyAccount()))
                                            .then((_) {
                                          if (mounted) {
                                            context
                                                .read<ProfileBloc>()
                                                .add(LoadProfileData());
                                          }
                                        });
                                        break;
                                      case 'My Intro videos':
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    MyInterviewVideos()));
                                        break;
                                      case 'Watchlist':
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    WatchListPage()));
                                        break;
                                      case 'Assessment':
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    AssessmentPage()));
                                        break;
                                      case 'My Jobs':
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    AppliedJobsPage()));
                                        break;
                                      case 'Account Settings':
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    SettingsFile()));
                                        break;
                                    }
                                  },
                                  child: Container(
                                    height: 58.h,
                                    padding:
                                    EdgeInsets.symmetric(horizontal: 10.w),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(
                                          color: borderColor.withOpacity(0.9),
                                          width: 1.6),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42.w,
                                          height: 42.w,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: borderColor
                                                    .withOpacity(0.9),
                                                width: 1.4
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(iconData,
                                                size: 20.w,
                                                color: isLogout
                                                    ? Colors.red
                                                    : accent),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF22383A)),
                                          ),
                                        ),
                                        Icon(
                                            Icons.chevron_right,
                                            color: const Color(0xFFB7D4D6),
                                            size: 20.w
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoggingOut)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.28),
                    child: Center(
                      child: SizedBox(
                        width: 60.w,
                        height: 60.w,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                          strokeWidth: 3.5.w,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
            currentIndex: _selectedIndex, onTap: _onItemTapped),
      ),
    );
  }

  Widget _buildProfileBlock(Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 110.w,
          height: 110.w,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 1.5.w)
          ),
          child: ClipOval(
            child: SizedBox.expand(
              child: Transform.scale(
                scale: 1.08,
                child: _profileData!.userImage != null
                    ? Image.network(
                        _profileData!.userImage!,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      )
                    : Image.asset(
                        'assets/placeholder.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${_profileData!.firstName ?? ''} ${_profileData!.lastName ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                      color: accent),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        if (_profileData!.age != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              _calculateAge(_profileData!.age!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6A8E92)),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileShimmer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
              width: 110.w,
              height: 110.w,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white)),
        ),
        SizedBox(height: 12.h),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(width: 160.w, height: 18.h, color: Colors.white),
        ),
        SizedBox(height: 6.h),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(width: 120.w, height: 14.h, color: Colors.white),
        ),
      ],
    );
  }
  // Widget _iconCircle({required IconData icon, required double iconSize}) {
  //   return Container(
  //     width: 38.w,
  //     height: 38.w,
  //     decoration: BoxDecoration(
  //         shape: BoxShape.circle,
  //         border: Border.all(color: Colors.grey.withOpacity(0.3)),
  //         color: Colors.white),
  //     child: Icon(icon, size: iconSize, color: const Color(0xFF003840)),
  //   );
  // }
}

class ConsistentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ConsistentAppBar({
    super.key,
    required this.left,
    this.leftExtras = const <Widget>[],
    this.expandLeft = false,
    this.height,
    this.padding,
    this.backgroundColor = Colors.white,
  });

  final Widget left;
  final List<Widget> leftExtras;
  final bool expandLeft;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;

  @override
  Size get preferredSize => Size.fromHeight(height ?? 64.h);

  @override
  Widget build(BuildContext context) {
    final barHeight = height ?? 64.h;
    final contentPadding = padding ?? EdgeInsets.fromLTRB(17.w, 17.h, 17.w, 0.h);

    return Material(
      color: backgroundColor,
      child: SafeArea(
        top: true,
        bottom: false,
        child: SizedBox(
          height: barHeight,
          child: Padding(
            padding: contentPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (expandLeft) Expanded(child: left) else left,
                if (leftExtras.isNotEmpty) SizedBox(width: 3.w),
                ..._intersperse(leftExtras, SizedBox(width: 3.w)),
                 // SizedBox(width:  10.w,),
                  Spacer(),
                  NotificationBell(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> items, Widget gap) {
    if (items.isEmpty) return items;
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i < items.length - 1) out.add(gap);
    }
    return out;
  }
}
