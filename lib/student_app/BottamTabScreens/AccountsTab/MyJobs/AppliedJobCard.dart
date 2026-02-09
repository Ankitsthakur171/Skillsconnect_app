import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class AppliedJobCardBT extends StatelessWidget {
  final String jobTitle;
  final String company;
  final String location;
  final String salary;
  final String postTime;
  final String expiry;
  final String? endDate;
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
    this.endDate,
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

    String formatDateShort(String raw) {
      final value = raw.trim();
      if (value.isEmpty) return 'N/A';
      try {
        if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(value)) {
          final parts = value.split('-');
          final parsed = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          return DateFormat('dd MMM yyyy').format(parsed);
        }
        final parsed = DateTime.parse(value);
        return DateFormat('dd MMM yyyy').format(parsed);
      } catch (_) {
        return raw;
      }
    }

    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    print(
        '🔍 [AppliedJobCardBT] Rendering card for job: $jobTitle, company: $company');

    final filteredTags = tags.where((t) => t.trim().isNotEmpty).toList();
    final hasTags = filteredTags.isNotEmpty;
    final safeSalary =
      (salary.isEmpty || salary.toLowerCase() == 'n/a') ? '' : salary;
    final postedDisplay = formatDateShort(postTime);
    final endDisplay = formatDateShort((endDate != null && endDate!.isNotEmpty)
      ? endDate!
      : expiry);

    Widget logo = Image.asset(
      "assets/google.png",
      width: 34.w,
      height: 34.w,
      fit: BoxFit.contain,
    );
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      logo = Image.network(
        logoUrl!,
        width: 45.w,
        height: 45.w,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          "assets/google.png",
          width: 34.w,
          height: 34.w,
          fit: BoxFit.contain,
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF6F7),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFBCD8DB), width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005E6A).withOpacity(0.06),
            blurRadius: 12,
            spreadRadius: 1,
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: logo,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      jobTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                        color: const Color(0xFF003840),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isCtcPaid(safeSalary) ? '$safeSalary LPA' : 'Unpaid',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF005E6A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        jobType,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF6F6F6F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ]),
                SizedBox(height: 3.h),
                Text(
                  company,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF005E6A),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  location.isNotEmpty ? location : 'No Location Specified',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    color: const Color(0xFF005E6A),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasTags) ...[
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      ...filteredTags.take(3).map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF9FA),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color:
                                  const Color(0xFF005E6A).withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: const Color(0xFF005E6A),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      if (filteredTags.length > 3)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005E6A).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '+ ${filteredTags.length - 3} more',
                            style: TextStyle(
                              color: const Color(0xFF005E6A),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  SizedBox(height: 8.h),
                  Text(
                    'No tags',
                    style: TextStyle(
                      color: const Color(0xFF6F6F6F),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Posted on - ",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF6F6F6F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            postedDisplay,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF003840),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Text(
                            "End date - ",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF6F6F6F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            endDisplay,
                            style: TextStyle(
                              fontSize: 12.sp,
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
