import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../Utilities/MyAccount_Get_Post/AccountProgress_Api.dart';

class ProfileCompletionBar extends StatefulWidget {
  const ProfileCompletionBar({super.key});

  @override
  State<ProfileCompletionBar> createState() => _ProfileCompletionBarState();
}

class _ProfileCompletionBarState extends State<ProfileCompletionBar> {
  String? percentage;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchProfileCompletion();
  }

  Future<void> fetchProfileCompletion() async {
    try {
      final result = await ProfileCompletionApi.fetchProfileCompletion();
      if (mounted) {
        setState(() {
          if (result != null) {
            percentage = result.setupPercentage;
            print("📥 Assigned percentage = $percentage");
            errorMessage = null;
          } else {
            errorMessage = 'Failed to load profile completion data.';
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error fetching profile completion: $e';
        });
      }
      print("⚠️ Exception in fetchProfileCompletion: $e");
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

    if (isLoading || percentage == null) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14.h, width: 160.w, color: Colors.white),
            SizedBox(height: 7.h),
            Container(height: 8.h, width: double.infinity, color: Colors.white),
          ],
        ),
      );
    }
    final parsed = double.tryParse(percentage ?? '') ?? 0.0;
    final clampedPercent = parsed.clamp(0.0, 100.0);
    final isLow = clampedPercent < 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Profile Completion Status",
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF005E6A),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "${clampedPercent.toInt()}%",
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: isLow ? Colors.red : const Color(0xFF027D92),
              ),
            ),
          ],
        ),
        SizedBox(height: 7.h),
        LinearPercentIndicator(
          animation: true,
          animationDuration: 500,
          lineHeight: 8.h,
          percent: clampedPercent / 100,
          backgroundColor: Colors.grey.shade300,
          progressColor: isLow ? Colors.red : null,
          linearGradient: isLow
              ? null
              : const LinearGradient(
            colors: [Color(0xFF027D92), Color(0xFF6ED4F9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barRadius: Radius.circular(8.r),
        ),
      ],
    );
  }
}