import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Model/PersonalDetail_Model.dart';
import '../../../Utilities/AccountsEmailUpdate_apis.dart';
import '../../../Utilities/MyAccount_Get_Post/PersonalDetail_Api.dart';
import '../../../Utilities/auth/LoginUserApi.dart';
import '../../../blocpage/bloc_event.dart';
import '../../../blocpage/bloc_logic.dart';

class UpdateEmailBottomSheet extends StatefulWidget {
  const UpdateEmailBottomSheet({super.key});

  @override
  State<UpdateEmailBottomSheet> createState() => _UpdateEmailBottomSheetState();
}

class _UpdateEmailBottomSheetState extends State<UpdateEmailBottomSheet> {
  bool step1OtpSent = false;
  bool step1Verified = false;
  bool step2OtpSent = false;

  bool loading = true;
  String currentEmail = '';

  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController step1OtpController = TextEditingController();
  final TextEditingController step2OtpController = TextEditingController();

  final Color _titleColor = const Color(0xFF003840);
  final Color _borderColor = const Color(0xFFD0DDDC);
  final Color _fieldFill =  Colors.grey.shade100;
  final Color _accent = const Color(0xFF005E6A);

  bool _sending = false;

  bool _step1OtpHasValidLen = false;
  bool _step2OtpHasValidLen = false;
  bool _newEmailLooksValid = false;

  String? _step1ErrorText;
  String? _step2ErrorText;
  String? _newEmailErrorText;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();

