import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../Model/Applied_Jobs_Model.dart';
import '../../../Pages/noInternetPage_jobs.dart';
import '../../../Utilities/AppliedJobs_Api.dart';
import '../../JobTab/JobdetailPage/JobdetailpageBT.dart';
import 'AppliedJobCard.dart';

class AppliedJobsPage extends StatefulWidget {
  const AppliedJobsPage({super.key});

  @override
  State<AppliedJobsPage> createState() => _AppliedJobsPageState();
}

class _AppliedJobsPageState extends State<AppliedJobsPage> {
  List<AppliedJobModel> _jobs = [];
  bool _isLoading = true;
  bool _hasInternet = true;
  bool _showShimmer = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _showShimmer = false);
    });
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _showShimmer = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _showShimmer = false);
    });

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException("No Internet");
      }

      final jobs = await AppliedJobsApi.fetchAppliedJobs();

      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _isLoading = false;
        _hasInternet = true;
      });
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasInternet = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasInternet = false;
      });
    }
  }

  Future<void> _onRetry() async {
    await _fetchJobs();
  }

  Future<void> _onRefresh() async {
    await _fetchJobs();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Applied Jobs",
          style: TextStyle(
            color: const Color(0xFF003840),
            fontWeight: FontWeight.bold,
            fontSize: 16.7.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: const Color(0xFF003840), size: 18.6.w),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF003840),
        backgroundColor: Colors.white,
        child: _showShimmer || _isLoading
            ? _buildShimmerList()
            : !_hasInternet
            ? NoInternetPage(onRetry: _onRetry)
            : _jobs.isEmpty
            ? const Center(
            child: Text("No jobs applied yet",
                style: TextStyle(color: Colors.grey)))
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _jobs.length,
          padding:
          EdgeInsets.symmetric(horizontal: 13.w, vertical: 6.5.h),
          itemBuilder: (context, index) {
            final job = _jobs[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailPage2(
                        jobToken: job.token, moduleId: job.jobId, isAlreadyApplied: true),
                  ),
                );
              },
              child: AppliedJobCardBT(
                jobTitle: job.title,
                company: job.companyName,
                location: job.location,
                salary: job.salary,
                postTime: job.postTime,
                expiry: job.expiry,
                tags: job.tags,
                logoUrl: job.companyLogo,
                jobType: job.jobType,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 6.5.h),
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.7.w, vertical: 7.4.h),
      padding: EdgeInsets.all(6.5.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.5.r),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(9.3.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9.3.r),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32.6.w,
                        height: 32.6.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.5.r),
                        ),
                      ),
                      SizedBox(width: 9.3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14.9.h,
                              width: 93.w,
                              color: Colors.white,
                            ),
                            SizedBox(height: 4.7.h),
                            Container(
                              height: 11.2.h,
                              width: 148.8.w,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.5.w),
                      Container(
                        height: 13.h,
                        width: 41.9.w,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  SizedBox(height: 9.3.h),
                  Wrap(
                    spacing: 6.5.w,
                    runSpacing: 6.5.h,
                    children: List.generate(3, (index) {
                      return Container(
                        height: 16.7.h,
                        width: 51.2.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.7.r),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 7.4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.5.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 11.2.h,
                    width: 65.1.w,
                    color: Colors.white,
                  ),
                  Container(
                    height: 11.2.h,
                    width: 51.2.w,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
