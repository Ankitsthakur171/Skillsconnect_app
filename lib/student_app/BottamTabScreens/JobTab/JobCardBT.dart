import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class JobCardBT extends StatelessWidget {
  final int jobId;
  final int recordId;
  final String jobToken;
  final String jobTitle;
  final String jobType;
  final String company;
  final String location;
  final String salary;
  final String postTime;
  final String expiry;
  final String? endDate;

  final List<String> tags;
  final String? logoUrl;
  final bool isApplied;

  final void Function({
    required int jobId,
    required int recordId,
    required String jobToken,
  })? onTap;

  const JobCardBT({
    super.key,
    required this.jobId,
    required this.recordId,
    required this.jobType,
    required this.jobToken,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.salary,
    required this.postTime,
    required this.expiry,
    required this.tags,
    this.endDate,
    this.logoUrl,
    this.onTap,
    this.isApplied = false,
  });

  /// Calculate and return the time left display string
  String _getTimeLeftDisplay() {
    final raw = (endDate != null && endDate!.isNotEmpty) ? endDate! : expiry;
    return _formatDateShort(raw);
  }

  String _formatDateShort(String raw) {
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
    } catch (e) {
      return raw;
    }
  }

  /// Check if the job is expired
  bool _isExpired() {
    if (endDate != null && endDate!.isNotEmpty) {
      try {
        final expireTime = DateTime.parse(endDate!);
        final now = DateTime.now();
        return expireTime.isBefore(now);
      } catch (e) {
        print('[JobCardBT] Error parsing endDate for expiry check: $e');
      }
    }
    // Check if expiry text contains "Expired"
    return expiry.toLowerCase().contains('expired');
  }

  @override
  Widget build(BuildContext context) {
    final hasTags = tags.isNotEmpty;
    final safeSalary =
        (salary.isEmpty || salary.toLowerCase() == 'n/a') ? 'N/A' : salary;
    final postedDisplay = _formatDateShort(postTime);
    final endDisplay = _getTimeLeftDisplay();
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

    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap == null
          ? null
          : () => onTap!(
                jobId: jobId,
                recordId: recordId,
                jobToken: jobToken,
              ),
      child: Container(
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
                  // Row 1: Logo - Name - CTC
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
                          safeSalary,
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
                  // Row 3: Location
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
                        ...tags.take(3).map((tag) {
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
                        if (tags.length > 3)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF005E6A).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '+ ${tags.length - 3} more',
                              style: TextStyle(
                                color: const Color(0xFF005E6A),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
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
                  SizedBox(width: 8.w),
                  _buildApplyButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    final expired = _isExpired();
    
    final String buttonText;
    final Gradient? gradient;
    final Color? backgroundColor;
    final Color textColor;
    final IconData? icon;
    
    if (expired) {
      buttonText = 'Expired';
      gradient = null;
      backgroundColor = const Color(0xFFD03C2D);
      textColor = Colors.white;
      icon = Icons.cancel_outlined;
    } else if (isApplied) {
      buttonText = 'Applied';
      gradient = null;
      backgroundColor = const Color(0xFF9E9E9E);
      textColor = Colors.white;
      icon = Icons.check_circle_outline;
    } else {
      buttonText = 'Apply';
      gradient = const LinearGradient(
        colors: [Color(0xFF00C853), Color(0xFF4CAF50)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      backgroundColor = null;
      textColor = Colors.white;
      icon = Icons.arrow_forward_rounded;
    }
    
    return InkWell(
      onTap: (expired || isApplied)
          ? null
          : () {
              if (onTap != null) {
                onTap!(
                  jobId: jobId,
                  recordId: recordId,
                  jobToken: jobToken,
                );
              }
            },
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 18.w,
          vertical: 10.h,
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: (expired || isApplied)
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF00C853).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              buttonText,
              style: TextStyle(
                color: textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            if (icon != null) ...[
              SizedBox(width: 6.w),
              Icon(
                icon,
                color: textColor,
                size: 16.sp,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
