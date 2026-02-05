import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Pages/Notification_icon_Badge.dart';
import '../../../../TPO/Screens/tpo_update_passwordscreen.dart';
import 'Contact_Us.dart';
import 'Terms_And_Conditions.dart';
import 'Verify_Delete_Account.dart';
import '../../../Utilities/delete_api.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsFile extends StatefulWidget {
  const SettingsFile({super.key});

  @override
  State<SettingsFile> createState() => _SettingsFileState();
}

class _SettingsFileState extends State<SettingsFile> {
  bool _loading = false;

  Widget _settingsTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final accent = const Color(0xFF005E6A);
    final borderColor = const Color(0xFFD0DDDC);

    return Material(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        onTap: onTap,
        child: Container(
          height: 58.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: borderColor.withOpacity(0.9), width: 1.6),
          ),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: borderColor.withOpacity(0.9), width: 1.4),
                ),
                child: Center(
                  child: Icon(icon, size: 20.w, color: accent),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF22383A),
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: const Color(0xFFB7D4D6), size: 20.w),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationAndTriggerStep1() async {
    final teal = const Color(0xFF005E6A);
    final red = Colors.red.shade400;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          contentPadding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 8.h),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: teal, width: 3),
                ),
                child: Icon(Icons.help_outline, color: teal, size: 30.w),
              ),
              SizedBox(height: 12.h),
              Text(
                'Confirmation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                'Are you sure you want to delete your account?\n\nYou will receive an OTP to verify this action.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsPadding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: Text('No'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: Text('Yes'),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final result = await DeleteApi.step1Request();
      debugPrint('SettingsFile: step1 result -> $result');

      final status = result['status'] as int? ?? 0;
      final body = result['body'];

      if (status >= 200 && status < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('OTP sent. Please check your phone / email.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        if (!mounted) return;

        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VerifyDeletionPage()),
        );
      } else {
        String message = body is Map
            ? (body['message'] ?? body['msg'] ?? body.toString()).toString()
            : body.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to request OTP: $message'),
              backgroundColor: Colors.red.shade600),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Request timed out. Try again.'),
            backgroundColor: Colors.red.shade600),
      );
    } catch (e) {
      debugPrint(
          'SettingsFile._showDeleteConfirmationAndTriggerStep1 error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error requesting OTP: $e'),
            backgroundColor: Colors.red.shade600),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF005E6A);
    final borderColor = const Color(0xFFD0DDDC);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: const Color(0xFF003840), size: 22.w),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: const Color(0xFF003840),
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12.w),
            height: 40.h,
            width: 40.h,
            alignment: Alignment.center,
            child: const NotificationBell(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            children: [
              _settingsTile(
                label: 'Contact Us',
                icon: Icons.support_agent_outlined,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactUsPage()),
                  );
                  if (mounted) setState(() {});
                },
              ),
              SizedBox(height: 16.h),
              _settingsTile(
                label: 'Terms & Conditions',
                icon: Icons.description_outlined,
                onTap: () async {
                  final Uri url =
                  Uri.parse('https://skillsconnect.in/terms-conditions');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Could not open Terms & Conditions')),
                    );
                  }
                },
              ),
              SizedBox(height: 16.h),
              _settingsTile(
                label: 'Change Password',
                icon: Icons.lock_outline,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TpoUpdatePasswordScreen()),
                  );
                  if (mounted) setState(() {});
                },
              ),
              SizedBox(height: 16.h),
              _settingsTile(
                label: 'Delete Account',
                icon: Icons.delete_outline_outlined,
                onTap:
                _loading ? () {} : _showDeleteConfirmationAndTriggerStep1,
              ),
              SizedBox(height: 12.h),
              if (_loading) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
