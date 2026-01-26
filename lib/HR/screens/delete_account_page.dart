import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ⬅️ for FilteringTextInputFormatter
import 'package:shared_preferences/shared_preferences.dart';

import '../../Services/api_services.dart';
import 'applicant_filters.dart'; // where HrProfile lives

class DeleteAccountVerifyScreen extends StatefulWidget {
  const DeleteAccountVerifyScreen({super.key});

  @override
  State<DeleteAccountVerifyScreen> createState() => _DeleteAccountVerifyScreenState();
}

class _DeleteAccountVerifyScreenState extends State<DeleteAccountVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate first
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Please fill all required fields.')),
      // );
      showErrorSnackBar(context, 'Please fill all required fields.');
      return;
    }

    FocusScope.of(context).unfocus(); // hide keyboard

    final reason = _reasonCtrl.text.trim();
    final otp = _otpCtrl.text.trim();

    setState(() => _submitting = true);
    final res = await HrProfile.deleteAccountStep2(reason: reason, otp: otp);
    setState(() => _submitting = false);

    if (!mounted) return;
    showErrorSnackBar(context,res.message);
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(res.message),
    //     backgroundColor: res.ok ? Colors.green : Colors.red,
    //   ),
    // );

    // if (res.ok) {
    //   // clear local session & go to login (adjust route as per your app)
    //   final prefs = await SharedPreferences.getInstance();
    //   await prefs.remove('auth_token');
    //
    //   if (!mounted) return;
    //   Navigator.of(context).popUntil((r) => r.isFirst);
    //   // Navigator.of(context).pushReplacementNamed('/login');
    // }

    if (res.ok) {
      // clear local session & go to login (adjust route as per your app)
      final prefs = await SharedPreferences.getInstance();

      // ✅ pehle jitna aap already kar rahe ho, woh rehne do
      await prefs.remove('auth_token');

      // 🔴 NEW: saaf-saaf logout feel — jitni bhi local prefs hain, clear kar do
      await prefs.clear();

      if (!mounted) return;

      // ✅ aapka pehle se code — first route tak pop
      Navigator.of(context).popUntil((r) => r.isFirst);

      // 🔴 NEW: ab seedha login par bhej do, taa ki user app se logout dikhe
      // NOTE: '/login' ko aapke app ke login route name se match kara dena.
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Deletion',
          style: TextStyle(color: Color(0xFF003840)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF003840)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, // live validation
          child: Column(
            children: [
              const SizedBox(height: 4),

              // Reason (required)
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Tell us why you want to delete the account',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Reason is required';
                  }
                  if (v.trim().length < 5) {
                    return 'Please provide a little more detail (min 5 chars)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // OTP (required, digits only)
              TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'OTP',
                  hintText: 'Enter the OTP you received',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'OTP is required';
                  final isDigits = RegExp(r'^\d+$').hasMatch(s);
                  if (!isDigits) return 'OTP must contain digits only';
                  if (s.length < 4) return 'OTP seems too short';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              _submitting
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff005E6A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _submit,
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // ✅ Rectangular with little radius
        ),
        duration: Duration(seconds: 2),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
