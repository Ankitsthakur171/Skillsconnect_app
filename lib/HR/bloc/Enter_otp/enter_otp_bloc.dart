// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'enter_otp_event.dart';
// import 'enter_otp_state.dart';
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class EnterOtpBloc extends Bloc<EnterOtpEvent, EnterOtpState> {
//   EnterOtpBloc() : super(EnterOtpState()) {
//     on<OtpChanged>((event, emit) {
//       emit(state.copyWith(otp: event.otp));
//     });
//
//     on<PasswordChanged>((event, emit) {
//       emit(state.copyWith(password: event.password));
//     });
//
//     on<SubmitOtp>(_handleSubmitOtp);
//   }
//
//
//   Future<void> _handleSubmitOtp(
//       SubmitOtp event, Emitter<EnterOtpState> emit) async {
//     emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
//
//     final url = Uri.parse(
//         'https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/auth/change-password');
//
//     final body = jsonEncode({
//       "email": event.email,
//       "otp": int.tryParse(state.otp), // OTP should be integer
//       "password": state.password,
//     });
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: body,
//       );
//
//       final responseData = jsonDecode(response.body);
//
//       if (response.statusCode == 200 && responseData['status'] == true) {
//         emit(state.copyWith(
//           isLoading: false,
//           successMessage: responseData['msg'] ?? 'Password updated successfully',
//         ));
//       } else {
//         emit(state.copyWith(
//           isLoading: false,
//           errorMessage: responseData['msg'] ?? 'Something went wrong',
//         ));
//       }
//     } catch (e) {
//       emit(state.copyWith(
//         isLoading: false,
//         errorMessage: 'Network error. Please try again later.',
//       ));
//     }
//   }
//
// }
//
//
//
//
//


import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../Constant/constants.dart';
import 'enter_otp_event.dart';
import 'enter_otp_state.dart';

class EnterOtpBloc extends Bloc<EnterOtpEvent, EnterOtpState> {
  EnterOtpBloc() : super(EnterOtpState()) {
    // OTP change event
    on<OtpChanged>((event, emit) {
      emit(state.copyWith(otp: event.otp));
    });

    // Verify OTP event
    // on<VerifyOtp>((event, emit) async {
    //   final isValid = await verifyOtpFromApi(event.email, event.otp);
    //   emit(state.copyWith(otpVerified: isValid));
    // });

    // Verify OTP event
    on<VerifyOtp>((event, emit) async {
      print('🔍 BLOC: VerifyOtp event received - email: ${event.email}, otp: ${event.otp}');
      final isValid = await verifyOtpFromApi(event.email, event.otp);
      print('🔍 BLOC: OTP verification result: $isValid');

      if (isValid) {
        print('✅ BLOC: OTP verified successfully');
        emit(state.copyWith(otpVerified: true, errorMessage: "", successMessage: ""));
      } else {
        print('❌ BLOC: OTP verification failed');
        emit(state.copyWith(
          otpVerified: false,
          errorMessage: "OTP incorrect", // ✅ yahin set karo
          successMessage: "",
        ));
      }
    });


    // Resend OTP event
    on<ResendOtp>((event, emit) async {
      print('🔄 BLOC: ResendOtp event received for email: ${event.email}');
      await resendOtpApi(event.email);
      print('✅ BLOC: Resend OTP API call completed');
      
      // Clear both error and show success message, reset verification
      emit(state.copyWith(
        successMessage: "OTP resent successfully", 
        errorMessage: "",  // ✅ Clear old error message
        otpVerified: null  // ✅ Reset verification status
      ));
      print('✅ BLOC: Emitted success state for resend OTP');

      // 👇 Clear success message but KEEP errorMessage cleared
      emit(state.copyWith(
        successMessage: "",
        errorMessage: "",  // ✅ Keep it cleared!
      ));
      print('🔄 BLOC: Cleared success message, errorMessage stays cleared');
    });


    // Password change event
    on<PasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password));
    });

    // Submit OTP & change password
    on<SubmitOtp>(_handleSubmitOtp);
  }

  /// ---- API CALLS ----

  // OTP verify API
  Future<bool> verifyOtpFromApi(String email, String otp) async {
    print('🌐 BLOC: verifyOtpFromApi called - email: $email, otp: $otp');
    try {
      final url = Uri.parse(
          '${BASE_URL}auth/verify-otp');

      final body = jsonEncode({"email": email, "otp": int.tryParse(otp)});
      print('📦 BLOC: Verify OTP request body: $body');
      print('🌐 BLOC: Verify OTP URL: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('📥 BLOC: Verify OTP response - Status: ${response.statusCode}');
      print('📄 BLOC: Verify OTP response body: ${response.body}');

      final data = jsonDecode(response.body);
      print('📊 BLOC: Parsed verify OTP data: $data');

      final result = response.statusCode == 200 && data['status'] == true;
      print('🎯 BLOC: Verify OTP result: $result');
      return result;
    } catch (e) {
      print('💥 BLOC: Exception in verifyOtpFromApi: $e');
      return false;
    }
  }

  // Resend OTP API
  Future<void> resendOtpApi(String email) async {
    print('🔄 ═══════════════════════════════════════════════════════════');
    print('🔄 BLOC: resendOtpApi called');
    print('📧 BLOC: Email: $email');
    print('📧 BLOC: Email type: ${email.runtimeType}');
    print('📧 BLOC: Email length: ${email.length}');
    print('📧 BLOC: Email trimmed: "${email.trim()}"');
    
    try {
      final url = Uri.parse(
          '${BASE_URL}auth/forget-password');  // ✅ Use same endpoint as initial forgot password
      
      final body = jsonEncode({"email": email});
      print('📦 BLOC: Resend OTP request body: $body');
      print('🌐 BLOC: Resend OTP URL: $url');
      print('📡 BLOC: Headers: {"Content-Type": "application/json"}');
      print('📡 BLOC: Sending POST request...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      print('📥 ═══════════════════════════════════════════════════════════');
      print('📥 BLOC: Resend OTP response received!');
      print('📥 BLOC: Status Code: ${response.statusCode}');
      print('📥 BLOC: Response body length: ${response.body.length}');
      print('📥 BLOC: Response body: ${response.body}');
      print('📥 BLOC: Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 BLOC: Parsed resend OTP data: $data');
        print('📊 BLOC: Response status: ${data['status']}');
        print('📊 BLOC: Response msg: ${data['msg']}');
        
        if (data['status'] == true) {
          print('✅ BLOC: Resend OTP API accepted request - email should be sent');
        } else {
          print('⚠️  BLOC: API returned status false - check error message: ${data['msg']}');
        }
      } else {
        print('❌ BLOC: Resend OTP failed with status code ${response.statusCode}');
      }
      print('📥 ═══════════════════════════════════════════════════════════');
    } catch (e) {
      print('💥 BLOC: Exception in resendOtpApi: $e');
      print('💥 BLOC: Stack trace: ${StackTrace.current}');
    }
  }

  /// ---- PASSWORD CHANGE ----
  Future<void> _handleSubmitOtp(
      SubmitOtp event, Emitter<EnterOtpState> emit) async {
    print('🚀 BLOC: _handleSubmitOtp called');
    print('📧 BLOC: Email: ${event.email}');
    print('🔢 BLOC: OTP in state: "${state.otp}"');
    print('🔒 BLOC: Password in state: "${state.password}"');
    
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    print('⏳ BLOC: Emitted loading state');

    final url = Uri.parse(
        '${BASE_URL}auth/change-password');

    final body = jsonEncode({
      "email": event.email,
      "otp": int.tryParse(state.otp),
      "password": state.password,
    });
    
    print('🌐 BLOC: Change password URL: $url');
    print('📦 BLOC: Change password request body: $body');

    try {
      print('📡 BLOC: Sending POST request for password change...');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('📥 BLOC: Response received - Status: ${response.statusCode}');
      print('📄 BLOC: Response body: ${response.body}');

      final responseData = jsonDecode(response.body);
      print('📊 BLOC: Parsed response data: $responseData');

      if (response.statusCode == 200 && responseData['status'] == true) {
        print('✅ BLOC: Password change successful');
        emit(state.copyWith(
          isLoading: false,
          successMessage:
          responseData['msg'] ?? 'Password updated successfully',
        ));
        print('✅ BLOC: Emitted success state with message: "${responseData['msg']}"');
      } else {
        print('❌ BLOC: Password change failed - status: ${responseData['status']}');
        emit(state.copyWith(
          isLoading: false,
          errorMessage: responseData['msg'] ?? 'Something went wrong',
        ));
        print('❌ BLOC: Emitted error state with message: "${responseData['msg']}"');
      }
    } catch (e) {
      print('💥 BLOC: Exception caught: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again later.',
      ));
      print('❌ BLOC: Emitted error state due to exception');
    }
  }
}
