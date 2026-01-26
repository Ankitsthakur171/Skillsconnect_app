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
      final isValid = await verifyOtpFromApi(event.email, event.otp);

      if (isValid) {
        emit(state.copyWith(otpVerified: true, errorMessage: "", successMessage: ""));
      } else {
        emit(state.copyWith(
          otpVerified: false,
          errorMessage: "OTP incorrect", // ✅ yahin set karo
          successMessage: "",
        ));
      }
    });


    // Resend OTP event
    on<ResendOtp>((event, emit) async {
      await resendOtpApi(event.email);
      emit(state.copyWith(successMessage: "OTP resent successfully"));

      // 👇 turant reset so that listener fire na ho baar-baar
      emit(state.copyWith(successMessage: ""));
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
    try {
      final url = Uri.parse(
          '${BASE_URL}auth/verify-otp');

      final body = jsonEncode({"email": email, "otp": int.tryParse(otp)});

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final data = jsonDecode(response.body);

      return response.statusCode == 200 && data['status'] == true;
    } catch (e) {
      return false;
    }
  }

  // Resend OTP API
  Future<void> resendOtpApi(String email) async {
    try {
      final url = Uri.parse(
          '${BASE_URL}auth/resend-otp');

      final body = jsonEncode({"email": email});

      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
    } catch (_) {}
  }

  /// ---- PASSWORD CHANGE ----
  Future<void> _handleSubmitOtp(
      SubmitOtp event, Emitter<EnterOtpState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    final url = Uri.parse(
        '${BASE_URL}auth/change-password');

    final body = jsonEncode({
      "email": event.email,
      "otp": int.tryParse(state.otp),
      "password": state.password,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        emit(state.copyWith(
          isLoading: false,
          successMessage:
          responseData['msg'] ?? 'Password updated successfully',
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: responseData['msg'] ?? 'Something went wrong',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Please try again later.',
      ));
    }
  }
}
