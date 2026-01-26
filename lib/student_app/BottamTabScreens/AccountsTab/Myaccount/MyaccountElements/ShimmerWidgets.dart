import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class PersonalDetailsShimmer extends StatelessWidget {
  const PersonalDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.only(top: 7.h),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBCD8DB)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(6, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 5.h),
            child: Row(
              children: [
                Container(
                  width: 22.w,
                  height: 22.h,
                  color: Colors.grey[300],
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 12.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class EducationShimmer extends StatelessWidget {
  const EducationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Column(
      children: List.generate(2, (index) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          margin: EdgeInsets.only(top: 7.h),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBCD8DB)),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 35.w,
                  height: 35.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14.h,
                        width: 120.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 5.h),
                      ),
                      Container(
                        height: 12.h,
                        width: 180.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 5.h),
                      ),
                      Container(
                        height: 12.h,
                        width: 140.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 5.h),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 7.w),
              Column(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Icon(Icons.edit, color: Colors.grey, size: 22.w),
                  ),
                  SizedBox(height: 3.h),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Icon(Icons.delete_outline, color: Colors.grey, size: 22.w),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

class ProjectShimmer extends StatelessWidget {
  const ProjectShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Column(
      children: List.generate(2, (index) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          margin: EdgeInsets.only(top: 7.h),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBCD8DB)),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  width: 32.w,
                  height: 32.h,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18.h,
                        width: 70.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        margin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Container(
                        height: 12.h,
                        width: 120.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Container(
                        height: 12.h,
                        width: 180.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Container(
                        height: 12.h,
                        width: 140.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Container(
                        height: 11.h,
                        width: 160.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Container(
                        height: 11.h,
                        width: 200.w,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 7.w),
              Column(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Icon(Icons.edit, color: Colors.grey, size: 22.w),
                  ),
                  SizedBox(height: 3.h),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Icon(Icons.delete_outline, color: Colors.grey, size: 22.w),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SkillsShimmer extends StatelessWidget {
  const SkillsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Column(
      children: List.generate(2, (index) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          margin: EdgeInsets.only(top: 7.h),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBCD8DB)),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  width: 32.w,
                  height: 32.h,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18.h,
                        width: 70.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        margin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Container(
                        height: 12.h,
                        width: 120.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Container(
                        height: 12.h,
                        width: 180.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Container(
                        height: 12.h,
                        width: 140.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Container(
                        height: 11.h,
                        width: 160.w,
                        color: Colors.white,
                        margin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Container(
                        height: 11.h,
                        width: 200.w,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 7.w),
              Column(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Icon(Icons.edit, color: Colors.grey, size: 22.w),
                  ),
                  SizedBox(height: 3.h),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Icon(Icons.delete_outline, color: Colors.grey, size: 22.w),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}