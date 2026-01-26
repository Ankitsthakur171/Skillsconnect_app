// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sk_loginscreen1/Pages/PasswordField.dart';
// import 'package:sk_loginscreen1/blocpage/bloc_event.dart';
// import 'package:sk_loginscreen1/blocpage/bloc_logic.dart';
// import 'package:sk_loginscreen1/blocpage/bloc_state.dart';
// import '../Utilities/auth/LoginUserApi.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import '../Utilities/update_fcm_token_api.dart';
//
// enum LoginOutcome {
//   success,
//   badPassword,
//   emailNotFound,
//   blocked,
//   requiresVerification,
//   unknown,
// }
//
// class LoginClassification {
//   final LoginOutcome outcome;
//   final String message;
//
//   const LoginClassification(this.outcome, this.message);
// }
//
// class Loginpage extends StatefulWidget {
//   const Loginpage({super.key});
//
//   @override
//   State<Loginpage> createState() => _LoginpageState();
// }
//
// class _LoginpageState extends State<Loginpage> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController otpController = TextEditingController();
//
//   bool _isLoading = false;
//   final loginUser _loginService = loginUser();
//   bool _internetToastShown = false;
//   bool _snackBarShown = false;
//   bool _usingOtp = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ScaffoldMessenger.of(context).clearSnackBars();
//       emailController.clear();
//       passwordController.clear();
//       otpController.clear();
//       setState(() {
//         _isLoading = false;
//       });
//     });
//
//     emailController.addListener(() => setState(() {}));
//     passwordController.addListener(() => setState(() {}));
//     otpController.addListener(() => setState(() {}));
//   }
//
//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     otpController.dispose();
//     super.dispose();
//   }
//
//   Future<bool> _hasInternetConnection() async {
//     try {
//       final result = await InternetAddress.lookup('google.com');
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   void _showSnackBarOnce(
//       BuildContext context,
//       String message, {
//         int cooldownSeconds = 3,
//         Color? color,
//         bool force = false,
//       }) {
//     if (_snackBarShown && !force) return;
//     _snackBarShown = true;
//
//     final messenger = ScaffoldMessenger.of(context);
//     messenger.hideCurrentSnackBar();
//
//     messenger.showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: color ?? Colors.green,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         duration: Duration(seconds: 2),
//       ),
//     );
//
//     Future.delayed(Duration(seconds: cooldownSeconds), () {
//       _snackBarShown = false;
//     });
//   }
//
//   bool _isValidEmail(String email) {
//     final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
//     return re.hasMatch(email);
//   }
//
//   bool _isValidEmailOrPhone(String input) {
//     final trimmed = input.trim();
//     if (trimmed.isEmpty) return false;
//
//     if (_isValidEmail(trimmed)) return true;
//
//     final normalized = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
//
//     final phoneRe = RegExp(r'^\+?\d{10,15}$');
//     return phoneRe.hasMatch(normalized);
//   }
//
//   LoginClassification _classifyLoginResult(Map<String, dynamic> result) {
//     final ok = (result['success'] == true) || (result['status'] == true);
//     final rawMsg = (result['message'] ?? result['msg'] ?? '').toString();
//     final msg = rawMsg.replaceAll(RegExp(r'<[^>]*>'), '').trim();
//
//     final code = (result['code'] ?? '').toString().toLowerCase();
//     final statusCode = result['status'] is int ? result['status'] as int : null;
//     final lower = msg.toLowerCase();
//
//     if (
//     ok ||
//         lower.contains('login successful') ||
//         lower.contains('logged in')) {
//       return const LoginClassification(LoginOutcome.success, 'Login Success');
//     }
//
//     if (lower.contains('not registered') ||
//         lower.contains('email not') ||
//         lower.contains('email address is not registered') ||
//         code.contains('email_not_found') ||
//         code.contains('user_not_found')) {
//       return const LoginClassification(LoginOutcome.emailNotFound,
//           'Login Failed – Email/Mobile not registered');
//     }
//
//     final looksLikeBadPassword = lower.contains('invalid login attempt') ||
//         lower.contains('invalid credential') ||
//         lower.contains('invalid credentials') ||
//         lower.contains('incorrect credential') ||
//         lower.contains('incorrect credentials') ||
//         lower.contains('wrong credential') ||
//         lower.contains('wrong credentials') ||
//         lower.contains('invalid username or password') ||
//         lower.contains('username or password') ||
//         lower.contains('auth failed') ||
//         lower.contains('unauthorized') ||
//         lower.contains('mismatch') ||
//         code.contains('invalid_password') ||
//         code.contains('wrong_password') ||
//         code.contains('invalid_credentials') ||
//         code.contains('bad_credentials') ||
//         statusCode == 401;
//
//     if (looksLikeBadPassword || lower.contains('password')) {
//       return const LoginClassification(
//           LoginOutcome.badPassword, 'Login Failed – Incorrect password');
//     }
//
//     if (code.contains('blocked') ||
//         code.contains('disabled') ||
//         lower.contains('block') ||
//         lower.contains('disable') ||
//         lower.contains('suspend')) {
//       return const LoginClassification(
//           LoginOutcome.blocked, 'Your account is blocked. Contact support.'
//       );
//     }
//
//     if (code.contains('unverified') ||
//         code.contains('verify') ||
//         lower.contains('verify')) {
//       return const LoginClassification(LoginOutcome.requiresVerification,
//           'Please verify your email/mobile to continue.');
//     }
//
//     return LoginClassification(
//       LoginOutcome.unknown,
//       msg.isEmpty ? 'Login failed. Try again.' : msg,
//     );
//   }
//
//   Future<void> _login() async {
//     if (_isLoading) return;
//
//     final username = emailController.text.trim();
//     final password = passwordController.text.trim();
//
//     if (username.isEmpty && password.isEmpty) {
//       _showSnackBarOnce(context, "Fill in all the details");
//       return;
//     }
//
//     if (username.isEmpty || !_isValidEmailOrPhone(username)) {
//       _showSnackBarOnce(context, "Enter a valid email or mobile number");
//       return;
//     }
//
//     if (password.isEmpty) {
//       _showSnackBarOnce(context, "Password is required");
//       return;
//     }
//
//     if (!await _hasInternetConnection()) {
//       if (!_internetToastShown) {
//         _internetToastShown = true;
//         _showSnackBarOnce(context, "No internet available");
//         Future.delayed(const Duration(seconds: 3), () {
//           _internetToastShown = false;
//         });
//       }
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//     final result = await _loginService.login(username, password);
//     setState(() {
//       _isLoading = false;
//     });
//
//     final classification = _classifyLoginResult(result);
//
//     switch (classification.outcome) {
//       case LoginOutcome.success:
//         {
//           final prefs = await SharedPreferences.getInstance();
//           final authToken = result['token'] ?? '';
//           String connectSid = result['cookie'] ?? '';
//
//           final match = RegExp(r'connect\.sid=([^;]+)').firstMatch(connectSid);
//           if (match != null) {
//             connectSid = match.group(1) ?? '';
//           }
//
//           await prefs.setString('authToken', authToken);
//           await prefs.setString('connectSid', connectSid);
//
//           final fcmToken = await FirebaseMessaging.instance.getToken();
//           if (fcmToken != null && fcmToken.isNotEmpty) {
//             try {
//               await UpdateFcmApi.sendFcmToken(fcmToken);
//             } catch (_) {}
//           }
//           FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
//             try {
//               await UpdateFcmApi.sendFcmToken(newToken);
//             } catch (_) {}
//           });
//
//           _showSnackBarOnce(context, "Logged in Successfully",
//               color: Colors.green, force: true);
//           context.read<NavigationBloc>().add(GotoHomeScreen2());
//           break;
//         }
//       case LoginOutcome.badPassword:
//         _showSnackBarOnce(context, "Login Failed – Incorrect password");
//         break;
//       case LoginOutcome.emailNotFound:
//         _showSnackBarOnce(
//             context, "Login Failed – Email/Mobile not registered");
//         break;
//       case LoginOutcome.blocked:
//         _showSnackBarOnce(context, "Your account is blocked. Contact support.");
//         break;
//       case LoginOutcome.requiresVerification:
//         _showSnackBarOnce(
//             context, "Please verify your email/mobile to continue.");
//         break;
//       case LoginOutcome.unknown:
//         final msg = classification.message;
//         _showSnackBarOnce(
//           context,
//           msg.toLowerCase().contains('error') ||
//               msg.toLowerCase().contains('exception')
//               ? msg
//               : "Enter correct credentials",
//         );
//         break;
//     }
//   }
//
//   Future<void> _requestOtpForEmail() async {
//     final username = emailController.text.trim();
//     if (username.isEmpty) {
//       _showSnackBarOnce(context, "Enter email or mobile number first");
//       return;
//     }
//     if (!_isValidEmailOrPhone(username)) {
//       _showSnackBarOnce(context, "Enter a valid email or mobile number");
//       return;
//     }
//
//     if (!await _hasInternetConnection()) {
//       _showSnackBarOnce(context, "No internet available");
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final result = await _loginService.requestLoginOtp(username);
//
//     setState(() {
//       _isLoading = false;
//     });
//
//     final isSuccess = (result['success'] == true) ||
//         (result['status'] is int && result['status'] == 200) ||
//         (result['status'] == 200);
//
//     if (isSuccess) {
//       _showSnackBarOnce(context, "OTP sent successfully",
//           color: Colors.green, force: true);
//       setState(() {
//         _usingOtp = true;
//         passwordController.clear();
//         otpController.clear();
//       });
//     } else {
//       final msg = result['message']?.toString() ?? 'Failed to send OTP';
//       _showSnackBarOnce(context, msg);
//     }
//   }
//
//   Future<void> _submitOtpLogin() async {
//     final otp = otpController.text.trim();
//     final username = emailController.text.trim();
//
//     if (otp.isEmpty) {
//       _showSnackBarOnce(context, "Enter OTP");
//       return;
//     }
//     if (!RegExp(r'^\d{4}$').hasMatch(otp) &&
//         !RegExp(r'^\d{6}$').hasMatch(otp)) {
//       _showSnackBarOnce(context, "OTP must be 4 or 6 digits");
//       return;
//     }
//
//     if (username.isEmpty || !_isValidEmailOrPhone(username)) {
//       _showSnackBarOnce(context, "Enter a valid email or mobile number");
//       return;
//     }
//
//     if (!await _hasInternetConnection()) {
//       _showSnackBarOnce(context, "No internet available");
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     final result = await _loginService.login(username, '', otp: otp);
//
//     setState(() {
//       _isLoading = false;
//     });
//
//     final classification = _classifyLoginResult(result);
//
//     switch (classification.outcome) {
//       case LoginOutcome.success:
//         {
//           final prefs = await SharedPreferences.getInstance();
//           final authToken = result['token'] ?? '';
//           String connectSid = result['cookie'] ?? '';
//
//           final match = RegExp(r'connect\.sid=([^;]+)').firstMatch(connectSid);
//           if (match != null) {
//             connectSid = match.group(1) ?? '';
//           }
//
//           await prefs.setString('authToken', authToken);
//           await prefs.setString('connectSid', connectSid);
//
//           final fcmToken = await FirebaseMessaging.instance.getToken();
//           if (fcmToken != null && fcmToken.isNotEmpty) {
//             try {
//               await UpdateFcmApi.sendFcmToken(fcmToken);
//             } catch (_) {}
//           }
//           FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
//             try {
//               await UpdateFcmApi.sendFcmToken(newToken);
//             } catch (_) {}
//           });
//
//           _showSnackBarOnce(context, "Logged in Successfully",
//               color: Colors.green, force: true);
//           context.read<NavigationBloc>().add(GotoHomeScreen2());
//           break;
//         }
//       case LoginOutcome.badPassword:
//         _showSnackBarOnce(context, "Login Failed – Incorrect password");
//         break;
//       case LoginOutcome.emailNotFound:
//         _showSnackBarOnce(
//             context, "Login Failed – Email/Mobile not registered");
//         break;
//       case LoginOutcome.blocked:
//         _showSnackBarOnce(context, "Your account is blocked. Contact support.");
//         break;
//       case LoginOutcome.requiresVerification:
//         _showSnackBarOnce(
//             context, "Please verify your email/mobile to continue.");
//         break;
//       case LoginOutcome.unknown:
//         final msg = classification.message;
//         _showSnackBarOnce(
//           context,
//           msg.toLowerCase().contains('error') ||
//               msg.toLowerCase().contains('exception')
//               ? msg
//               : "Enter correct credentials",
//         );
//         break;
//     }
//   }
//
//   void _onSecondaryAuthButtonPressed() {
//     if (_usingOtp) {
//       setState(() {
//         _usingOtp = false;
//         otpController.clear();
//       });
//     } else {
//       final username = emailController.text.trim();
//       if (username.isEmpty) {
//         _showSnackBarOnce(context, "Enter email or mobile number first");
//         return;
//       }
//       if (!_isValidEmailOrPhone(username)) {
//         _showSnackBarOnce(context, "Enter a valid email or mobile number");
//         return;
//       }
//       _requestOtpForEmail();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     ScreenUtil.init(
//       context,
//       designSize: const Size(390, 844),
//       minTextAdapt: true,
//       splitScreenMode: true,
//     );
//     return BlocListener<NavigationBloc, NavigationState>(
//       listener: (context, state) {},
//       child: Scaffold(
//         backgroundColor: const Color(0xFF003840),
//         resizeToAvoidBottomInset: true,
//         body: Column(
//           children: [
//             Expanded(
//               flex: 2,
//               child: SafeArea(
//                 child: Stack(
//                   children: [
//                     Center(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           SizedBox(height: 20.h),
//                           SvgPicture.asset(
//                             "assets/Logo.svg",
//                             width: 300.w,
//                             height: 70.h,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             Expanded(
//               flex: 2,
//               child: Container(
//                 padding: EdgeInsets.all(22.w),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius:
//                   BorderRadius.vertical(top: Radius.circular(25.r)),
//                 ),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Center(
//                         child: Text(
//                           "Login to your account",
//                           style: TextStyle(
//                             fontSize: 22.sp,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 15.h),
//                       Text("Enter your email or mobile number",
//                           style: TextStyle(fontSize: 14.sp)),
//                       SizedBox(height: 6.h),
//                       TextField(
//                         controller: emailController,
//                         keyboardType: TextInputType.emailAddress,
//                         autofillHints: const [
//                           AutofillHints.username,
//                           AutofillHints.email
//                         ],
//                         decoration: InputDecoration(
//                           hintText: "Email address",
//                           prefixIcon: Icon(Icons.email_outlined, size: 20.w),
//                           filled: true,
//                           fillColor: Colors.white,
//                           contentPadding: EdgeInsets.symmetric(
//                               vertical: 12.h, horizontal: 16.w),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(25.r),
//                             borderSide:
//                             const BorderSide(color: Color(0xFF003840)),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 10.h),
//                       if (_usingOtp) ...[
//                         Text("Enter OTP", style: TextStyle(fontSize: 14.sp)),
//                         SizedBox(height: 6.h),
//                         TextField(
//                           controller: otpController,
//                           keyboardType: TextInputType.number,
//                           decoration: InputDecoration(
//                             hintText: "Enter OTP (4 or 6 digits)",
//                             filled: true,
//                             fillColor: Colors.white,
//                             contentPadding: EdgeInsets.symmetric(
//                                 vertical: 12.h, horizontal: 16.w),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(25.r),
//                               borderSide:
//                               const BorderSide(color: Color(0xFF003840)),
//                             ),
//                           ),
//                         ),
//                       ] else ...[
//                         Text("Enter password",
//                             style: TextStyle(fontSize: 14.sp)),
//                         SizedBox(height: 6.h),
//                         PasswordField(controller: passwordController),
//                       ],
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: TextButton(
//                           onPressed: () {
//                             context
//                                 .read<NavigationBloc>()
//                                 .add(GoToForgotPassword());
//                           },
//                           child: Text(
//                             "Forgot password?",
//                             style:
//                             TextStyle(color: Colors.black, fontSize: 12.sp),
//                           ),
//                         ),
//                       ),
//                       SizedBox(
//                         height: 50.h,
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: ElevatedButton(
//                                 onPressed: _isLoading
//                                     ? null
//                                     : (_usingOtp ? _submitOtpLogin : _login),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF003840),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(25.r),
//                                   ),
//                                 ),
//                                 child: _isLoading
//                                     ? SizedBox(
//                                   width: 20.w,
//                                   height: 20.w,
//                                   child: CircularProgressIndicator(
//                                     color: Colors.white,
//                                     strokeWidth: 2.w,
//                                   ),
//                                 )
//                                     : Text(
//                                   _usingOtp ? "Submit OTP" : "Login",
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 15.sp,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 12.w),
//                             Expanded(
//                               child: ElevatedButton(
//                                 onPressed: _isLoading
//                                     ? null
//                                     : _onSecondaryAuthButtonPressed,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF003840),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(25.r),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   _usingOtp ? "Password Login" : "OTP Login",
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 15.sp,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: 12.h),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text("Don’t have an account?",
//                               style: TextStyle(fontSize: 12.sp)),
//                           GestureDetector(
//                             onTap: () async {
//                               final Uri url =
//                               Uri.parse('https://skillsconnect.in/sign-up');
//                               if (await canLaunchUrl(url)) {
//                                 await launchUrl(url,
//                                     mode: LaunchMode.externalApplication);
//                               } else {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                       content: Text("Couldn't sign-in")),
//                                 );
//                               }
//                             },
//                             child: Text(
//                               "Sign Up",
//                               style: TextStyle(
//                                 color: Colors.teal,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 12.sp,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }