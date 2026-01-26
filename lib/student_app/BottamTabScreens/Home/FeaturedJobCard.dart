import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class FeaturedJobCard extends StatelessWidget {
  final String title;
  final String location;
  final String salary;
  final String applications;
  final String timeLeft;
  final String registered;
  final String jobType;
  final String imageAsset;
  final VoidCallback? onTap;

  const FeaturedJobCard({
    super.key,
    required this.title,
    required this.location,
    required this.salary,
    required this.applications,
    required this.timeLeft,
    required this.registered,
    required this.jobType,
    required this.imageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = 189.5.w;
    final imageHeight = 99.3.h;
    final iconSize = 16.2.w;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 252.7.h,
        maxHeight: 297.8.h,
      ),
      child: Card(
        margin: EdgeInsets.only(right: 11.7.w, bottom: 1.8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.3.r),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.4),
            width: 1,
          ),
        ),
        elevation: 3.1,
        color: Colors.white,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              print('🔍 [FeaturedJobCard] Tapped card: $title');
              onTap!();
            }
          },
          borderRadius: BorderRadius.circular(6.3.r),
          child: Container(
            width: cardWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.3.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6.3.r)),
                  child: imageAsset.startsWith('http')
                      ? _buildNetworkImage(imageAsset, imageHeight)
                      : Image.asset(
                    imageAsset,
                    width: double.infinity,
                    height: imageHeight,
                    fit: BoxFit.contain,
                  ),
                ),

                /// FIX APPLIED HERE: scrollable content to avoid overflow
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 9.9.w, vertical: 8.1.h),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5.sp,
                              color: const Color(0xFF003840),
                            ),
                          ),
                          SizedBox(height: 2.7.h),

                          Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.8.sp,
                              color: const Color(0xFF003840),
                            ),
                          ),
                          SizedBox(height: 6.3.h),

                          Text(
                            "$salary • $applications Applications",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.8.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF003840),
                            ),
                          ),
                          SizedBox(height: 6.3.h),

                          Row(
                            children: [
                              Icon(Icons.group_outlined, size: iconSize, color: Colors.grey[600]),
                              SizedBox(width: 2.7.w),
                              Expanded(
                                child: Text(
                                  registered,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.8.sp, color: const Color(0xFF003840)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.3.h),

                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: iconSize, color: Colors.grey[600]),
                              SizedBox(width: 2.7.w),
                              Expanded(
                                child: Text(
                                  timeLeft,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.8.sp, color: const Color(0xFF003840)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.3.h),

                          Row(
                            children: [
                              Icon(Icons.work_outline, size: iconSize, color: Colors.grey[600]),
                              SizedBox(width: 2.7.w),
                              Expanded(
                                child: Text(
                                  jobType,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.8.sp, color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url, double height) {
    if (url.isEmpty || !Uri.parse(url).isAbsolute) {
      return Container(
        height: height,
        color: Colors.grey[200],
        child: Icon(Icons.broken_image, size: 16.2.w, color: Colors.red),
      );
    }

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: height,
            width: double.infinity,
            color: Colors.white,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          color: Colors.grey[200],
          child: Icon(Icons.broken_image, size: 16.2.w, color: Colors.red),
        );
      },
    );
  }
}
