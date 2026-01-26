import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Model/PersonalDetail_Model.dart';
import '../../../Utilities/AccountsMobileNumberUpdate.dart';
import '../../../Utilities/MyAccount_Get_Post/PersonalDetail_Api.dart';

class UpdateMobileBottomSheet extends StatefulWidget {
  final String? initialNumber;
  final FutureOr<void> Function(String newNumber) onSuccess;

  const UpdateMobileBottomSheet({
    super.key,
    required this.initialNumber,
    required this.onSuccess,
  });

  @override
  State<UpdateMobileBottomSheet> createState() =>
      _UpdateMobileBottomSheetState();
}

class _UpdateMobileBottomSheetState extends State<UpdateMobileBottomSheet> {
  bool step1OtpSent = false;
  bool step1Verified = false;
  bool step2OtpSent = false;
  bool loading = true;

  final TextEditingController newNumberController = TextEditingController();
  final TextEditingController step1OtpController = TextEditingController();
  final TextEditingController step2OtpController = TextEditingController();

  // UI / validation flags
  bool _step1OtpValid = false;
  bool _step2OtpValid = false;
  bool _newNumberValid = false;

  String? _step1Error;
  String? _step2Error;
  String? _newNumberError;

  final Color _accent = const Color(0xFF005E6A);
  bool _sending = false;

  String currentMobile = '';

  @override
  void initState() {
    super.initState();

    newNumberController.addListener(_onNewNumberChanged);
    step1OtpController.addListener(_onStep1OtpChanged);
    step2OtpController.addListener(_onStep2OtpChanged);

    // keep the newNumber empty so user must enter new number in step2
    if (widget.initialNumber != null &&
        widget.initialNumber!.trim().isNotEmpty) {
      currentMobile = widget.initialNumber!.trim();
      _loadCurrentMobileIfNeeded();
    } else {
      _loadCurrentMobile();
    }
  }

