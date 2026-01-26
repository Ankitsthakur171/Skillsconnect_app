import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../Utilities/auth/LoginUserApi.dart';
import '../../../Utilities/delete_api.dart';
import '../../../blocpage/bloc_event.dart';
import '../../../blocpage/bloc_logic.dart';

class VerifyDeletionPage extends StatefulWidget {
  const VerifyDeletionPage({super.key});

  @override
  State<VerifyDeletionPage> createState() => _VerifyDeletionPageState();
}

class _VerifyDeletionPageState extends State<VerifyDeletionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();

  bool _submitting = false;
  bool _autoValidate = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String? _validateReason(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter a reason';
    return null;
  }

  String? _validateOtp(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter OTP';
    final trimmed = v.trim();
    final digits = RegExp(r'^[0-9]{6}$');
    if (!digits.hasMatch(trimmed)) {
      return 'OTP must be exactly 6 digits';
    }
    return null;
  }

  Future<void> _showDeletedDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 220.w,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64.w,
                    height: 64.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade50,
                    ),
                    child: Center(
                      child: Icon(Icons.check, size: 36.w, color: Colors.green),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Your account has been deleted',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF003840),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autoValidate = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter valid details'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    final reason = _reasonCtrl.text.trim();
    final otp = _otpCtrl.text.trim();

    setState(() => _submitting = true);

    try {
      final result = await DeleteApi.step2Request(reason: reason, otp: otp);
      debugPrint('VerifyDeletionPage._submit -> $result');

      final status = result['status'] as int? ?? 0;
      final body = result['body'];

      if (status >= 200 && status < 300) {
        await _showDeletedDialog();

        final loginService = loginUser();
        await loginService.clearToken();

        if (context.mounted) {
          context.read<NavigationBloc>().add(GobackToLoginPage());
        }
      } else {
        final msg = body is Map
            ? (body['message'] ?? body['msg'] ?? body.toString())
            : body.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $msg'), backgroundColor: Colors.red.shade600),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request timed out. Try again.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } catch (e) {
      debugPrint('VerifyDeletionPage._submit - exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade600),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = const Color(0xFF003840);
    final borderColor = const Color(0xFFD0DDDC);
    final fieldFill = const Color(0xFFF0F7F7);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Verify Deletion',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: titleColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          child: Form(
            key: _formKey,
            autovalidateMode:
            _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
            child: Column(
              children: [
                TextFormField(
                  controller: _reasonCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'State your Reason',
                    filled: true,
                    fillColor: fieldFill,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: borderColor, width: 1.2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.white, width: 1.4)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide:
                        BorderSide(color: Colors.red.shade400, width: 1.4)),
                  ),
                  validator: _validateReason,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    counterText: "", // hides "0/6"
                    hintText: 'OTP (6 digits)',
                    filled: true,
                    fillColor: fieldFill,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: borderColor, width: 1.2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.white, width: 1.4)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide:
                        BorderSide(color: Colors.red.shade400, width: 1.4)),
                  ),
                  validator: _validateOtp,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: titleColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: Text(
                      'Submit',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
