import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../Utilities/auth/VerifyOtp.dart';
import '../Utilities/auth/forgotpasswordApi.dart';
import 'Otpfiled.dart';
import 'otpandresetpasswordpage.dart';


class ForgotpasswordPage extends StatefulWidget {
  const ForgotpasswordPage({super.key});

  @override
  State<ForgotpasswordPage> createState() => _ForgotpasswordPageState();
}

class _ForgotpasswordPageState extends State<ForgotpasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final ForgotPasswordService _forgotServices = ForgotPasswordService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _hasPopped = false;

  final Map<String, DateTime> _lastOtpSent = {};

  static const Duration _otpCooldown = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _hasPopped = false;
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    _scroll_controller_guard(_scrollController).dispose();
    super.dispose();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _showSnack(String message, {bool success = false, int seconds = 3}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 12.sp)),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: seconds),
      ),
    );
  }

  int _secondsUntilResend(String username) {
    final last = _lastOtpSent[username];
    if (last == null) return 0;
    final diff = DateTime.now().difference(last);
    final remaining = _otpCooldown - diff;
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  bool _canResend(String username) {
    return _secondsUntilResend(username) == 0;
  }

  Future<void> _recordOtpSent(String username) async {
    _lastOtpSent[username] = DateTime.now();
  }

  Future<void> _handleSendOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack("Enter a valid email address");
      return;
    }

    if (!await _hasInternetConnection()) {
      _showSnack("No internet available");
      return;
    }

    if (!_canResend(email)) {
      final sec = _secondsUntilResend(email);
      _showSnack("You can resend OTP in ${sec}s");
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await _forgotServices.sendResetOtp(email);
      setState(() => _isLoading = false);

      final bool success = result['success'] == true ||
          (result['status'] is int && result['status'] == 200);

      _showSnack(
        result['message']?.toString() ?? (success ? "OTP has been sent" : "Failed to send OTP"),
        success: success,
      );

      if (success) {
        await _recordOtpSent(email);
        // Open OTP bottom sheet after a tiny delay so user sees the snackbar
        await Future.delayed(const Duration(milliseconds: 250));
        _showOtpBottomSheet();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Error: $e");
    }
  }

  Future<void> _verifyOtp() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      _showSnack("Enter the OTP");
      return;
    }

    if (!await _hasInternetConnection()) {
      _showSnack("No internet available");
      return;
    }

    try {
      final result = await VerifyOtp(email, otp);

      final success = result['success'] == true;
      _showSnack(
        result['message']?.toString() ?? (success ? "Verified" : "Verification failed"),
        success: success,
      );

      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpAndPasswordReset(email: email, otp: otp),
          ),
        );
      }
    } catch (e) {
      _showSnack("Error: $e");
    }
  }

  void _goBack() {
    if (!_hasPopped && Navigator.of(context).canPop()) {
      _hasPopped = true;
      Navigator.of(context).pop();
    }
  }

  void _showOtpBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
                ),
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40.w,
                        height: 4.h,
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      Text(
                        "Verify OTP",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      OtpField(
                        onSubmit: (otp) => otpController.text = otp,
                        onChange: (value) => otpController.text = value,
                      ),
                      SizedBox(height: 22.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 120.w,
                            height: 42.h,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _verifyOtp,
                              icon: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18.w,
                              ),
                              label: Text(
                                "Verify",
                                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003840),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                ),
                              ),
                            ),
                          ),

                          TextButton(
                            onPressed: _isLoading ? null : _showResendConfirmDialog,
                            child: Text(
                              "Resend OTP",
                              style: TextStyle(
                                color: const Color(0xFF003840),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showResendConfirmDialog() {
    final username = emailController.text.trim();
    if (username.isEmpty) {
      _showSnack("Email is missing");
      return;
    }

    final remaining = _secondsUntilResend(username);
    if (remaining > 0) {
      _showSnack("You can resend OTP in ${remaining}s");
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text("Resend OTP", style: TextStyle(fontSize: 16.sp)),
          content: Text("Resend OTP to ${_maskedEmail(username)}?", style: TextStyle(fontSize: 13.sp)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: TextStyle(color: const Color(0xFF003840))),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                Navigator.of(context).pop();
                await _performResendOtp(username);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003840),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 1.5.w,
                ),
              )
                  : Text("Resend", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performResendOtp(String username) async {
    if (!await _hasInternetConnection()) {
      _showSnack("No internet available");
      return;
    }

    final remaining = _secondsUntilResend(username);
    if (remaining > 0) {
      _showSnack("You can resend OTP in ${remaining}s");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _forgotServices.sendResetOtp(username);

      setState(() => _isLoading = false);

      final bool success = result['success'] == true ||
          (result['status'] is int && result['status'] == 200);

      if (success) {
        await _recordOtpSent(username);
        _showSnack("OTP has been sent", success: true);
      } else {
        _showSnack(result['message']?.toString() ?? "Failed to resend OTP");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Error: $e");
    }
  }

  String _maskedEmail(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return email;
      final name = parts[0];
      final domain = parts[1];
      final first = name.isNotEmpty ? name[0] : '';
      return '$first***@$domain';
    } catch (_) {
      return email;
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

    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFF003840),
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
                          SizedBox(height: 15.h),
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      controller: _scroll_controller_guard(_scrollController),
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        top: 20.h,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  "Reset Password?",
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Center(
                                child: Text(
                                  "Please provide an email to receive password reset instructions.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(height: 25.h),
                              Text(
                                "Enter your email address",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: "example@gmail.com",
                                  prefixIcon: Icon(Icons.mail_outline_outlined, size: 20.w),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF003840),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 25.h),
                              Center(
                                child: SizedBox(
                                  width: 140.w,
                                  height: 40.h,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleSendOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003840),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25.r),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Get OTP",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                        SizedBox(width: 7.w),
                                        _isLoading
                                            ? SizedBox(
                                          width: 17.w,
                                          height: 17.h,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 1.5.w,
                                          ),
                                        )
                                            : Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 18.w,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              GestureDetector(
                                onTap: _goBack,
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: Text(
                                      "Go Back",
                                      style: TextStyle(
                                        color: const Color(0xFF003840),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ScrollController _scroll_controller_guard(ScrollController controller) {
    return controller;
  }
}
