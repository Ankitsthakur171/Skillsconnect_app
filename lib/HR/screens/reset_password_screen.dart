//
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:skillsconnect/HR/screens/EnterOtpScreen.dart';
// import '../bloc/Reset_Password/reset_password_bloc.dart';
// import '../bloc/Reset_Password/reset_password_event.dart';
// import '../bloc/Reset_Password/reset_password_state.dart';
//
// class ResetPasswordScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => ResetPasswordBloc(),
//       child: Scaffold(
//         body: SingleChildScrollView(
//           child: Column(
//             children: [
//               // Top Section
//               Container(
//                 height: 280,
//                 width: double.infinity,
//                 color: const Color(0xFF003B47),
//                 child: Stack(
//                   children: [
//                     Positioned(
//                       top: 5,
//                       left: 170,
//                       child: Image.asset(
//                         'assets/logo2.png',
//                         width: 200,
//                         height: 190,
//                       ),
//                     ),
//                     Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Image.asset(
//                             'assets/logo.png',
//                             width: 180,
//                             height: 64,
//                           ),
//                         ],
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//
//               // Form Section
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//                 child: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
//                   listener: (context, state) {
//                     if (state.errorMessage.isNotEmpty) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(state.errorMessage),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                     }
//
//                     if (state.successMessage.isNotEmpty) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(state.successMessage),
//                           backgroundColor: Colors.green,
//                         ),
//                       );
//                       // Navigate to OTP screen:
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => EnterOtpScreen(email: state.email),
//                         ),
//                       );
//                     }
//                   },
//                   builder: (context, state) {
//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Center(
//                           child: Text(
//                             "Reset Password?",
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xff25282B),
//                             ),
//                           ),
//                         ),
//                         Center(
//                           child: Text(
//                             "Please provide your email to receive",
//                             style: TextStyle(fontSize: 14, color: Color(0xff003840)),
//                           ),
//                         ),
//                         Center(
//                           child: Text(
//                             "password reset instructions.",
//                             style: TextStyle(fontSize: 14, color: Color(0xff003840)),
//                           ),
//                         ),
//                         const SizedBox(height: 100),
//
//                         // Email Field
//                         const Padding(
//                           padding: EdgeInsets.only(left: 18.0),
//                           child: Text(
//                             "Enter your email address",
//                             style: TextStyle(color: Color(0xff003840)),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         TextFormField(
//                           onChanged: (value) => context
//                               .read<ResetPasswordBloc>()
//                               .add(EmailChanged(value)), // ✅ only update state
//                           style: const TextStyle(color: Color(0xff003840)),
//                           decoration: InputDecoration(
//                             hintText: "johndoe@email.com",
//                             hintStyle: const TextStyle(color: Colors.grey),
//                             prefixIcon: const Padding(
//                               padding: EdgeInsets.all(12.0),
//                               child: SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: ImageIcon(
//                                   AssetImage('assets/mail.png'),
//                                   color: Color(0xff003840),
//                                   size: 18,
//                                 ),
//                               ),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(30),
//                               borderSide: const BorderSide(color: Colors.grey),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(30),
//                               borderSide: const BorderSide(
//                                   color: Color(0xff003840), width: 2),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//
//                         // Submit Button
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () {
//                               if (state.email.isEmpty) {
//                                 showErrorSnackBar(context, "Email is required");
//                               } else {
//                                 // ✅ API call only here
//                                 context.read<ResetPasswordBloc>().add(SubmitReset());
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               backgroundColor: const Color(0xff005E6A),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                             ),
//                             child: state.isLoading
//                                 ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             )
//                                 : Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: const [
//                                 Text(
//                                   "Get OTP",
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                                 SizedBox(width: 10),
//                                 Icon(
//                                   Icons.arrow_forward,
//                                   color: Colors.white,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
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
//         style: const TextStyle(color: Colors.white, fontSize: 14),
//       ),
//       backgroundColor: Colors.red.shade600,
//       behavior: SnackBarBehavior.floating,
//       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       duration: const Duration(seconds: 2),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//     ),
//   );
// }










import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/HR/screens/EnterOtpScreen.dart';

