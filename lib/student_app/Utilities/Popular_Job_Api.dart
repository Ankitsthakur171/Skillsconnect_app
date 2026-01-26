// import 'dart:convert';
// import 'package:shimmer/shimmer.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:sk_loginscreen1/BottamTabScreens/Home/CustomAppbarBT.dart';
// import 'package:sk_loginscreen1/BottamTabScreens/JobTab/JobdetailPage/JobdetailpageBT.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sk_loginscreen1/Pages/HomeScreenShimmers.dart';
// import '../../Model/Banner_model.dart';
// import '../../Model/Job_Model.dart';
// import '../../Model/Popular_Job_Model.dart';
// import '../../Pages/bottombar.dart';
// import '../../Utilities/Popular_Job_Api.dart';
// import '../../Model/featured_Job_Model.dart';
// import '../BottamTabScreens/Home/FeaturedJobCard.dart';
// import '../BottamTabScreens/Home/KnowHowBanner.dart';
// import '../BottamTabScreens/Home/PopularJobCard.dart';
// import 'ApiConstants.dart';
// import 'package:http/http.dart' as http;
//
// class HomeScreen2 extends StatefulWidget {
//   const HomeScreen2({super.key});
//
//   @override
//   State<HomeScreen2> createState() => _HomeScreen2State();
// }
//
// class _HomeScreen2State extends State<HomeScreen2> {
//   int _selectedIndex = 0;
//   List<FeaturedJob> _featuredJobs = [];
//   List<PopularJob> _popularJobs = [];
//   List<BannerModel> _banners = [];
//   bool _isLoadingPopular = true;
//   bool _isLoadingFeatured = true;
//   bool _isLoadingBanners = true;
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//       print('🔍 [HomeScreen2] Bottom nav index changed to: $index');
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     print('🔍 [HomeScreen2] Initializing');
//     _fetchHomeData();
//   }
//
//   Future<void> _fetchHomeData() async {
//     print('🔍 [HomeScreen2] Fetching home data');
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final authToken = prefs.getString('authToken') ?? '';
//       var url = Uri.parse('${ApiConstants.subUrl}jobs/home');
//       var headers = {
//         'Content-Type': 'application/json',
//         'Cookie': 'authToken=$authToken',
//       };
//
//       var request = http.Request('POST', url);
//       request.headers.addAll(headers);
//
//       http.StreamedResponse response =
//           await request.send().timeout(const Duration(seconds: 10));
//
//       print('📩 [HomeScreen2] Home data response: ${response.statusCode}');
//       if (response.statusCode == 200) {
//         final String jsonString = await response.stream.bytesToString();
//         final Map<String, dynamic> data = jsonDecode(jsonString);
//         print('📦 [HomeScreen2] Home data: $data');
//
//         if (data["status"] == true) {
//           final bannersJson = data["banners"] as List? ?? [];
//           final bannerList = bannersJson
//               .map((e) => BannerModel.fromJson(e))
//               .where((banner) => banner.image.isNotEmpty)
//               .toList();
//
//           final featuredJobsJson = data["featured_jobs"] as List? ?? [];
//           final featuredJobsList =
//               featuredJobsJson.map((e) => FeaturedJob.fromJson(e)).toList();
//
//           final popularJobsJson = data["popular_jobs"] as List? ?? [];
//           final popularJobsList =
//               popularJobsJson.map((e) => PopularJob.fromJson(e)).toList();
//
//           if (!mounted) return;
//           setState(() {
//             _banners = bannerList;
//             _featuredJobs = featuredJobsList;
//             _popularJobs = popularJobsList;
//             _isLoadingBanners = false;
//             _isLoadingFeatured = false;
//             _isLoadingPopular = false;
//             print('✅ [HomeScreen2] Loaded ${bannerList.length} banners, '
//                 '${featuredJobsList.length} featured jobs, '
//                 '${popularJobsList.length} popular jobs');
//           });
//         } else {
//           print('⚠️ [HomeScreen2] Invalid home data or status false');
//           if (!mounted) return;
//           setState(() {
//             _isLoadingBanners = false;
//             _isLoadingFeatured = false;
//             _isLoadingPopular = false;
//           });
//         }
//       } else {
//         print(
//             '⚠️ [HomeScreen2] Failed to fetch home data: ${response.statusCode}');
//         if (!mounted) return;
//         setState(() {
//           _isLoadingBanners = false;
//           _isLoadingFeatured = false;
//           _isLoadingPopular = false;
//         });
//       }
//     } catch (e) {
//       print('❌ [HomeScreen2] Error fetching home data: $e');
//       if (!mounted) return;
//       setState(() {
//         _isLoadingBanners = false;
//         _isLoadingFeatured = false;
//         _isLoadingPopular = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text('Failed to load home data',
//                 style: TextStyle(fontSize: 12.4.sp))),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     ScreenUtil.init(
//       context,
//       designSize: const Size(390, 844),
//       minTextAdapt: true,
//       splitScreenMode: true,
//     );
//     print('🔍 [HomeScreen2] Rendering');
//
//     final double appBarHeight = 43.3.h;
//     final double bottomNavBarHeight = 46.9.h;
//     final double sectionHeaderHeight = 36.1.h;
//     final double sizedBoxHeight = 9.h + 9.h + 15.4.h;
//     final double knowHowBannerHeight = 126.4.h;
//     final double paddingHeight = 13.6.h * 2;
//     final double marginHeight = 36.1.h + 3.8.h;
//     final double totalFixedHeight = appBarHeight +
//         bottomNavBarHeight +
//         (sectionHeaderHeight * 2) +
//         sizedBoxHeight +
//         knowHowBannerHeight +
//         paddingHeight +
//         marginHeight;
//
//     final double availableHeight = ScreenUtil().screenHeight - totalFixedHeight;
//     final double popularJobListHeight = availableHeight * 0.35;
//     final double featuredJobListHeight = availableHeight * 0.65;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: const HomeScreenAppbar(),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.only(bottom: 2.9.h),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _sectionHeader("Popular Jobs", actionText: "See all"),
//               SizedBox(
//                 height: popularJobListHeight.clamp(171.5.h, 189.5.h),
//                 child: _isLoadingPopular
//                     ? const Center(child: PopularJobShimmer())
//                     : _popularJobs.isEmpty
//                         ? Center(
//                             child: Text("No popular jobs found",
//                                 style: TextStyle(fontSize: 12.4.sp)))
//                         : ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             padding: EdgeInsets.symmetric(horizontal: 12.6.w),
//                             itemCount: _popularJobs.length,
//                             itemBuilder: (context, index) {
//                               final job = _popularJobs[index];
//                               return PopularJobCard(
//                                 title: job.jobName,
//                                 subtitile: job.companyName,
//                                 description:
//                                     'Exciting opportunity at ${job.companyName}',
//                                 salary: "${job.salaryMin}-${job.salaryMax} LPA",
//                                 time: "Posted on ${job.postedOn}",
//                                 immageAsset: job.companyLogo,
//                                 onTap: () {
//                                   print(
//                                       '🔍 [HomeScreen2] Navigating to job detail: ${job.jobId}');
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => JobDetailPage2(
//                                         jobToken: job.jobId.toString(),
//                                         moduleId: job.jobId,
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               );
//                             },
//                           ),
//               ),
//               SizedBox(height: 13.6.h),
//               _isLoadingBanners
//                   ? const Center(child: CircularProgressIndicator())
//                   : _banners.isEmpty
//                       ? Center(
//                           child: Text("No banners available",
//                               style: TextStyle(fontSize: 12.4.sp)))
//                       : KnowHowBanner(banners: _banners),
//               SizedBox(height: 9.h),
//               _sectionHeader("Featured Opportunities"),
//               SizedBox(
//                 height: featuredJobListHeight.clamp(216.6.h, 243.7.h),
//                 child: _isLoadingFeatured
//                     ? const Center(child: PopularJobShimmer())
//                     : _featuredJobs.isEmpty
//                         ? Center(
//                             child: Text("No featured jobs found",
//                                 style: TextStyle(fontSize: 12.4.sp)))
//                         : ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             padding: EdgeInsets.symmetric(horizontal: 12.6.w),
//                             itemCount: _featuredJobs.length,
//                             itemBuilder: (context, index) {
//                               final job = _featuredJobs[index];
//                               return FeaturedJobCard(
//                                 title: job.jobName,
//                                 location: job.companyName,
//                                 salary: "${job.salaryMin}-${job.salaryMax} LPA",
//                                 applications: "87",
//                                 timeLeft: job.postedOn,
//                                 registered: "13000 Registered",
//                                 jobType: "Full time (Hybrid)",
//                                 imageAsset: job.companyLogo,
//                                 onTap: () {
//                                   print(
//                                       '🔍 [HomeScreen2] Navigating to job detail: ${job.jobId}');
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => JobDetailPage2(
//                                         jobToken: job.jobId.toString(),
//                                         moduleId: job.jobId,
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               );
//                             },
//                           ),
//               ),
//               SizedBox(height: 15.4.h),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: CustomBottomNavBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//       ),
//     );
//   }
//
//   Widget _sectionHeader(String title, {String? actionText}) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 12.6.w, vertical: 13.6.h),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 14.4.sp,
//               fontWeight: FontWeight.w600,
//               color: const Color(0xFF003840),
//             ),
//           ),
//           if (actionText != null)
//             Text(
//               actionText,
//               style: TextStyle(
//                 fontSize: 10.8.sp,
//                 color: Colors.black87,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
