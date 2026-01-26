import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Pages/Notification_icon_Badge.dart';

class HomeScreenAppbar extends StatelessWidget implements PreferredSizeWidget {
  const HomeScreenAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(17.w, 17.h, 17.w, 0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  style: TextStyle(fontSize: 13.sp),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search,
                        size: 18.sp, color: Colors.black),
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      color: Colors.black,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            const NotificationBell(),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}
