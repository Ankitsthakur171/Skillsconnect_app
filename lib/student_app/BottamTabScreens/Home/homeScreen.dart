import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../Model/Banner_model.dart';
import '../../Model/Popular_Job_Model.dart';
import '../../Pages/HomeScreenShimmers.dart';
import '../../Pages/bottombar.dart';
import '../../Model/featured_Job_Model.dart';
import '../../Pages/noInternetPage_jobs.dart';
import '../../Utilities/ApiConstants.dart';
import '../../blocpage/bloc_event.dart';
import '../../blocpage/bloc_logic.dart';
import '../JobTab/JobdetailPage/JobdetailpageBT.dart';
import 'CustomAppbarBT.dart';
import 'DashboardHeaderSection.dart';
import '../../Utilities/MyAccount_Get_Post/HomeScreenDashboard_Api.dart';
import '../../Model/Dashboard_Model.dart';
import 'KnowHowBanner.dart';
import 'PopularJobCard.dart';
import 'InterviewScheduleCard.dart';
import 'FeaturedJobCard.dart';
import 'ProfileCompletionCard.dart';
import 'package:http/http.dart' as http;

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({super.key});

  @override
  State<HomeScreen2> createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {
  int _selectedIndex = 0;
  List<FeaturedJob> _featuredJobs = [];
  List<PopularJob> _popularJobs = [];
  List<BannerModel> _banners = [];
  bool _isLoadingPopular = true;
  bool _isLoadingFeatured = true;
  bool _isLoadingBanners = true;
  bool _hasInternet = true;
  bool _isRetrying = false;
  bool _showShimmer = true;
  DashboardData? _dashboardData;
  bool _isLoadingDashboard = true;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print('🔍 [HomeScreen2] Bottom nav index changed to: $index');
    });
  }

  @override
  void initState() {
    super.initState();
    _checkInternetAndFetch();
    _fetchDashboardData();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _showShimmer = false);
    });
  }

  Future<void> _checkInternetAndFetch() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
        await _fetchHomeData();
      }
    } on SocketException {
      setState(() {
        _hasInternet = false;
        _isLoadingBanners = false;
        _isLoadingFeatured = false;
        _isLoadingPopular = false;
      });
    }
  }

  Future<void> _retryConnection() async {
    setState(() {
      _isRetrying = true;
      _showShimmer = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    await _checkInternetAndFetch();
    if (!mounted) return;
    setState(() {
      _isRetrying = false;
      _showShimmer = false;
    });
  }

  Future<void> _fetchDashboardData() async {
    try {
      print('📊 [HomeScreen2] Fetching dashboard data...');
      final data = await HomeScreenDashboardApi.fetchDashboard();
      
      print('📊 [HomeScreen2] Dashboard data result: ${data != null ? "SUCCESS" : "NULL"}');
      
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoadingDashboard = false;
          if (data != null) {
            print('✅ [HomeScreen2] Dashboard data loaded - Profile: ${data.profile.name}');
          } else {
            print('⚠️ [HomeScreen2] Dashboard data is null - API may have failed');
          }
        });
      }
    } catch (e, st) {
      print('❌ [HomeScreen2] Error fetching dashboard: $e');
      print('   Stack: $st');
      if (mounted) {
        setState(() => _isLoadingDashboard = false);
      }
    }
  }

  Future<void> _fetchHomeData() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    try {
      var url = Uri.parse(ApiConstantsStu.homeScreenApi);
      var headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      var request = http.Request('POST', url);
      request.headers.addAll(headers);

      http.StreamedResponse response =
          await request.send().timeout(const Duration(seconds: 10));

      print('📩 [HomeScreen2] Home data response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final String jsonString = await response.stream.bytesToString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        if (data["status"] == true) {
          final bannersJson = data["banners"] as List? ?? [];
          final bannerList = bannersJson
              .map((e) => BannerModel.fromJson(e))
              .where((banner) => banner.image.isNotEmpty)
              .toList();

          final featuredJobsJson = data["featured_jobs"] as List? ?? [];
          final featuredJobsList =
              featuredJobsJson.map((e) => FeaturedJob.fromJson(e)).toList();

          final popularJobsJson = data["popular_jobs"] as List? ?? [];
          final popularJobsList =
              popularJobsJson.map((e) => PopularJob.fromJson(e)).toList();

          if (!mounted) return;
          setState(() {
            _banners = bannerList;
            _featuredJobs = featuredJobsList;
            _popularJobs = popularJobsList;
            _isLoadingBanners = false;
            _isLoadingFeatured = false;
            _isLoadingPopular = false;
            // print('✅ [HomeScreen2] Loaded ${bannerList.length} banners, '
            //     '${featuredJobsList.length} featured jobs, '
            //     '${popularJobsList.length} popular jobs');
          });
        } else {
          if (!mounted) return;
          setState(() {
            _isLoadingBanners = false;
            _isLoadingFeatured = false;
            _isLoadingPopular = false;
          });
        }
      } else {
        print(
            '⚠️ [HomeScreen2] Failed to fetch home data: ${response.statusCode} - ${response.reasonPhrase}');
        if (!mounted) return;
        setState(() {
          _isLoadingBanners = false;
          _isLoadingFeatured = false;
          _isLoadingPopular = false;
        });
      }
    } catch (e) {
      print('❌ [HomeScreen2] Error fetching home data: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingBanners = false;
        _isLoadingFeatured = false;
        _isLoadingPopular = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load home data',
                style: TextStyle(fontSize: 12.4.sp))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    final double appBarHeight = 43.3.h;
    final double bottomNavBarHeight = 46.9.h;
    final double sectionHeaderHeight = 36.1.h;
    final double sizedBoxHeight = 9.h + 9.h + 15.4.h;
    final double knowHowBannerHeight = 126.4.h;
    final double paddingHeight = 13.6.h * 2;
    final double marginHeight = 36.1.h + 3.8.h;
    final double totalFixedHeight = appBarHeight +
        bottomNavBarHeight +
        (sectionHeaderHeight * 2) +
        sizedBoxHeight +
        knowHowBannerHeight +
        paddingHeight +
        marginHeight;
    final double availableHeight = ScreenUtil().screenHeight - totalFixedHeight;
    final double popularJobListHeight = availableHeight * 0.35;
    final double featuredJobListHeight = availableHeight * 0.65;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HomeScreenAppbar(),
      body: !_hasInternet
          ? (_showShimmer
              ? SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 2.9.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader("Popular Jobs", actionText: "See all"),
                        SizedBox(
                          height: popularJobListHeight.clamp(171.5.h, 189.5.h),
                          child: const Center(child: PopularJobShimmer()),
                        ),
                        SizedBox(height: 13.6.h),
                        const Center(child: KnowHowBannerShimmer()),
                        SizedBox(height: 9.h),
                        _sectionHeader("Featured Opportunities"),
                        SizedBox(
                          height: featuredJobListHeight.clamp(216.6.h, 243.7.h),
                          child: const Center(child: PopularJobShimmer()),
                        ),
                        SizedBox(height: 15.4.h),
                      ],
                    ),
                  ),
                )
              : NoInternetPage(onRetry: _retryConnection))
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(bottom: 2.9.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Header Section
                    if (_dashboardData != null && !_isLoadingDashboard)
                      DashboardHeaderSection(
                        profile: _dashboardData!.profile,
                        stats: _dashboardData!.stats,
                        latestApplication: _dashboardData!.myApplications.isNotEmpty
                            ? _dashboardData!.myApplications.first
                            : null,
                        onViewLatestApplication: () {
                          if (_dashboardData!.myApplications.isNotEmpty) {
                            final app = _dashboardData!.myApplications.first;
                            final tokenToUse = app.jobInvitationToken.isNotEmpty 
                              ? app.jobInvitationToken 
                              : app.id.toString();
                            final jobIdToUse = app.jobId > 0 
                              ? app.jobId 
                              : (int.tryParse(app.id.toString()) ?? 0);
                                    
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailPage2(
                                  jobToken: tokenToUse,
                                  moduleId: jobIdToUse,
                                ),
                              ),
                            );
                          }
                        },
                      )
                    else if (_isLoadingDashboard)
                      _buildDashboardHeaderShimmer(),
                    _sectionHeader("Popular Jobs", actionText: "See all",
                      onActionTap: () {
                      setState(() => _selectedIndex = 1);
                      context.read<NavigationBloc>().add(GotoJobScreen2());
                    },),
                    SizedBox(
                      height: popularJobListHeight.clamp(200.h, 220.h),
                      child: _isLoadingPopular || _showShimmer || _dashboardData == null
                          ? const Center(child: PopularJobShimmer())
                          : _dashboardData!.opportunityFeed.isEmpty
                              ? Center(
                                  child: Text("No opportunities found",
                                      style: TextStyle(fontSize: 12.4.sp)))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.6.w),
                                  itemCount: _dashboardData!.opportunityFeed.length,
                                  itemBuilder: (context, index) {
                                    final opportunity = _dashboardData!.opportunityFeed[index];
                                    return PopularJobCard(
                                      title: opportunity.role,
                                      subtitile: opportunity.company,
                                      description: '${opportunity.type} • ${opportunity.location}',
                                      salary: opportunity.stipend,
                                      time: 'Deadline: ${opportunity.deadline}',
                                      immageAsset: '',
                                      companyLogo: opportunity.companyLogo,
                                      costToCompany: opportunity.costToCompany,
                                      isEligible: opportunity.eligible,
                                      onTap: () {
                                        final tokenToUse = opportunity.jobInvitationToken.isNotEmpty 
                                          ? opportunity.jobInvitationToken 
                                          : opportunity.id;
                                        final jobIdToUse = opportunity.jobId > 0 
                                          ? opportunity.jobId 
                                          : (int.tryParse(opportunity.id) ?? 0);
                                    
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => JobDetailPage2(
                                              jobToken: tokenToUse,
                                              moduleId: jobIdToUse,
                                            ),
                                          ),
                                        );
                                      },
                                      onApply: opportunity.eligible ? () {
                                        final tokenToUse = opportunity.jobInvitationToken.isNotEmpty 
                                          ? opportunity.jobInvitationToken 
                                          : opportunity.id;
                                        final jobIdToUse = opportunity.jobId > 0 
                                          ? opportunity.jobId 
                                          : (int.tryParse(opportunity.id) ?? 0);
                                                                    
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => JobDetailPage2(
                                              jobToken: tokenToUse,
                                              moduleId: jobIdToUse,
                                            ),
                                          ),
                                        );
                                      } : null,
                                    );
                                  },
                                ),
                    ),
                    SizedBox(height: 10.h),
                    // Show Interview Schedule if available, otherwise show banner (knwohowbanner)
                    if (_dashboardData != null && _dashboardData!.interviewSchedule.isNotEmpty)
                      ...[
                        _sectionHeader("Interview Scheduled", actionText: "See all",
                          onActionTap: () {
                          setState(() => _selectedIndex = 2);
                          context.read<NavigationBloc>().add(GoToInterviewScreen2());
                        },),
                        SizedBox(
                          height: 250.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 12.6.w),
                            itemCount: _dashboardData!.interviewSchedule.length,
                            itemBuilder: (context, index) {
                              final interview = _dashboardData!.interviewSchedule[index];
                              return InterviewScheduleCard(
                                interview: interview,
                                onViewDetails: () {
                                  context.read<NavigationBloc>().add(GoToInterviewScreen2());
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 9.h),
                      ]
                    else
                      ...[
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Tap to know more  ",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Icon(
                                Icons.arrow_downward_rounded,
                                color: Colors.grey.shade600,
                                size: 16.sp,
                              ),
                            ],
                          ),
                        ),
                        _isLoadingBanners || _showShimmer
                            ? const Center(child: KnowHowBannerShimmer())
                            : _banners.isEmpty
                                ? Center(
                                    child: Text("No banners available",
                                        style: TextStyle(fontSize: 12.4.sp)))
                                : KnowHowBanner(banners: _banners),
                        SizedBox(height: 9.h),
                      ],
                    _sectionHeader("Recommended Next Steps"),
                    if (_dashboardData != null && !_isLoadingDashboard)
                      ProfileCompletionCard(
                        completionPercentage: _dashboardData!.profile.completion,
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    SizedBox(height: 15.4.h),
                    // FEATURED OPPORTUNITIES SECTION COMMENTED OUT
                    /* 
                    _sectionHeader("Featured Opportunities"),
                    SizedBox(
                      height: featuredJobListHeight.clamp(216.6.h, 243.7.h),
                      child: _isLoadingFeatured || _showShimmer
                          ? const Center(child: PopularJobShimmer())
                          : _featuredJobs.isEmpty
                              ? Center(
                                  child: Text("No featured jobs found",
                                      style: TextStyle(fontSize: 12.4.sp)))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.6.w),
                                  itemCount: _featuredJobs.length,
                                  itemBuilder: (context, index) {
                                    final job = _featuredJobs[index];
                                    return FeaturedJobCard(
                                      title: job.jobName,
                                      location: job.companyName,
                                      salary:
                                          "${job.salaryMin}-${job.salaryMax} LPA",
                                      applications: "87",
                                      timeLeft: job.postedOn,
                                      registered: "13000 Registered",
                                      jobType: "Full time (Hybrid)",
                                      imageAsset: job.companyLogo,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => JobDetailPage2(
                                              jobToken: job.jobId.toString(),
                                              moduleId: job.jobId,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                    ),
                    SizedBox(height: 15.4.h),
                    */
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _sectionHeader(String title, {String? actionText, VoidCallback? onActionTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.6.w, vertical: 13.6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.4.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF003840),
            ),
          ),

          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText,
                style: TextStyle(
                  fontSize: 12.8.sp,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeaderShimmer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section Shimmer
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12.h,
                        width: 100.w,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 24.h,
                        width: 150.w,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 12.h,
                        width: 120.w,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 12.h,
                      width: 80.w,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      height: 10.h,
                      width: 100.w,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Stats Grid Shimmer (2x2)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.w,
              children: List.generate(
                4,
                (_) => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
