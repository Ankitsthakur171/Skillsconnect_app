import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Model/Contack_Us_model.dart';
import '../../../Utilities/Contact_Us_Api.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  final Color titleColor = const Color(0xFF003840);
  final Color borderColor = const Color(0xFFD0DDDC);
  final Color fieldFill = const Color(0xFFF0F7F7);
  final Color teal = const Color(0xFF003840);

  bool _sending = false;
  bool _autoValidate = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    double radius = 12,
    EdgeInsetsGeometry contentPadding =
    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: titleColor, fontSize: 15.sp),
      prefixIcon: icon != null
          ? Padding(
        padding: EdgeInsets.only(left: 12.w, right: 8.w),
        child: Icon(icon, size: 20.w, color: titleColor),
      )
          : null,
      prefixIconConstraints:
      icon != null ? BoxConstraints(minWidth: 48.w, minHeight: 48.h) : null,
      filled: true,
      fillColor: fieldFill,
      contentPadding: contentPadding,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.r),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.r),
        borderSide: BorderSide(color: Colors.white, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.r),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.r),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.6),
      ),
    );
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your name';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter phone';
    final trimmed = v.trim();
    final digitsOnly = RegExp(r'^[0-9]+$');
    if (!digitsOnly.hasMatch(trimmed) || trimmed.length != 10) {
      return 'Add a valid number';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter email';

    final trimmed = v.trim();

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email';
    }

    if (trimmed.toLowerCase().endsWith('@gamil.com') ||
        trimmed.toLowerCase().endsWith('@gmial.com') ||
        trimmed.toLowerCase().endsWith('@gmaill.com')) {
      return 'Did you mean @gmail.com?';
    }

    return null;
  }


  String? _validateSubject(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter subject';
    return null;
  }

  String? _validateMessage(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter a message';
    return null;
  }

  bool _anyFieldEmpty() {
    return _nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _subjectCtrl.text.trim().isEmpty ||
        _messageCtrl.text.trim().isEmpty;
  }

  Future<void> _showFinalDialog() async {

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 8.h),
          content: Text(
            'We have received your message. One of our team members will contact you shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: teal,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: teal,
                  padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_anyFieldEmpty()) {
      setState(() {
        _autoValidate = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all details')),
      );
      debugPrint('ContactUsPage: please fill all details - submission blocked');
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() {
        _autoValidate = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid details')),
      );
      debugPrint('ContactUsPage: validation failed (invalid phone/email/etc.)');
      return;
    }

    final req = ContactRequest(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
    );

    setState(() => _sending = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending message...')),
    );

    try {
      debugPrint('ContactUsPage._sendMessage - request: ${req.toJson()}');
      final resp = await ContactApi.sendContact(req);

      debugPrint(
          'ContactUsPage._sendMessage - response status=${resp.statusCode}, success=${resp.success}, msg=${resp.message}');

      if (resp.success) {
        await _showFinalDialog();
        _formKey.currentState?.reset();
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _emailCtrl.clear();
        _subjectCtrl.clear();
        _messageCtrl.clear();

        setState(() {
          _autoValidate = false;
        });

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Message sent successfully: ${resp.message}')),
        // );
      } else {
        final bodyPreview = resp.data != null ? resp.data.toString() : 'No JSON body';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API did not accept request: ${resp.message}\n$bodyPreview')),
        );
      }
    } on TimeoutException {
      debugPrint('ContactUsPage._sendMessage - TimeoutException');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request timed out. Please try again.')),
      );
    } catch (e, st) {
      debugPrint('ContactUsPage._sendMessage - exception: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor, size: 24.w),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Contact Us',
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
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
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: fieldFill,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact us:',
                        style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 18.sp),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Icon(Icons.phone, color: titleColor, size: 20.w),
                          SizedBox(width: 10.w),
                          Text('+91 9870470502',
                              style:
                              TextStyle(fontSize: 16.sp, color: titleColor)),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Icon(Icons.mail_outline, color: titleColor, size: 20.w),
                          SizedBox(width: 10.w),
                          Text('support@skillsconnect.in',
                              style:
                              TextStyle(fontSize: 16.sp, color: titleColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                TextFormField(
                  controller: _nameCtrl,
                  keyboardType: TextInputType.name,
                  decoration:
                  _inputDecoration(hint: 'Full Name', icon: Icons.person_outline),
                  validator: _validateName,
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(hint: 'Phone', icon: Icons.phone),
                  validator: _validatePhone,
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                  _inputDecoration(hint: 'Email', icon: Icons.mail_outline),
                  validator: _validateEmail,
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _subjectCtrl,
                  keyboardType: TextInputType.text,
                  decoration:
                  _inputDecoration(hint: 'Subject', icon: Icons.subject),
                  validator: _validateSubject,
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _messageCtrl,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  minLines: 5,
                  maxLines: 8,
                  decoration: _inputDecoration(
                    hint: 'Message',
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    radius: 12,
                  ),
                  validator: _validateMessage,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: titleColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Send Message',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
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
