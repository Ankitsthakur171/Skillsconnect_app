import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Pages/Notification_icon_Badge.dart';

class HomeScreenAppbar extends StatefulWidget implements PreferredSizeWidget {
  const HomeScreenAppbar({super.key});

  @override
  State<HomeScreenAppbar> createState() => _HomeScreenAppbarState();

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}

class _HomeScreenAppbarState extends State<HomeScreenAppbar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(17.w, 17.h, 17.w, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Dashboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20.sp,
                  color: const Color.fromARGB(255, 8, 104, 96),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            const NotificationBell(),
          ],
        ),
      ),
    );
  }
}
