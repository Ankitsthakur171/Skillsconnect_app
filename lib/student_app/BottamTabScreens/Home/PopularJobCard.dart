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
  final VoidCallback? onApply;
  final bool isEligible;

  const PopularJobCard({
    super.key,
    required this.title,
    required this.subtitile,
    required this.description,
    required this.salary,
    required this.time,
    required this.immageAsset,
    this.onTap,
    this.onApply,
    this.isEligible = true,
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
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7.r),
                    child: Image.network(
                      immageAsset,
                      width: 34.w,
                      height: 34.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 34.w,
                        height: 34.h,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported,
                            size: 17.sp, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
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
                            fontSize: 13.5.sp,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          subtitile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 9.h),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[700],
                  height: 1.2,
                ),
              ),
              SizedBox(height: 7.h),
              Divider(thickness: 0.6, color: Colors.grey.withOpacity(0.35)),
              SizedBox(height: 5.h),
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
                        fontSize: 12.sp,
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
                        fontSize: 9.5.sp,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7.h),
              SizedBox(
                width: double.infinity,
                height: 34.h,
                child: ElevatedButton(
                  onPressed: isEligible ? onApply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEligible
                        ? const Color(0xFF0D9488)
                        : Colors.grey[400],
                    disabledBackgroundColor: Colors.grey[400],
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                  ),
                  child: Text(
                    isEligible ? 'Apply' : 'Not Eligible',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
