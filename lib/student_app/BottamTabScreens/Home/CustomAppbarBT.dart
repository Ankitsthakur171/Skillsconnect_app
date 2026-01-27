import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Pages/Notification_icon_Badge.dart';
import '../../Utilities/ApiConstants.dart';

class HomeScreenAppbar extends StatefulWidget implements PreferredSizeWidget {
  const HomeScreenAppbar({super.key});

  @override
  State<HomeScreenAppbar> createState() => _HomeScreenAppbarState();

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}

class _HomeScreenAppbarState extends State<HomeScreenAppbar> {
  late final Future<String> _collegeFuture;

  @override
  void initState() {
    super.initState();
    _collegeFuture = _loadCollegeName();
  }

  Future<String> _loadCollegeName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final uri = Uri.parse(ApiConstantsStu.personalDetailApi);
      final resp = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      });

      if (resp.statusCode != 200) return '';

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final details = decoded['personalDetails'];
      if (details is List && details.isNotEmpty) {
        final first = details.first;
        if (first is Map<String, dynamic>) {
          final name = (first['college_name'] ?? first['collage_name'] ?? '') as String;
          return name;
        }
      }
    } catch (e) {
      // swallow and fall back to placeholder
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(17.w, 17.h, 17.w, 0),
        child: Row(
          children: [
            Expanded(
              child: FutureBuilder<String>(
                future: _collegeFuture,
                builder: (context, snapshot) {
                  final text = (snapshot.data ?? '').trim();
                  final display = text.isEmpty ? 'Your college' : text;
                  return Row(
                    children: [
                      Icon(Icons.school, size: 18.sp, color: Colors.black87),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
