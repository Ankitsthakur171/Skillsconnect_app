
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/HR/bloc/Job/job_bloc.dart';
import 'package:skillsconnect/HR/screens/EnterOtpScreen.dart';
import 'package:skillsconnect/HR/screens/bottom_nav_bar.dart';
import 'package:skillsconnect/HR/screens/reset_password_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/Job/job_event.dart';
import '../bloc/Login/login_bloc.dart';
import '../bloc/Login/login_event.dart';
import '../bloc/Login/login_state.dart';
import 'ForceUpdate/force_update.dart';
import 'in_app_webview_screen.dart';
import 'job_screen.dart';
import 'login_with_otp.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final otpController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final TapGestureRecognizer _signUpRecognizer = TapGestureRecognizer();
  final TapGestureRecognizer _registercollege = TapGestureRecognizer();
  bool _isSubmitting = false; //  add



  @override
  void initState() {
    super.initState();
    _signUpRecognizer.onTap = (){
      if (_isSubmitting) return;                // ⬅️ guard
      _openUrl("https://skillsconnect.in/sign-up");
    };
    _registercollege.onTap = () {
      if (_isSubmitting) return; // ⬅️ guard

      _openUrl("https://skillsconnect.in/institute-onboarding");
    };


    // Wait until first frame is rendered, then check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        checkAndForceUpdate(context);
      }
    });

  }


  Future<void> _openUrl(String url) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppWebViewScreen(
          url: url,
          title: 'SkillsConnect', // optional
        ),
      ),
    );
  }



  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) async{
          emailController.value = emailController.value.copyWith(text: state.email);
          passwordController.value = passwordController.value.copyWith(text: state.password);

          if (state is LoginSuccess)  {
            if (mounted) setState(() => _isSubmitting = false);   // ⬅️ unlock

            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text(
            //       "You have successfully logged in!",
            //       style: TextStyle(color: Colors.white),
            //     ),
            //     backgroundColor: Colors.orange,
            //     duration: Duration(seconds: 2),
            //     behavior: SnackBarBehavior.floating,
            //     margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(10),
            //     ),
            //   ),
            // );

            showSuccessSnackBar(context, "You have successfully logged in!");

            // ✅ Show success SnackBar
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getString('user_id') ?? '';

            if (userId.isNotEmpty) {
              // 🔥 yaha ensure kar lo ki Firestore me call doc create ho jaye
              await createUserCallDocIfNeeded(userId);
            }

            // Future<void> createUserCallDocIfNeeded(String userId) async {
            //   final ref = FirebaseFirestore.instance.collection('calls').doc(userId);
            //   final s = await ref.get();
            //   if (!s.exists) {
            //     await ref.set({
            //       "status": "idle",
            //       "channelId": null,
            //       "callerId": null,
            //       "receiverId": null,
            //       "isCalling": false,
            //       "timestamp": FieldValue.serverTimestamp(),
            //     }, SetOptions(merge: true));
            //   }
            // }

            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //     builder: (_) => BlocProvider(
            //       create: (_) => JobBloc()..add(LoadJobsEvent()),
            //       child: BottomNavBar(),
            //     ),
            //   ),
            // );
          } else if (state is LoginFailure) {
            if (mounted) setState(() => _isSubmitting = false);   // ⬅️ unlock

            String msg = state.errorMessage.toString();

            // ✅ Agar socket ya API related error hai
            if (msg.contains("SocketException") ||
                msg.contains("Failed host lookup") ||
                msg.contains("timeout")) {
              msg = "Oops Something went wrong";
            }
            // ✅ Agar backend error hai (5xx response)
            else if (msg.contains("500") ||
                msg.contains("502") ||
                msg.contains("503") ||
                msg.contains("504") ||
                msg.toLowerCase().contains("internal server")) {
              msg = "Internal Server Error";
            }

            showErrorSnackBar(context, msg);
          }
        },
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  color: Color(0xFF003B47),
                  child: Stack(
                    children: [
                      // Positioned(
                      //   top: 5,
                      //   left: 170,
                      //   child: Image.asset('assets/logo2.png', width: 200, height: 190),
                      // ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/logo.png', width: 160, height: 60),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: BlocBuilder<LoginBloc, LoginState>(
                    builder: (context, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Login to your account",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff25282B), fontFamily: 'Inter'),
                            ),
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.only(left: 18.0),
                            child: Text("Enter your email address", style: TextStyle(color: Color(0xff003840), fontFamily: 'Inter')),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: emailController,
                            onChanged: (value) => context.read<LoginBloc>().add(EmailChanged(value)),
                            style: TextStyle(color: Color(0xff003840)),
                            decoration: InputDecoration(
                              hintText: "johndoe@email.com",
                              hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Inter'),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: ImageIcon(AssetImage('assets/mail.png'), color: Color(0xff003840), size: 18),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: Color(0xff003840), width: 2),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LoginWithOtp()),
                              ),
                              child: Text("Login with OTP", style: TextStyle(color: Color(0xff003840), fontFamily: 'Inter')),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.only(left: 18.0),
                            child: Text("Enter password", style: TextStyle(color: Color(0xff003840), fontFamily: 'Inter')),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            onChanged: (value) => context.read<LoginBloc>().add(PasswordChanged(value)),
                            style: TextStyle(color: Color(0xff003840)),
                            decoration: InputDecoration(
                              hintText: "********",
                              hintStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: ImageIcon(AssetImage('assets/lock.png'), color: Color(0xff003840), size: 18),
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Color(0xff003840)),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: Color(0xff003840), width: 2),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
                              ),
                              child: Text("Forgot password?", style: TextStyle(color: Color(0xff003840), fontFamily: 'Inter')),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null // ⛔ second tap disabled
                                  : () {

                                final email = emailController.text.trim();
                                final password = passwordController.text.trim();

                                if (email.isEmpty) {
                                  showErrorSnackBar(context, "Please enter your email address");
                                  return;
                                }


                                if (password.isEmpty) {
                                  showErrorSnackBar(context, "Please enter your password");
                                  return;
                                }

                                if (password.length < 6) {
                                  showErrorSnackBar(context, "Password must be at least 6 characters long");
                                  return;
                                }
                                setState(() => _isSubmitting = true);      // ⬅️ lock UI taps (except this handler)

                                context.read<LoginBloc>().add(LoginSubmitted(context: context));
                              },


                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                backgroundColor: Color(0xff005E6A),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text("Log In", style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Don’t have an account? ",
                                style: TextStyle(color: Color(0x80003840), fontFamily: 'Inter'),
                                children: [
                                  TextSpan(
                                    text: "Sign Up",
                                    style: const TextStyle(
                                      color: Color(0xff003840),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                      // decoration: TextDecoration.underline, // optional
                                    ),
                                    recognizer: _signUpRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ) ,
                          SizedBox(height: 20),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Want to list your college? ",
                                style: TextStyle(color: Color(0x80003840), fontFamily: 'Inter'),
                                children: [
                                  TextSpan(
                                    text: "Register it here",
                                    style: const TextStyle(
                                      color: Color(0xff003840),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                      // decoration: TextDecoration.underline, // optional
                                    ),
                                    recognizer: _registercollege,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> createUserCallDocIfNeeded(String userId) async {
    final ref = FirebaseFirestore.instance.collection('calls').doc(userId);
    final s = await ref.get();
    if (!s.exists) {
      await ref.set({
        "status": "idle",
        "channelId": null,
        "callerId": null,
        "receiverId": null,
        "isCalling": false,
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}


