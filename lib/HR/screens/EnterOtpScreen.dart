// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter/cupertino.dart';
// import '../bloc/Enter_Otp/enter_otp_bloc.dart';
// import '../bloc/Enter_Otp/enter_otp_event.dart';
// import '../bloc/Enter_Otp/enter_otp_state.dart';
//
//
// class EnterOtpScreen extends StatefulWidget {
//   final String email;
//
//   const EnterOtpScreen({required this.email});
//
//   @override
//   State<EnterOtpScreen> createState() => _EnterOtpScreenState();
// }
//
// class _EnterOtpScreenState extends State<EnterOtpScreen> {
//   bool _obscurePassword = true;
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => EnterOtpBloc(),
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         appBar: AppBar(
//           leading: IconButton(
//             icon: Icon(CupertinoIcons.back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           title: Text("Enter OTP", style: TextStyle(color: Colors.white)),
//           backgroundColor: Color(0xff005E6A),
//         ),
//         body: BlocConsumer<EnterOtpBloc, EnterOtpState>(
//           listener: (context, state) {
//             if (state.errorMessage.isNotEmpty) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(state.errorMessage), backgroundColor: Colors.red),
//               );
//             }
//             if (state.successMessage.isNotEmpty) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(state.successMessage), backgroundColor: Colors.green),
//               );
//               // Optionally navigate away
//             }
//           },
//           builder: (context, state) {
//             return SingleChildScrollView(
//               padding: EdgeInsets.all(24.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Email
//                   Padding(
//                     padding: EdgeInsets.only(left: 18.0),
//                     child: Text("Email address", style: TextStyle(color: Color(0xff003840))),
//                   ),
//                   SizedBox(height: 8),
//                   TextField(
//                     readOnly: true,
//                     controller: TextEditingController(text: widget.email),
//                     style: TextStyle(color: Color(0xff003840)),
//                     decoration: InputDecoration(
//                       prefixIcon: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: ImageIcon(
//                             AssetImage('assets/mail.png'),
//                             color: Color(0xff003840),
//                             size: 18,
//                           ),
//                         ),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(color: Colors.grey),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(color: Color(0xff003840), width: 2),
//                       ),
//                     ),
//                   ),
//
//                   // OTP
//                   SizedBox(height: 20),
//                   Padding(
//                     padding: EdgeInsets.only(left: 18.0),
//                     child: Text("Enter 6-digit OTP", style: TextStyle(color: Color(0xff003840))),
//                   ),
//                   SizedBox(height: 8),
//                   TextFormField(
//                     onChanged: (value) => context.read<EnterOtpBloc>().add(OtpChanged(value)),
//                     keyboardType: TextInputType.number,
//                     style: TextStyle(color: Color(0xff003840)),
//                     decoration: InputDecoration(
//                       hintText: "Enter OTP",
//                       hintStyle: TextStyle(color: Colors.grey),
//                       prefixIcon: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: ImageIcon(
//                             AssetImage('assets/mail.png'),
//                             color: Color(0xff003840),
//                             size: 18,
//                           ),
//                         ),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(color: Colors.grey),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(color: Color(0xff003840), width: 2),
//                       ),
//                     ),
//                   ),
//
//                   // Password
//                   SizedBox(height: 20),
//                   Padding(
//                     padding: EdgeInsets.only(left: 18.0),
//                     child: Text("Enter New Password", style: TextStyle(color: Color(0xff003840))),
//                   ),
//                   SizedBox(height: 8),
//                   TextFormField(
//                     onChanged: (value) => context.read<EnterOtpBloc>().add(PasswordChanged(value)),
//                     obscureText: _obscurePassword,
//                     style: TextStyle(color: Color(0xff003840)),
//                     decoration: InputDecoration(
//                       hintText: "Enter New Password",
//                       hintStyle: TextStyle(color: Colors.grey),
//                       prefixIcon: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: ImageIcon(
//                             AssetImage('assets/lock.png'),
//                             color: Color(0xff003840),
//                             size: 18,
//                           ),
//                         ),
//                       ),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
//                           color: Color(0xff003840),
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _obscurePassword = !_obscurePassword;
//                           });
//                         },
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(color: Colors.grey),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(color: Color(0xff003840), width: 2),
//                       ),
//                     ),
//                   ),
//
//
//
//                   // Submit Button
//                   SizedBox(height: 40),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         if (state.otp.isEmpty) {
//                           showErrorSnackBar(context, "OTP is required");
//                           return;
//                         }
//
//                         if (state.password.isEmpty) {
//                           showErrorSnackBar(context, "Password is required");
//                           return;
//                         }
//
//                         // agar dono bhar diye gaye hain to event fire hoga
//                         context.read<EnterOtpBloc>().add(SubmitOtp(widget.email));
//                       },
//                       style: ElevatedButton.styleFrom(
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         backgroundColor: Color(0xff005E6A),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       child: state.isLoading
//                           ? SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                           : Text(
//                         "Submit",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
// void showErrorSnackBar(BuildContext context, String message) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text(
//         message,
//         style: TextStyle(color: Colors.white, fontSize: 14),
//       ),
//       backgroundColor: Colors.red.shade600,
//       behavior: SnackBarBehavior.floating,
//       margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10), // ✅ Rectangular with little radius
//       ),
//       duration: Duration(seconds: 2),
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//     ),
//   );
// }
//
//
//
//
//














import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../bloc/Enter_Otp/enter_otp_bloc.dart';
import '../bloc/Enter_Otp/enter_otp_event.dart';
import '../bloc/Enter_Otp/enter_otp_state.dart';
import 'login_screen.dart';

class EnterOtpScreen extends StatefulWidget {
  final String email;

  const EnterOtpScreen({required this.email, Key? key}) : super(key: key);

  @override
  State<EnterOtpScreen> createState() => _EnterOtpScreenState();
}

class _EnterOtpScreenState extends State<EnterOtpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _confirmPassword = "";
  // 🔥 Resend OTP cooldown
  int _resendSeconds = 0;
  Timer? _timer;



  void _startResendTimer() {
    setState(() => _resendSeconds = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds > 1) {
        setState(() => _resendSeconds--);
      } else {
        t.cancel();
        setState(() => _resendSeconds = 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EnterOtpBloc(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Enter OTP", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xff005E6A),
        ),
        body: BlocConsumer<EnterOtpBloc, EnterOtpState>(
          listenWhen: (prev, curr) {
            // ✅ Only trigger when error or success message CHANGES (prevents spam)
            final errorChanged = (prev.errorMessage != curr.errorMessage) && curr.errorMessage.isNotEmpty;
            final successChanged = (prev.successMessage != curr.successMessage) && curr.successMessage.isNotEmpty;
            return errorChanged || successChanged;
          },
          listener: (context, state) {
            print('🔔 OTP SCREEN LISTENER: errorMsg="${state.errorMessage}", successMsg="${state.successMessage}", isLoading=${state.isLoading}, otpVerified=${state.otpVerified}');
            
            if (state.errorMessage.isNotEmpty) {
              print('❌ Showing error: ${state.errorMessage}');
              showErrorSnackBar(context, state.errorMessage);
              // ✅ Clear immediately to prevent spam
              Future.microtask(() {
                context.read<EnterOtpBloc>().emit(state.copyWith(errorMessage: ""));
              });
            }
            if (state.successMessage.isNotEmpty) {
              print('✅ Showing success: ${state.successMessage}');
              showSuccessSnackBar(context, state.successMessage);
              
              // ✅ Only navigate to login if it's password change success, not resend OTP
              if (state.successMessage.toLowerCase().contains('password') ||  
                  state.successMessage.toLowerCase().contains('updated')) {
                print('📱 Password changed successfully, navigating to Login screen in 1 second...');
                context.read<EnterOtpBloc>().emit(state.copyWith(successMessage: ""));
                
                Future.delayed(const Duration(seconds: 1), () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) =>  LoginScreen()),
                        (route) => false, // saare previous routes hata do
                  );
                });
              } else {
                // Just clear the message for resend OTP
                print('🔄 Resend OTP success message shown, clearing it');
                context.read<EnterOtpBloc>().emit(state.copyWith(successMessage: ""));
              }
            }

          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email
                  const Padding(
                    padding: EdgeInsets.only(left: 18.0),
                    child: Text("Email address", style: TextStyle(color: Color(0xff003840))),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    enabled: false, // ❌ disables editing & gives grey disabled look
                    controller: TextEditingController(text: widget.email),
                    style: const TextStyle(color: Colors.grey), // text bhi grey
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: ImageIcon(
                            AssetImage('assets/mail.png'),
                            color: Colors.grey,
                            size: 18,
                          ),
                        ),
                      ),
                      disabledBorder: OutlineInputBorder( // ✅ disabled border
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),



                  // OTP
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 18.0),
                    child: Text("Enter 6-digit OTP", style: TextStyle(color: Color(0xff003840))),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    onChanged: (value) {
                      context.read<EnterOtpBloc>().add(OtpChanged(value));
                      if (value.length == 6) {
                        FocusScope.of(context).unfocus(); // keyboard band karne ke liye (optional)
                        context.read<EnterOtpBloc>().add(VerifyOtp(widget.email, value)); // ✅ verify event
                      }
                    },
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Color(0xff003840)),
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "Enter OTP",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: ImageIcon(
                            AssetImage('assets/phone.png'),
                            color: Color(0xff003840),
                            size: 18,
                          ),
                        ),
                      ),
                      // ✅ Show tick / cross after verification
                      suffixIcon: state.otpVerified == null
                          ? null
                          : (state.otpVerified == true
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xff003840), width: 2),
                      ),
                    ),
                  ),

        // ✅ Resend OTP option below the text field
                  // Resend OTP button with cooldown
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resendSeconds == 0
                          ? () {
                        context.read<EnterOtpBloc>().add(ResendOtp(widget.email));
                        _startResendTimer(); // start 30s timer
                      }
                          : null,
                      child: Text(
                        _resendSeconds == 0
                            ? "Resend OTP"
                            : "Resend OTP (${_resendSeconds}s)",
                        style: const TextStyle(
                          color: Color(0xff005E6A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),



                  // TextFormField(
                  //   onChanged: (value) => context.read<EnterOtpBloc>().add(OtpChanged(value)),
                  //   keyboardType: TextInputType.number,
                  //   style: const TextStyle(color: Color(0xff003840)),
                  //   maxLength: 6, // ✅ max 6 characters allowed
                  //   inputFormatters: [
                  //     FilteringTextInputFormatter.digitsOnly, // ✅ only digits allowed
                  //     LengthLimitingTextInputFormatter(6),    // ✅ restrict to 6 digits
                  //   ],
                  //   decoration: InputDecoration(
                  //     counterText: "", // ✅ "0/6" counter hide karne ke liye
                  //     hintText: "Enter OTP",
                  //     hintStyle: const TextStyle(color: Colors.grey),
                  //     prefixIcon: Padding(
                  //       padding: const EdgeInsets.all(12.0),
                  //       child: SizedBox(
                  //         height: 20,
                  //         width: 20,
                  //         child: ImageIcon(
                  //           AssetImage('assets/phone.png'),
                  //           color: Color(0xff003840),
                  //           size: 18,
                  //         ),
                  //       ),
                  //     ),
                  //     enabledBorder: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(30),
                  //       borderSide: const BorderSide(color: Colors.grey),
                  //     ),
                  //     focusedBorder: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(30),
                  //       borderSide: const BorderSide(color: Color(0xff003840), width: 2),
                  //     ),
                  //   ),
                  // ),

                  // New Password
                  const Padding(
                    padding: EdgeInsets.only(left: 18.0),
                    child: Text("New Password", style: TextStyle(color: Color(0xff003840))),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    onChanged: (value) => context.read<EnterOtpBloc>().add(PasswordChanged(value)),
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Color(0xff003840)),
                    decoration: InputDecoration(
                      hintText: "Enter New Password",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12.0), // thoda spacing ke liye
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: ImageIcon(
                            AssetImage('assets/lock.png'), // ✅ aapka custom lock.png
                            color: Color(0xff003840),
                            size: 18,
                          ),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xff003840),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xff003840), width: 2),
                      ),
                    ),
                  ),

                  // Confirm Password
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 18.0),
                    child: Text("Confirm Password", style: TextStyle(color: Color(0xff003840))),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _confirmPassword = value;
                      });
                    },
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: Color(0xff003840)),
                    decoration: InputDecoration(
                      hintText: "Re-enter Password",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12.0), // thoda spacing ke liye
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: ImageIcon(
                            AssetImage('assets/lock.png'), // ✅ aapka custom lock.png
                            color: Color(0xff003840),
                            size: 18,
                          ),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xff003840),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xff003840), width: 2),
                      ),
                    ),
                  ),

                  // Submit Button
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        print('🔘 SUBMIT BUTTON PRESSED (OTP Screen)');
                        print('📧 Email: ${widget.email}');
                        print('🔢 OTP in state: "${state.otp}"');
                        print('🔒 Password in state: "${state.password}"');
                        print('✅ OTP Verified: ${state.otpVerified}');
                        print('⏳ isLoading: ${state.isLoading}');
                        print('🔑 Confirm Password: "$_confirmPassword"');
                        
                        if (state.otp.isEmpty) {
                          print('⚠️ OTP is empty');
                          showErrorSnackBar(context, "OTP is required");
                          return;
                        }

                        if (state.otpVerified == false) {
                          print('❌ OTP is not verified');
                          showErrorSnackBar(context, "OTP is incorrect");
                          return;
                        }

                        if (state.password.isEmpty) {
                          print('⚠️ Password is empty');
                          showErrorSnackBar(context, "Password is required");
                          return;
                        }

                        // ✅ Password length validation
                        if (state.password.length < 6) {
                          print('⚠️ Password too short: ${state.password.length} chars');
                          showErrorSnackBar(context, "Password must be at least 6 characters");
                          return;
                        }

                        if (_confirmPassword.isEmpty) {
                          print('⚠️ Confirm password is empty');
                          showErrorSnackBar(context, "Confirm Password is required");
                          return;
                        }

                        if (state.password != _confirmPassword) {
                          print('❌ Passwords do not match: "${state.password}" vs "$_confirmPassword"');
                          showErrorSnackBar(context, "Passwords do not match");
                          return;
                        }

                        print('✅ All validations passed, dispatching SubmitOtp event');
                        context.read<EnterOtpBloc>().add(SubmitOtp(widget.email));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xff005E6A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "Submit",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
