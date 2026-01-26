import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  final List<String> tags;
  final String? logoUrl;

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
    // required this.endDate,
    this.logoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTags = tags.isNotEmpty;
    final safeSalary =
        (salary.isEmpty || salary.toLowerCase() == 'n/a') ? 'N/A' : salary;
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
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        // border: Border.all(
                        //   // color: const Color(0xFFBCD8DB),
                        //   width: 1,
                        // ),
                      ),
                      child: logo,
                    ),
                    SizedBox(width: 8.w),
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
                              height: 1.05,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            company,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF6F6F6F),
                            ),
                          ),
                          Text(
                            location.isNotEmpty ? location : 'NA',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF6F6F6F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      safeSalary,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: const Color(0xFF005E6A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ]),
                  SizedBox(height: 10.h),
                  if (hasTags)
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005E6A).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Text(
                            jobType,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF005E6A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: tags.map((tag) {
                                return Container(
                                  margin: EdgeInsets.only(right: 8.w),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF9FA),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: const Color(0xFF005E6A)
                                          .withOpacity(0.25),
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
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No tags',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF827B7B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(
                      "Posted - ",
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF003840),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      postTime,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF003840),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEDDDC),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFDAA5A5)),
                    ),
                    child: Text(
                      expiry,
                      style: TextStyle(
                        color: const Color(0xFFD03C2D),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