import '../bloc/Reset_Password/reset_password_bloc.dart';
import '../bloc/Reset_Password/reset_password_event.dart';
import '../bloc/Reset_Password/reset_password_state.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResetPasswordBloc(),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Top Section
              Container(
                height: 280,
                width: double.infinity,
                color: const Color(0xFF003B47),
                child: Stack(
                  children: [
                    // Positioned(
                    //   top: 5,
                    //   left: 170,
                    //   child: Image.asset(
                    //     'assets/logo2.png',
                    //     width: 200,
                    //     height: 190,
                    //   ),
                    // ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            width: 180,
                            height: 64,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // Form Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
                  // ✅ Listener sirf tab chale jab success/error "change" ho
                  listenWhen: (prev, curr) {
                    final successChanged =
                        (prev.successMessage != curr.successMessage) &&
                            curr.successMessage.isNotEmpty;
                    final errorChanged =
                        (prev.errorMessage != curr.errorMessage) &&
                            curr.errorMessage.isNotEmpty;
                    print('🔍 LISTENWHEEN CHECK: successChanged=$successChanged, errorChanged=$errorChanged');
                    return successChanged || errorChanged;
                  },
                  listener: (context, state) async {
                    print('🔔 ═══════════════════════════════════════════════════════════');
                    print('🔔 LISTENER TRIGGERED ON ResetPasswordScreen');
                    print('🔔 errorMsg="${state.errorMessage}"');
                    print('🔔 successMsg="${state.successMessage}"');
                    print('🔔 isLoading=${state.isLoading}');
                    print('🔔 email="${state.email}"');
                    print('🔔 ═══════════════════════════════════════════════════════════');
                    
                    if (state.errorMessage.isNotEmpty) {
                      print('❌ SHOWING ERROR SNACKBAR: ${state.errorMessage}');
                      showErrorSnackBar(context,state.errorMessage);
                    }

                    if (state.successMessage.isNotEmpty) {
                      print('✅ SHOWING SUCCESS SNACKBAR: ${state.successMessage}');
                      showSuccesSnackBar(context, state.successMessage);

                      // ✅ Navigate ONLY once when successMessage turns non-empty
                      final email = state.email;
                      print('✅ SUCCESS! API accepted request');
                      print('✅ OTP email should be sent to: $email');
                      print('📱 NOW NAVIGATING to OTP screen...');
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EnterOtpScreen(email: email),
                        ),
                      );
                      print('📱 Returned from OTP screen');
                      // NOTE: listenWhen ki wajah se wapas aakar typing par
                      // listener dobara trigger nahi hoga jab tak message change na ho.
                    }
                  },

                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "Reset Password?",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff25282B),
                            ),
                          ),
                        ),
                        const Center(
                          child: Text(
                            "Please provide your email to receive",
                            style: TextStyle(fontSize: 14, color: Color(0xff003840)),
                          ),
                        ),
                        const Center(
                          child: Text(
                            "password reset instructions.",
                            style: TextStyle(fontSize: 14, color: Color(0xff003840)),
                          ),
                        ),
                        const SizedBox(height: 100),

                        // Email Field
                        const Padding(
                          padding: EdgeInsets.only(left: 18.0),
                          child: Text(
                            "Enter your email address",
                            style: TextStyle(color: Color(0xff003840)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          // ✅ Typing par sirf email update event — koi API nahi
                          onChanged: (value) =>
                              context.read<ResetPasswordBloc>().add(EmailChanged(value)),
                          style: const TextStyle(color: Color(0xff003840)),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "johndoe@email.com",
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: ImageIcon(
                                  AssetImage('assets/mail.png'),
                                  color: Color(0xff003840),
                                  size: 18,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                              const BorderSide(color: Color(0xff003840), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state.isLoading
                                ? null
                                : () {
                              print('🔘 SUBMIT BUTTON PRESSED');
                              print('📧 Current email in state: "${state.email}"');
                              print('⏳ isLoading: ${state.isLoading}');
                              
                              // ✅ Validate + API call SIRF yahin
                              if (state.email.isEmpty) {
                                print('⚠️ Email is empty, showing error');
                                showErrorSnackBar(context, "Email is required");
                                return;
                              }
                              // Optional: basic email check (UI level)
                              final ok = RegExp(
                                  r"^[\w\.\-+]+@[A-Za-z0-9\.\-]+\.[A-Za-z]{2,}$")
                                  .hasMatch(state.email);
                              if (!ok) {
                                print('⚠️ Email validation failed for: ${state.email}');
                                showErrorSnackBar(
                                    context, "Please enter a valid email");
                                return;
                              }
                              print('✅ Email validated, dispatching SubmitReset event');
                              context.read<ResetPasswordBloc>().add(SubmitReset());
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
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  "Get OTP",
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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

  void showSuccesSnackBar(BuildContext context, String successMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successMessage,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: Colors.green,
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