  Future<void> _loadCurrentMobileIfNeeded() async {
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
        final fetched = list.first.mobile ?? '';
        if (fetched.isNotEmpty && mounted) {
          setState(() {
            currentMobile = fetched;
            loading = false;
          });
        } else {
          if (mounted) setState(() => loading = false);
        }
      } else {
        if (mounted) setState(() => loading = false);
      }
    } catch (e, st) {
      debugPrint('Error fetching personal details: $e\n$st');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadCurrentMobile() async {
    if (!mounted) return;
    setState(() {
      loading = true;
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
        final fetched = list.first.mobile ?? '';
        currentMobile = fetched;
      } else {
        final prefs2 = await SharedPreferences.getInstance();
        final saved = prefs2.getString('user_mobile') ?? '';
        currentMobile = saved;
      }
    } catch (e, st) {
      debugPrint('Error fetching personal details: $e\n$st');
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('user_mobile') ?? '';
      currentMobile = saved;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    newNumberController.removeListener(_onNewNumberChanged);
    step1OtpController.removeListener(_onStep1OtpChanged);
    step2OtpController.removeListener(_onStep2OtpChanged);

    newNumberController.dispose();
    step1OtpController.dispose();
    step2OtpController.dispose();
    super.dispose();
  }

  void _onNewNumberChanged() {
    final t = newNumberController.text.trim();
    final valid = RegExp(r'^[6-9]\d{9}$').hasMatch(t);
    if (valid != _newNumberValid) {
      setState(() {
        _newNumberValid = valid;
        _newNumberError =
            valid ? null : 'Enter valid 10-digit mobile (starts 6-9)';
      });
    }
  }

  void _onStep1OtpChanged() {
    final t = step1OtpController.text.trim();
    final valid = RegExp(r'^\d{4}$|^\d{6}$').hasMatch(t);
    if (valid != _step1OtpValid) {
      setState(() {
        _step1OtpValid = valid;
        _step1Error = valid ? null : 'OTP must be 4 or 6 digits';
      });
    }
  }

  void _onStep2OtpChanged() {
    final t = step2OtpController.text.trim();
    final valid = RegExp(r'^\d{4}$|^\d{6}$').hasMatch(t);
    if (valid != _step2OtpValid) {
      setState(() {
        _step2OtpValid = valid;
        _step2Error = valid ? null : 'OTP must be 4 or 6 digits';
      });
    }
  }

  void _showSnack(String text, {bool error = false}) {
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
                color: error ? Colors.red.shade600 : Colors.green,
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
                text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) overlayEntry.remove();
    });
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
    _showSnack(msg, error: true);
    debugPrint('verify error details => status:$status body: $body');
  }

  Future<void> _sendStep1Otp() async {
    final target = currentMobile.trim();
    if (target.isEmpty || !RegExp(r'^[6-9]\d{9}$').hasMatch(target)) {
      _showSnack('Current mobile invalid', error: true);
      return;
    }
    if (_sending) return;

    setState(() {
      step1OtpSent = true;
      step1Verified = false;
      step1OtpController.clear();
      _step1OtpValid = false;
      _step1Error = null;
      _sending = true;
    });

    try {
      final res = await AccountsMobileNumberUpdate.sendMobileOtp(
          phoneNo: target, sendthru: 'mb');
      debugPrint('sendStep1Otp -> $res');

      if (res['status'] is int && res['status'] >= 200 && res['status'] < 300) {
        final body = res['body'];
        String serverMsg = 'OTP sent to current mobile';
        if (body is Map) {
          serverMsg =
              (body['message'] ?? body['msg'] ?? body['error'] ?? serverMsg)
                  .toString();
        } else if (body is String) {
          serverMsg = body;
        }
        _showSnack(serverMsg);
      } else {
        String msg = 'Failed to send OTP';
        final body = res['body'];
        if (body is Map) {
          msg = (body['message'] ??
                  body['msg'] ??
                  body['error'] ??
                  body.toString())
              .toString();
        } else if (body is String) msg = body;
        _showSnack(msg, error: true);
      }
    } catch (e, st) {
      debugPrint('sendStep1Otp exc: $e\n$st');
      _showSnack('Failed to send OTP (exception)', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyStep1Otp() async {
    final code = step1OtpController.text.trim();
    if (!RegExp(r'^\d{4}$|^\d{6}$').hasMatch(code)) {
      setState(() => _step1Error = 'OTP must be 4 or 6 digits');
      _showSnack('Enter valid OTP', error: true);
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);

    try {
      final res = await AccountsMobileNumberUpdate.verifyOtp(
        mobileOtp: code,
        sendthru: 'mb',
        rechange: 'Yes',
        phoneNo: currentMobile, // <-- REQUIRED: put current mobile here
      );
      debugPrint('verifyStep1Otp -> $res');
      _handleVerifyResponse(res, onSuccess: () {
        setState(() {
          step1Verified = true;
          step1OtpSent = false; // hide OTP input on success only
          _step1Error = null;
        });
        _showSnack('Current mobile verified');
      });
    } catch (e, st) {
      debugPrint('verifyStep1Otp exc: $e\n$st');
      _showSnack('OTP verification failed', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendStep2Otp() async {
    final newNumber = newNumberController.text.trim();
    if (!_newNumberValid) {
      _showSnack('Enter valid new mobile', error: true);
      return;
    }
    if (!step1Verified) {
      _showSnack('Please verify current mobile first', error: true);
      return;
    }
    if (_sending) return;

    setState(() {
      step2OtpSent = true;
      step2OtpController.clear();
      _step2OtpValid = false;
      _step2Error = null;
      _sending = true;
    });

    try {
      final res = await AccountsMobileNumberUpdate.sendMobileOtp(
          phoneNo: newNumber, sendthru: 'mb');
      debugPrint('sendStep2Otp -> $res');

      if (res['status'] is int && res['status'] >= 200 && res['status'] < 300) {
        final body = res['body'];
        String serverMsg = 'OTP sent to new mobile';
        if (body is Map) {
          serverMsg =
              (body['message'] ?? body['msg'] ?? body['error'] ?? serverMsg)
                  .toString();
        } else if (body is String) serverMsg = body;
        _showSnack(serverMsg);
      } else {
        String msg = 'Failed to send OTP to new mobile';
        final body = res['body'];
        if (body is Map) {
          msg = (body['message'] ??
                  body['msg'] ??
                  body['error'] ??
                  body.toString())
              .toString();
        } else if (body is String) msg = body;
        _showSnack(msg, error: true);
      }
    } catch (e, st) {
      debugPrint('sendStep2Otp exc: $e\n$st');
      _showSnack('Failed to send OTP to new mobile (exception)', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submitChange() async {
    final otp = step2OtpController.text.trim();
    final newNumber = newNumberController.text.trim();

    if (!_newNumberValid) {
      _showSnack('Enter valid new mobile', error: true);
      return;
    }
    if (!step2OtpSent) {
      _showSnack('Send OTP to new mobile first', error: true);
      return;
    }
    if (!RegExp(r'^\d{4}$|^\d{6}$').hasMatch(otp)) {
      setState(() => _step2Error = 'OTP must be 4 or 6 digits');
      _showSnack('Enter valid OTP', error: true);
      return;
    }
    if (!step1Verified) {
      _showSnack('Current mobile verification required', error: true);
      return;
    }

    if (_sending) return;
    setState(() => _sending = true);

    try {
      final res = await AccountsMobileNumberUpdate.verifyOtp(
        mobileOtp: otp,
        sendthru: 'mb',
        rechange: 'New',
        phoneNo: newNumber,
      );
      debugPrint('submitChange -> $res');
      _handleVerifyResponse(res, onSuccess: () async {
        await _showSuccessAndClose(newNumber);
      });
    } catch (e, st) {
      debugPrint('submitChange exc: $e\n$st');
      _showSnack('Failed to submit new mobile', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showSuccessAndClose(String newNumber) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          content: SizedBox(
            height: 120.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48.w),
                SizedBox(height: 12.h),
                Text('Mobile Number changed',
                    style:
                        TextStyle(color: _accent, fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Text('Your mobile number has been updated.'),
              ],
            ),
          ),
        );
      },
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_mobile', newNumber);

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
    if (mounted) {
      await widget.onSuccess(newNumber);
      Navigator.of(context).pop();
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
                  child: const Center(child: CircularProgressIndicator()))
              : ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  children: [
                    Center(
                      child: Container(
                          width: 48.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2.r))),
                    ),
                    SizedBox(height: 12.h),
                    Text('Update Mobile Number',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16.sp)),
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
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 8.h),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _bullet(
                                'You can only request 3 OTPs; exceeding this will block your account for security reasons.',
                              ),
                              _bullet(
                                'The new number must not be associated with any existing SkillsConnect account.',
                              ),
                              _bullet(
                                'The number change is permanent and cannot be reversed.',
                              ),
                              _bullet(
                                'Mobile number can only be updated once in a month.',
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Text('Step 1: Send OTP to Current Mobile',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(30.r),
                                border:
                                    Border.all(color: Colors.grey.shade300)),
                            child: Row(children: [
                              Icon(Icons.phone_android, size: 18.w),
                              SizedBox(width: 10.w),
                              Expanded(
                                  child: Text(
                                      currentMobile.isNotEmpty
                                          ? currentMobile
                                          : '—',
                                      style: TextStyle(fontSize: 14.sp))),
                              if (step1Verified)
                                Icon(Icons.check_circle, color: Colors.green),
                            ]),
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
                                  horizontal: 14.w, vertical: 6.h),
                              minimumSize: Size(0, 36.h),
                            ),
                            child: Text(step1Verified ? 'Verified' : 'Send OTP',
                                style: TextStyle(color: _accent)),
                          ),
                        ),
                      ],
                    ),
                    if (step1OtpSent && !step1Verified) ...[
                      SizedBox(height: 12.h),
                      Row(children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12.r),
                                border:
                                    Border.all(color: Colors.grey.shade300)),
                            child: TextField(
                              controller: step1OtpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6)
                              ],
                              decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'Enter OTP (4 or 6 digits)',
                                  border: InputBorder.none,
                                  isDense: true,
                                  errorText: _step1Error),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        SizedBox(
                          height: 44.h,
                          child: ElevatedButton(
                            onPressed: (!_step1OtpValid || _sending)
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
                      ]),
                    ],
                    SizedBox(height: 18.h),
                    Text('Step 2: Enter & Send OTP to New Mobile',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 8.h),
                    Row(children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30.r),
                              border: Border.all(color: Colors.grey.shade300)),
                          child: Row(children: [
                            Icon(Icons.phone_android, size: 18.w),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: newNumberController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10)
                                ],
                                decoration: InputDecoration(
                                    hintText: 'Enter new mobile',
                                    border: InputBorder.none,
                                    isDense: true,
                                    errorText: _newNumberError),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      SizedBox(
                        height: 44.h,
                        child: OutlinedButton(
                          onPressed: (step2OtpSent ||
                                  _sending ||
                                  !_newNumberValid ||
                                  !step1Verified)
                              ? null
                              : _sendStep2Otp,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _accent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 6.h),
                            minimumSize: Size(0, 36.h),
                          ),
                          child: Text('Send OTP',
                              style: TextStyle(color: _accent)),
                        ),
                      ),
                    ]),
                    if (step2OtpSent) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade300)),
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: step2OtpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6)
                              ],
                              decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'Enter OTP',
                                  border: InputBorder.none,
                                  isDense: true,
                                  errorText: _step2Error),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          SizedBox(
                            height: 40.h,
                            child: ElevatedButton(
                              onPressed: (!_step2OtpValid || _sending)
                                  ? null
                                  : _submitChange,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.r))),
                              child: const Text(
                                'Submit',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ]),
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
                                borderRadius: BorderRadius.circular(24.r))),
                        child: const Text('Close',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
        );
      },
    );
  }
}


Widget _bullet(String text) {
  return Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "• ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      ],
    ),
  );
}
