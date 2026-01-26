import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Model/InterviewScreen_Model.dart';
import '../../Pages/BlinkAnimatedStatus.dart';

class InterviewCard extends StatelessWidget {
  final InterviewModel model;
  final VoidCallback onJoinTap;

  const InterviewCard({
    super.key,
    required this.model,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    final String moderatorText = model.moderator.isNotEmpty
        ? (model.moderator[0].fullName?.isNotEmpty == true
        ? model.moderator[0].fullName!
        : model.moderator[0].meetingName)
        : '—';

    final bool isOffice = model.meetingMode.toLowerCase().contains('office');

    return Container(
      margin: EdgeInsets.all(10.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF6F7),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFBCD8DB), width: 1.w),

        /// ⭐ Floating shadow
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

          /// Title
          Text(
            model.jobTitle,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16.sp,
              color: const Color(0xFF003840),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 10.h),

          /// ⭐ Inner Card
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

                /// COMPANY + STATUS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.maps_home_work_outlined,
                              size: 16.w, color: const Color(0xFF003840)),
                          SizedBox(width: 7.w),
                          Expanded(
                            child: Text(
                              model.company,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF003840),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// ACTIVE / INACTIVE badge
                    LiveSlidingText(
                      status: model.isActive ? 'Active' : 'Inactive',
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                /// DATE + TIME
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size: 16.w, color: const Color(0xFF003840)),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        model.date,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF003840),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Icon(Icons.access_time_outlined,
                        size: 16.w, color: const Color(0xFF003840)),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        "${model.startTime} - ${model.endTime}",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF003840),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                /// MODERATOR + MODE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline_outlined,
                            size: 16.w, color: const Color(0xFF003840)),
                        SizedBox(width: 7.w),
                        Text(
                          moderatorText,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF003840),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      model.meetingMode,
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

          SizedBox(height: 12.h),

          /// JOIN BUTTON
          Center(
            child: SizedBox(
              width: 150.w,
              child: ElevatedButton.icon(
                onPressed: onJoinTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005E6A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                icon: Text(
                  isOffice ? "View Now" : "Join Now",
                  style: TextStyle(fontSize: 14.sp, color: Colors.white),
                ),
                label: Icon(Icons.arrow_forward,
                    color: Colors.white, size: 18.w),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
