import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Utilities/AccountsWhatsAppNumberUpdate.dart';

class UpdateWhatsAppBottomSheet extends StatefulWidget {
  final String initialNumber;
  final FutureOr<void> Function(String newNumber) onSuccess;

  const UpdateWhatsAppBottomSheet({
    super.key,
    required this.initialNumber,
    required this.onSuccess,
  });

  @override
  State<UpdateWhatsAppBottomSheet> createState() =>
      _UpdateWhatsAppBottomSheetState();
}

class _UpdateWhatsAppBottomSheetState extends State<UpdateWhatsAppBottomSheet> {
  bool step1OtpSent = false;
  bool step1Verified = false;
  bool step2OtpSent = false;

  final TextEditingController newNumberController = TextEditingController();
  final TextEditingController step1OtpController = TextEditingController();
  final TextEditingController step2OtpController = TextEditingController();

  bool _step1OtpValid = false;
  bool _step2OtpValid = false;
  bool _newNumberValid = false;

  String? _step1Error;
  String? _step2Error;
  String? _newNumberError;

  final Color _accent = const Color(0xFF005E6A);
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    newNumberController.text = '';
    newNumberController.addListener(_onNewNumberChanged);
    step1OtpController.addListener(_onStep1OtpChanged);
    step2OtpController.addListener(_onStep2OtpChanged);
  }

  @override
  void dispose() {
    newNumberController
      ..removeListener(_onNewNumberChanged)
      ..dispose();
    step1OtpController
      ..removeListener(_onStep1OtpChanged)
      ..dispose();
    step2OtpController
      ..removeListener(_onStep2OtpChanged)
      ..dispose();
    super.dispose();
  }

  void _onNewNumberChanged() {
    final t = newNumberController.text.trim();
    final valid = RegExp(r'^[6-9]\d{9}$').hasMatch(t);
    if (valid != _newNumberValid) {
      setState(() {
        _newNumberValid = valid;
        _newNumberError = valid ? null : 'Enter valid 10-digit WhatsApp number';
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

  void _showSnack(String t, {bool err = false}) {
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
                color: err ? Colors.red.shade600 : Colors.green,
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
                t,
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
    final current = widget.initialNumber.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(current)) {
      _showSnack('Current WhatsApp invalid', err: true);
      return;
    }
    if (_sending) return;

    setState(() {
      step1OtpSent = true;
      step1Verified = false;
      step1OtpController.clear();
      _step1OtpValid = false;
      _sending = true;
    });

    try {
      final res = await AccountsWhatsAppNumberUpdate.sendWhatsAppOtp(
        phoneNo: current,
        sendthru: 'wp',
      );

      final int status = res['status'] is int ? res['status'] as int : 0;
      final body = res['body'];

      if (status >= 200 && status < 300) {
        String msg = 'OTP sent to current WhatsApp';
        if (body is Map)
          msg = (body['message'] ?? body['msg'] ?? msg).toString();
        _showSnack(msg, err: !(body is Map ? (body['status'] == true) : false));
      } else {
        String msg = 'Failed to send OTP';
        if (body is Map) {
          msg = (body['message'] ??
                  body['msg'] ??
                  body['error'] ??
                  body.toString())
              .toString();
        }
        _showSnack(msg, err: true);
      }
    } catch (e) {
      _showSnack('Failed to send OTP (exception)', err: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyStep1Otp() async {
    final code = step1OtpController.text.trim();
    if (!RegExp(r'^\d{4}$|^\d{6}$').hasMatch(code)) {
      setState(() => _step1Error = 'OTP must be 4 or 6 digits');
      _showSnack('Enter valid OTP', err: true);
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);

    try {
      final res = await AccountsWhatsAppNumberUpdate.verifyWhatsAppOtp(
        mobileOtp: code,
        sendthru: 'wp',
        rechange: 'Yes',
        phoneNo: widget.initialNumber.trim(),
      );

      final int status = res['status'] is int ? res['status'] as int : 0;
      final body = res['body'];

      if (status >= 200 && status < 300) {
        if (body is Map &&
            (body['status'] == true || body['success'] == true)) {
          setState(() {
            step1Verified = true;
            step1OtpSent = false;
            _step1Error = null;
          });
          _showSnack('Current WhatsApp verified');
        } else {
          final msg = (body is Map)
              ? (body['message'] ?? body['msg'] ?? body.toString())
              : body.toString();
          _showSnack(msg, err: true);
        }
      } else {
        final msg = (body is Map)
            ? (body['message'] ?? body['msg'] ?? body.toString())
            : body.toString();
        _showSnack(msg, err: true);
      }
    } catch (e) {
      _showSnack('OTP verification failed', err: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendStep2Otp() async {
    final newNum = newNumberController.text.trim();
    if (!_newNumberValid) {
      _showSnack('Enter valid new WhatsApp number', err: true);
      return;
    }
    if (!step1Verified) {
      _showSnack('Verify current WhatsApp first', err: true);
      return;
    }
    if (_sending) return;

    setState(() {
      step2OtpSent = true;
      step2OtpController.clear();
      _step2OtpValid = false;
      _sending = true;
    });

    try {
      final res = await AccountsWhatsAppNumberUpdate.sendWhatsAppOtp(
        phoneNo: newNum,
        sendthru: 'wp',
      );

      final int status = res['status'] is int ? res['status'] as int : 0;
      final body = res['body'];

      if (status >= 200 && status < 300) {
        String msg = 'OTP sent to new WhatsApp';
        if (body is Map) {
          msg = (body['message'] ?? body['msg'] ?? msg).toString();
        }
        _showSnack(msg, err: !(body is Map ? (body['status'] == true) : false));
      } else {
        final msg = (body is Map)
            ? (body['message'] ??
                body['msg'] ??
                body['error'] ??
                body.toString())
            : body.toString();
        _showSnack(msg, err: true);
      }
    } catch (e) {
      _showSnack('Failed to send OTP to new WhatsApp', err: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submitChange() async {
    final otp = step2OtpController.text.trim();
    final newNum = newNumberController.text.trim();

    if (!_newNumberValid) {
      _showSnack('Enter valid new WhatsApp number', err: true);
      return;
    }
    if (!step2OtpSent) {
      _showSnack('Send OTP to new WhatsApp first', err: true);
      return;
    }
    if (!RegExp(r'^\d{4}$|^\d{6}$').hasMatch(otp)) {
      setState(() => _step2Error = 'OTP must be 4 or 6 digits');
      _showSnack('Enter valid OTP', err: true);
      return;
    }
    if (!step1Verified) {
      _showSnack('Current WhatsApp verification required', err: true);
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);

    try {
      final res = await AccountsWhatsAppNumberUpdate.verifyWhatsAppOtp(
        mobileOtp: otp,
        sendthru: 'wp',
        rechange: 'New',
        phoneNo: newNum,
      );

      final int status = res['status'] is int ? res['status'] as int : 0;
      final body = res['body'];

      if (status >= 200 && status < 300) {
        if (body is Map &&
            (body['status'] == true || body['success'] == true)) {
          _showSnack('WhatsApp updated successfully');
          await _showSuccessAndClose(newNum);
        } else {
          final msg = (body is Map)
              ? (body['message'] ?? body['msg'] ?? body.toString())
              : body.toString();
          _showSnack(msg, err: true);
        }
      } else {
        final msg = (body is Map)
            ? (body['message'] ??
                body['msg'] ??
                body['error'] ??
                body.toString())
            : body.toString();
        _showSnack(msg, err: true);
      }
    } catch (e) {
      _showSnack('Failed to submit new WhatsApp', err: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showSuccessAndClose(String newNum) async {
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
                Text('WhatsApp changed',
                    style:
                        TextStyle(color: _accent, fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                const Text('Your WhatsApp number has been updated.'),
              ],
            ),
          ),
        );
      },
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_whatsapp', newNum);

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop(); // dialog
    if (mounted) {
      await widget.onSuccess(newNum);
      Navigator.of(context).pop(); // sheet
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
              Text('Update WhatsApp Number',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
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
                    _bullet('You can only request 3 OTPs; exceeding this will block your account for security reasons.'),
                    _bullet('The new number must not be associated with any existing SkillsConnect account.'),
                    _bullet('The number change is permanent and cannot be reversed.'),
                    _bullet('Whatsapp number can only be updated once in a month.'),

                  ],
                ),
              ),

              SizedBox(height: 18.h),

              // STEP 1
              Text('Step 1: Send OTP to Current WhatsApp',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.message_outlined, size: 18.w),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              widget.initialNumber.isNotEmpty
                                  ? widget.initialNumber
                                  : '—',
                            ),
                          ),
                          if (step1Verified)
                            const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  SizedBox(
                    height: 36.h,
                    child: OutlinedButton(
                      onPressed:
                          (step1Verified || _sending) ? null : _sendStep1Otp,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _accent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r)),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 6.h),
                        minimumSize: Size(0, 36.h),
                      ),
                      child: Text(
                        step1Verified ? 'Verified' : 'Send OTP',
                        style: TextStyle(color: _accent, fontSize: 13.sp),
                      ),
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
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade300),
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
                            errorText: _step1Error,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    SizedBox(
                      height: 36.h,
                      child: ElevatedButton(
                        onPressed: (!_step1OtpValid || _sending)
                            ? null
                            : _verifyStep1Otp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r)),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          minimumSize: Size(0, 36.h),
                        ),
                        child: const Text('Verify',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 18.h),
              Text('Step 2: Enter & Send OTP to New WhatsApp',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.message_outlined, size: 18.w),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: TextField(
                              controller: newNumberController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Enter new WhatsApp',
                                border: InputBorder.none,
                                errorText: _newNumberError,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  SizedBox(
                    height: 36.h,
                    child: OutlinedButton(
                      onPressed:
                          (!_newNumberValid || !step1Verified || _sending)
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
                          style: TextStyle(color: _accent, fontSize: 13.sp)),
                    ),
                  ),
                ],
              ),

              if (step2OtpSent) ...[
                SizedBox(height: 12.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade300),
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
                            errorText: _step2Error,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        height: 36.h,
                        child: ElevatedButton(
                          onPressed: (!_step2OtpValid || _sending)
                              ? null
                              : _submitChange,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                            minimumSize: Size(0, 36.h),
                          ),
                          child: const Text('Submit',
                              style: TextStyle(color: Colors.white)),
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
