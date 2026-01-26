import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../Utilities/auth/changePasswordApi.dart';
import 'NewpasswordFiled.dart';

class OtpAndPasswordReset extends StatefulWidget {
  final String email;
  final String otp;
  const OtpAndPasswordReset({super.key, required this.email, required this.otp});

  @override
  State<OtpAndPasswordReset> createState() => _OtpAndPasswordResetState();
}

class _OtpAndPasswordResetState extends State<OtpAndPasswordReset> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  static const Color _primaryColor = Color(0xFF003840);

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(
      String msg, {
        bool success = false,
        int seconds = 3,
        bool useRootMessenger = true,
      }) {
    final BuildContext targetContext = useRootMessenger
        ? Navigator.of(context, rootNavigator: true).context
        : context;

    final messenger = ScaffoldMessenger.of(targetContext);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(fontSize: 12.sp)),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: seconds),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _looksLikeSameAsOldMessage(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('same') || lower.contains('old') || lower.contains('previous');
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnack("Both fields are required");
      return;
    }

    if (newPassword.length < 6) {
      _showSnack("Password must be at least 6 characters");
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnack("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await PasswordServices.resetPassword(
        email: widget.email,
        otp: widget.otp,
        password: newPassword,
      );

      setState(() => _isLoading = false);

      final bool success = result['success'] == true;
      final String message = result['message']?.toString() ?? (success ? "Password reset" : "Reset failed");

      if (success) {
        _showSnack(message, success: true);
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        return;
      } else {
        if (_looksLikeSameAsOldMessage(message)) {
          _showSnack("New password cannot be same as old password");
        } else {
          _showSnack(message);
        }
        return;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Error: $e");
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Scaffold(
      backgroundColor: _primaryColor,
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20.h),
                        SvgPicture.asset(
                          "assets/Logo.svg",
                          width: 300.w,
                          height: 70.h,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Enter New Password",
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(height: 35.h),
                    Text("New Password", style: TextStyle(fontSize: 14.sp)),
                    SizedBox(height: 7.h),
                    NewPasswordField(controller: _newPasswordController),
                    SizedBox(height: 17.h),
                    Text("Confirm Password", style: TextStyle(fontSize: 14.sp)),
                    SizedBox(height: 7.h),
                    NewPasswordField(controller: _confirmPasswordController),
                    SizedBox(height: 35.h),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 45.h,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _resetPassword,
                          label: Text(
                            _isLoading ? "Please wait..." : "Reset Password",
                            style: TextStyle(color: Colors.white, fontSize: 16.sp),
                          ),
                          icon: Icon(Icons.lock_reset, color: Colors.white, size: 20.w),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
