import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Pages/Notification_icon_Badge.dart';

class AccountAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AccountAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 14.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circleIconButton(
              icon: Icons.arrow_back,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Text(
              "My Account",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF003840),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const NotificationBell(),
                // _circleIconButton(
                //   icon: Icons.notifications_none_outlined,
                //   onTap: () {},
                // ),
                // Positioned(
                //   top: -1.h,
                //   right: -1.w,
                //   child: Container(
                //     width: 8.w,
                //     height: 8.h,
                //     decoration: const BoxDecoration(
                //       color: Colors.red,
                //       shape: BoxShape.circle,
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 35.w,
        height: 35.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBCD8DB)),
        ),
        child: Icon(icon, color: const Color(0xFF003840), size: 22.w),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(80.h);
}