import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppliedJobCardBT extends StatelessWidget {
  final String jobTitle;
  final String company;
  final String location;
  final String salary;
  final String postTime;
  final String expiry;
  final List<String> tags;
  final String? logoUrl;
  final String jobType;

  const AppliedJobCardBT({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.salary,
    required this.postTime,
    required this.expiry,
    required this.tags,
    required this.jobType,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    bool isCtcPaid(String raw) {
      if (raw.trim().isEmpty) return false;

      final digits = RegExp(r'\d+')
          .allMatches(raw)
          .map((m) => m.group(0))
          .where((s) => s != null)
          .toList();

      if (digits.isEmpty) return false;

      for (final d in digits) {
        final n = int.tryParse(d ?? '0') ?? 0;
        if (n > 0) return true;
      }
      return false;
    }

    ScreenUtil.init(context,
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true);

    print(
        '🔍 [AppliedJobCardBT] Rendering card for job: $jobTitle, company: $company');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
      padding: EdgeInsets.all(8.w),

      decoration: BoxDecoration(
        color: const Color(0xFFEBF6F7),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFBCD8DB), width: 1.4.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005E6A).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                            color: const Color(0xFF005E6A), width: 1.w),
                      ),
                      child: logoUrl != null && logoUrl!.isNotEmpty
                          ? Image.network(
                        logoUrl!,
                        width: 35.w,
                        height: 35.h,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          "assets/google.png",
                          width: 35.w,
                          height: 35.h,
                        ),
                      )
                          : Image.asset(
                        "assets/google.png",
                        width: 35.w,
                        height: 35.h,
                      ),
                    ),

                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16.sp,
                              color: const Color(0xFF003840),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 3.h),
                          Text(
                            company,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF827B7B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: 3.h),
                          Text(
                            location.isNotEmpty ? location : 'NA',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF827B7B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 6.w),
                    ConstrainedBox(
                      constraints:
                      BoxConstraints(minWidth: 44.w, maxWidth: 90.w),
                      child: Text(
                        isCtcPaid(salary) ? '$salary LPA' : 'Unpaid',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF005E6A),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (jobType.trim().isNotEmpty) _jobTypeTag(jobType),
                      SizedBox(width: 8.w),
                      Row(
                        children: tags
                            .where((t) => t.trim().isNotEmpty)
                            .map((t) => _skillTag(t))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Posted -",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF003840),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      postTime,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF003840),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobTypeTag(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF005E6A),
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _skillTag(String label) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F9),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFBCD8DB)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF003840),
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
