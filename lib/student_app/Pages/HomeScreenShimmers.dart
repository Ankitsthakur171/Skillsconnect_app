import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class PopularJobShimmer extends StatelessWidget {
  const PopularJobShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        itemCount: 3, // number of shimmer cards to show
        itemBuilder: (context, index) {
          return Container(
            width: 260.w, // 👈 match PopularJobCard width
            margin: EdgeInsets.only(right: 12.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // logo + title row
                Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12.h,
                          width: 120.w,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          height: 10.h,
                          width: 80.w,
                          color: Colors.grey,
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 10.h),
                // description
                Container(
                  height: 10.h,
                  width: double.infinity,
                  color: Colors.grey,
                ),
                SizedBox(height: 6.h),
                Container(
                  height: 10.h,
                  width: double.infinity,
                  color: Colors.grey,
                ),
                SizedBox(height: 12.h),
                // salary + posted
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 12.h,
                      width: 80.w,
                      color: Colors.grey,
                    ),
                    Container(
                      height: 12.h,
                      width: 70.w,
                      color: Colors.grey,
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}


class KnowHowBannerShimmer extends StatelessWidget {
  const KnowHowBannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 11.8.h),
        Container(
          height: 126.4.h,
          margin: EdgeInsets.symmetric(horizontal: 12.6.w),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9.5.r),
              ),
              width: double.infinity,
              height: 126.4.h,
            ),
          ),
        ),
        SizedBox(height: 15.4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.9.w),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 6.7.w,
                  height: 6.7.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}