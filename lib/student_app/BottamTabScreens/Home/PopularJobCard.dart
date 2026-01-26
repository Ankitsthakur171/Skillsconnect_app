import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PopularJobCard extends StatelessWidget {
  final String title;
  final String subtitile;
  final String description;
  final String salary;
  final String time;
  final String immageAsset;
  final VoidCallback? onTap;

  const PopularJobCard({
    super.key,
    required this.title,
    required this.subtitile,
    required this.description,
    required this.salary,
    required this.time,
    required this.immageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.8.r),
      child: Card(
        margin: EdgeInsets.only(right: 10.8.w, bottom: 7.2.h),
        elevation: 1.8,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.8.r),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Container(
          width: 270.8.w,
          padding: EdgeInsets.symmetric(horizontal: 14.4.w, vertical: 10.8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7.2.r),
                    child: Image.network(
                      immageAsset,
                      width: 36.1.w,
                      height: 36.1.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36.1.w,
                        height: 36.1.h,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported,
                            size: 18.1.sp, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF1A73E8),
                            fontWeight: FontWeight.w600,
                            fontSize: 14.4.sp,
                          ),
                        ),
                        SizedBox(height: 3.6.h),
                        Text(
                          subtitile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12.6.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.8.h),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.7.sp,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 10.8.h),
              Divider(thickness: 0.7, color: Colors.grey.withOpacity(0.4)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      salary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF34A853),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Flexible(
                    child: Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10.8.sp,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