    step1OtpController.addListener(_onStep1OtpChanged);
    step2OtpController.addListener(_onStep2OtpChanged);
    newEmailController.addListener(_onNewEmailChanged);
  }

  Future<void> _loadCurrentEmail() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      currentEmail = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final List<PersonalDetailModel> list =
          await PersonalDetailApi.fetchPersonalDetails(
        authToken: authToken,
        connectSid: connectSid,
      );

      if (list.isNotEmpty) {
        setState(() {
          currentEmail = list.first.email;
        });
      } else {
        final saved = prefs.getString('user_email') ?? '';
        setState(() {
          currentEmail = saved;
        });
      }
    } catch (e, st) {
      debugPrint('Error fetching personal details: $e\n$st');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    step1OtpController.removeListener(_onStep1OtpChanged);
    step2OtpController.removeListener(_onStep2OtpChanged);
    newEmailController.removeListener(_onNewEmailChanged);

    newEmailController.dispose();
    step1OtpController.dispose();
    step2OtpController.dispose();
    super.dispose();
  }

  void _onStep1OtpChanged() {
    final txt = step1OtpController.text.trim();
    final valid = RegExp(r'^\d{4}$|^\d{6}$').hasMatch(txt);
    if (valid != _step1OtpHasValidLen) {
      setState(() {
        _step1OtpHasValidLen = valid;
        _step1ErrorText = valid ? null : 'OTP must be 4 or 6 digits';
      });
    }
  }

  void _onStep2OtpChanged() {
    final txt = step2OtpController.text.trim();
    final valid = RegExp(r'^\d{4}$|^\d{6}$').hasMatch(txt);
    if (valid != _step2OtpHasValidLen) {
      setState(() {
        _step2OtpHasValidLen = valid;
        _step2ErrorText = valid ? null : 'OTP must be 4 or 6 digits';
      });
    }
  }

  void _onNewEmailChanged() {
    final txt = newEmailController.text.trim();
    final looks = _emailLooksValid(txt);
    if (looks != _newEmailLooksValid) {
      setState(() {
        _newEmailLooksValid = looks;
        _newEmailErrorText = looks ? null : 'Enter a valid email';
      });
    }
  }

  bool _emailLooksValid(String e) {
    final v = e.trim();
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(v);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (ctx) {
        final topInset = MediaQuery.of(ctx).padding.top;
        return Positioned(
          top: topInset + 8,
          left: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.red.shade600 : Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) overlayEntry.remove();
    });
  }

  Future<void> _sendStep1Otp() async {
    if (currentEmail.trim().isEmpty) {
      _showSnack('No current email available', isError: true);
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);

    debugPrint('Button pressed: _sendStep1Otp');
    try {
      final res = await EmailOtpApi.sendEmailOtp(
        email: currentEmail,
        rechange: 'Yes',
      );
      debugPrint('EmailOtpApi.sendEmailOtp (step1) -> $res');
      _handleSendResponse(res, onSuccess: () {
        setState(() {
          step1OtpSent = true;
          step1Verified = false;
          // reset otp fields/state
          step1OtpController.clear();
          _step1OtpHasValidLen = false;
          _step1ErrorText = null;
        });
        _showSnack('OTP sent to current email', isError: false);
      });
    } catch (e, st) {
      debugPrint('sendStep1Otp exception: $e\n$st');
      _showSnack('Failed to send OTP', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyStep1Otp() async {
    final code = step1OtpController.text.trim();
    if (!RegExp(r'^\d{4}$|^\d{6}$').hasMatch(code)) {
      setState(() => _step1ErrorText = 'OTP must be 4 or 6 digits');
      _showSnack('Enter a valid 4 or 6 digit OTP', isError: true);
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);

    debugPrint('Button pressed: _verifyStep1Otp - code:$code');
    try {
      final res = await EmailOtpApi.verifyOtp(
        emailOtp: code,
        emailNew: currentEmail,
        rechange: 'Yes',
      );
      debugPrint('EmailOtpApi.verifyOtp (step1) -> $res');

      _handleVerifyResponse(res, onSuccess: () {
        setState(() {
          step1Verified = true;
          step1OtpSent = false;
          _step1ErrorText = null;
        });
        _showSnack('Current email verified', isError: false);
      });
    } catch (e, st) {
      debugPrint('verifyStep1Otp exception: $e\n$st');
      _showSnack('Verification failed', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendStep2Otp() async {
    final newEmail = newEmailController.text.trim();
    if (!_emailLooksValid(newEmail)) {
      setState(() => _newEmailErrorText = 'Enter a valid email');
      _showSnack('Enter a valid new email', isError: true);
      return;
    }
    if (!step1Verified) {
      _showSnack('Please verify current email first', isError: true);
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);

    debugPrint('Button pressed: _sendStep2Otp - newEmail:$newEmail');
    try {
      final res =
          await EmailOtpApi.sendEmailOtp(email: newEmail, rechange: 'New');
      debugPrint('EmailOtpApi.sendEmailOtp (step2) -> $res');

      _handleSendResponse(res, onSuccess: () {
        setState(() {
          step2OtpSent = true;
          _step2OtpHasValidLen = false;
          step2OtpController.clear();
          _step2ErrorText = null;
        });
        _showSnack('OTP sent to new email', isError: false);
      });
    } catch (e, st) {
      debugPrint('sendStep2Otp exception: $e\n$st');
      _showSnack('Failed to send OTP to new email', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submitChange() async {
    final otp = step2OtpController.text.trim();
    final newEmail = newEmailController.text.trim();

    if (!_emailLooksValid(newEmail)) {
      setState(() => _newEmailErrorText = 'Enter a valid email');
      _showSnack('Enter a valid new email', isError: true);
      return;
    }
    if (!step2OtpSent) {
      _showSnack('Send OTP to new email first', isError: true);
      return;
    }
    if (!RegExp(r'^\d{4}$|^\d{6}$').hasMatch(otp)) {
      setState(() => _step2ErrorText = 'OTP must be 4 or 6 digits');
      _showSnack('Enter valid 4 or 6 digit OTP', isError: true);
      return;
    }
    if (!step1Verified) {
      _showSnack('Current email verification required', isError: true);
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);

    debugPrint('Button pressed: _submitChange - otp:$otp newEmail:$newEmail');
    try {
      final res = await EmailOtpApi.verifyOtp(
        emailOtp: otp,
        emailNew: newEmail,
        rechange: 'New',
      );
      debugPrint('EmailOtpApi.verifyOtp (step2) -> $res');

      _handleVerifyResponse(res, onSuccess: () async {
        await _showSuccessDialogAndClose(newEmail);
      });
    } catch (e, st) {
      debugPrint('submitChange exception: $e\n$st');
      _showSnack('Failed to submit new email', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _handleSendResponse(Map<String, dynamic> res,
      {required VoidCallback onSuccess}) {
    final int status = res['status'] is int ? res['status'] as int : 0;
    final body = res['body'];

    if (status >= 200 && status < 300) {
      onSuccess();
      return;
    }

    String msg = 'Failed to send OTP';
    if (body is Map) {
      msg = (body['message'] ?? body['msg'] ?? body['error'] ?? body.toString())
          .toString();
    } else if (body is String) {
      msg = body;
    }
    _showSnack(msg, isError: true);
  }

  void _handleVerifyResponse(Map<String, dynamic> res,
      {required VoidCallback onSuccess}) {
    final int status = res['status'] is int ? res['status'] as int : 0;
    final body = res['body'];

    if (status >= 200 && status < 300) {
      if (body is Map) {
        final bool ok = (body['status'] == true) ||
            (body['success'] == true) ||
            (body['data'] is Map &&
                (body['data']['success'] == true ||
                    body['data']['status'] == true));
        if (ok) {
          onSuccess();
          return;
        }
      } else {
        onSuccess();
        return;
      }
    }

    String msg = 'OTP verification failed';
    if (body is Map) {
      msg = (body['message'] ?? body['msg'] ?? body['error'] ?? body.toString())
          .toString();
    } else if (body is String) {
      msg = body;
    }
    _showSnack(msg, isError: true);
    debugPrint('verify error details => status:$status body: $body');
  }

  Future<void> _showSuccessDialogAndClose(String newEmail) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: SizedBox(
            height: 120.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48.w),
                SizedBox(height: 12.h),
                Text(
                  'Email changed',
                  style: TextStyle(
                    color: const Color(0xFF005E6A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your email has been updated successfully.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', newEmail);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) Navigator.of(context).pop();
    if (mounted) Navigator.of(context).pop();

    await prefs.remove('authToken');
    await prefs.remove('connectSid');

    await prefs.clear();

    try {
      final loginService = loginUser();
      await loginService.clearToken();
    } catch (_) {}

    if (context.mounted) {
      context.read<NavigationBloc>().add(GobackToLoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 12.h,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: loading
              ? SizedBox(
                  height: 200.h,
                  child: const Center(child: CircularProgressIndicator()),
                )
              : ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20.r)),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    children: [
                      Center(
                        child: Container(
                          width: 48.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade200,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Important Note:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp)),
                            SizedBox(height: 8.h),
                            Text(
                              '• You can only request 3 OTPs; exceeding this will block your account for security reasons.\n'
                              '• The new email must not be associated with any existing skillsconnect account.\n'
                              '• The email change is permanent and can not be reversed.\n'
                              '• Email can only be updated once in a month.',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                          'Step 1: Send OTP to Current Email',
                          style: TextStyle(
                              color: _titleColor, fontWeight: FontWeight.w600)
                      ),
                      SizedBox(height: 8.h),
                      Row(

                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: _fieldFill,
                                borderRadius: BorderRadius.circular(30.r),
                                border:
                                    Border.all(color: _borderColor, width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.mail_outline,
                                      color: _titleColor, size: 18.w),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      currentEmail.isNotEmpty
                                          ? currentEmail
                                          : '—',
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey.shade800
                                      ),
                                    ),
                                  ),
                                  if (step1Verified)
                                    Padding(
                                      padding: EdgeInsets.only(left: 8.w),
                                      child: Icon(Icons.check_circle,
                                          color: Colors.green),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          SizedBox(
                            height: 44.h,
                            child: OutlinedButton(
                              onPressed: (step1Verified || _sending)
                                  ? null
                                  : _sendStep1Otp,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _accent),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r)),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                              ),
                              child: Text(
                                  step1Verified ? 'Verified' : 'Send OTP',
                                  style: TextStyle(color: _accent)),
                            ),
                          ),
                        ],
                      ),
                      if (step1OtpSent && !step1Verified) ...[
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: _fieldFill,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: _borderColor),
                                ),
                                child: TextField(
                                  controller: step1OtpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: 'Enter OTP (4 or 6 digits)',
                                    border: InputBorder.none,
                                    isDense: true,
                                    errorText: _step1ErrorText,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            SizedBox(
                              height: 44.h,
                              child: ElevatedButton(
                                onPressed: (!_step1OtpHasValidLen || _sending)
                                    ? null
                                    : _verifyStep1Otp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r)),
                                ),
                                child: Text(
                                  'Verify',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 18.h),
                      Text('Step 2: Enter & Send OTP to New Email',
                          style: TextStyle(
                              color: _titleColor, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                              ),
                              decoration: BoxDecoration(
                                color: _fieldFill,
                                borderRadius: BorderRadius.circular(30.r),
                                border:
                                    Border.all(color: _borderColor, width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.mail_outline,
                                      color: _titleColor, size: 18.w),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: TextField(
                                      controller: newEmailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        hintText: 'Enter new email',
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 8.h),
                                        errorText: _newEmailErrorText,
                                      ),
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          SizedBox(
                            height: 44.h,
                            child: OutlinedButton(
                              onPressed: (step2OtpSent ||
                                      _sending ||
                                      !_newEmailLooksValid ||
                                      !step1Verified)
                                  ? null
                                  : _sendStep2Otp,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _accent),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r)),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                              ),
                              child: Text('Send OTP',
                                  style: TextStyle(color: _accent)),
                            ),
                          ),
                        ],
                      ),
                      if (step2OtpSent) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: _fieldFill,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: step2OtpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: 'Enter OTP',
                                    border: InputBorder.none,
                                    isDense: true,
                                    errorText: _step2ErrorText,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              SizedBox(
                                height: 40.h,
                                child: ElevatedButton(
                                  onPressed: (!_step2OtpHasValidLen || _sending)
                                      ? null
                                      : _submitChange,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.r)),
                                  ),
                                  child: const Text(
                                    'Submit',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24.r)),
                          ),
                          child: Text('Close',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
