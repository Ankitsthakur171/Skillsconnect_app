import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/LoginwithOtp/otp_login_bloc.dart';
import '../bloc/LoginwithOtp/otp_login_event.dart';
import '../bloc/LoginwithOtp/otp_login_state.dart';
import 'EnterOtpScreen.dart';

class LoginWithOtp extends StatelessWidget {
  const LoginWithOtp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpLoginBloc(),
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
                    ),
                  ],
                ),
              ),

              // Form Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: BlocConsumer<OtpLoginBloc, OtpLoginState>(
                  listenWhen: (prev, curr) {
                    final successChanged =
                        (prev.successMessage != curr.successMessage) &&
                        curr.successMessage.isNotEmpty;
                    final errorChanged =
                        (prev.errorMessage != curr.errorMessage) &&
                        curr.errorMessage.isNotEmpty;
                    return successChanged || errorChanged;
                  },
                  listener: (context, state) {
                    if (state.errorMessage.isNotEmpty) {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text(state.errorMessage),
                      //     backgroundColor: Colors.red,
                      //   ),
                      // );
                      showErrorSnackBar(context, state.errorMessage);
                    }
                    if (state.successMessage.isNotEmpty) {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text(state.successMessage),
                      //     backgroundColor: Colors.green,
                      //   ),
                      // );
                      showSuccessSnackBar(context, state.successMessage);

                    }
                  },
                  builder: (context, state) {
                    final bloc = context.read<OtpLoginBloc>();
                    final canResend =
                        state.resendSecondsLeft == 0 && !state.isLoading;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "Login with OTP",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff25282B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (state.step == OtpLoginStep.enterEmail) ...[
                          const Padding(
                            padding: EdgeInsets.only(left: 18.0),
                            child: Text(
                              "Enter your email or phone",
                              style: TextStyle(color: Color(0xff003840)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            onChanged: (v) => bloc.add(OtpEmailChanged(v)),
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
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xff003840),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () => bloc.add(const OtpRequestSubmitted()),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                        ] else ...[
                          // === OTP STEP ===
                          SizedBox(height: 20,),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // ✅ center me karega
                            children: [
                              Flexible(
                                child: RichText(
                                  overflow: TextOverflow
                                      .ellipsis, // ✅ ellipsis lagayega
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: "OTP sent to ",
                                        style: TextStyle(
                                          color: Color(0xff003840),
                                        ),
                                      ),
                                      TextSpan(
                                        text: state.email.length > 20
                                            ? "${state.email.substring(0, 20)}..." // ✅ 20 char ke baad ...
                                            : state.email,
                                        style: const TextStyle(
                                          color: Color(0xff003840),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () => bloc.add(const OtpEditEmailPressed()),
                              child: const Text(
                                "Change",
                                style: TextStyle(color: Color(0xff005E6A)),
                              ),
                            ),
                          ),
                          TextFormField(
                            onChanged: (v) => bloc.add(OtpCodeChanged(v)),
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              letterSpacing: 6,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: "____",
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xff003840),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          // NEW: Full-width Verify button below, Resend on its own line
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: canResend
                                  ? () => bloc.add(const OtpResendRequested())
                                  : null,
                              child: Text(
                                canResend
                                    ? "Resend OTP"
                                    : "Resend in ${state.resendSecondsLeft}s",
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () => bloc.add(OtpVerifySubmitted(context)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16), // same feel as Get OTP
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
                                "Verify & Login",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),


                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     TextButton(
                          //       onPressed: state.isLoading ? null : () => bloc.add(const OtpResendRequested()),
                          //       child: const Text("Resend OTP"),
                          //     ),
                          //     SizedBox(
                          //       width: 160,
                          //       child: ElevatedButton(
                          //         onPressed: state.isLoading ? null : () => bloc.add(OtpVerifySubmitted(context)),
                          //         style: ElevatedButton.styleFrom(
                          //           padding: const EdgeInsets.symmetric(vertical: 14),
                          //           backgroundColor: const Color(0xff005E6A),
                          //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          //         ),
                          //         child: state.isLoading
                          //             ? const SizedBox(
                          //           width: 18,
                          //           height: 18,
                          //           child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          //         )
                          //             : const Text("Verify & Login", style: TextStyle(color: Colors.white)),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
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


}
