// lib/HR/bloc/UpdatePassword/update_password_bloc.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Constant/constants.dart';
import 'update_password_event.dart';
import 'update_password_state.dart';

class UpdatePasswordBloc extends Bloc<UpdatePasswordEvent, UpdatePasswordState> {
  UpdatePasswordBloc() : super(UpdatePasswordState.initial()) {
    on<CurrentPasswordChanged>((e, emit) {
      emit(state.copyWith(currentPassword: e.currentPassword));
    });
    on<NewPasswordChanged>((e, emit) {
      emit(state.copyWith(newPassword: e.newPassword));
    });
    on<ConfirmPasswordChanged>((e, emit) {
      emit(state.copyWith(confirmPassword: e.confirmPassword));
    });
    on<SubmitPasswordUpdate>(_handleSubmit);
  }

  Future<void> _handleSubmit(
      SubmitPasswordUpdate event,
      Emitter<UpdatePasswordState> emit,
      ) async {

    print('🔹 Password update submit triggered');
    print('Current Password: ${state.currentPassword}');
    print('New Password: ${state.newPassword}');
    print('Confirm Password: ${state.confirmPassword}');
    print('Email received from event: ${event.email}');


    if (state.currentPassword.isEmpty ||
        state.newPassword.isEmpty ||
        state.confirmPassword.isEmpty) {
      emit(state.copyWith(isFailure: true, errorMessage: "Please fill all fields"));
      return;
    }
    if (state.newPassword != state.confirmPassword) {
      emit(state.copyWith(isFailure: true, errorMessage: "Passwords do not match"));
      return;
    }

    emit(state.copyWith(isSubmitting: true, isFailure: false, isSuccess: false, errorMessage: ''));

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // ✅ Prefer UI-provided email; fallback to prefs if (rarely) empty
      final emailFromUi = (event.email).trim();
      final email = emailFromUi.isNotEmpty
          ? emailFromUi
          : (prefs.getString('email') ?? prefs.getString('user_email') ?? '');

      print('🧩 Using email: $email');
      print('🪪 Token: $token');

      if (email.isEmpty) {
        print('❌ Email not found in prefs or event');
        emit(state.copyWith(
          isSubmitting: false,
          isFailure: true,
          errorMessage: "Email not found. Please re-login.",
        ));
        return;
      }

      final url = Uri.parse(
        '${BASE_URL}auth/change-password-logged',

      );
      print('🌐 API URL: $url');


      final body = jsonEncode({
        "email": email,
        "current_password": state.currentPassword,
        "new_password": state.newPassword,
      });
      print('📦 Request body: $body');

      final resp = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) {
        emit(state.copyWith(
          isSubmitting: false,
          isFailure: true,
          errorMessage: 'Failed with status ${resp.statusCode}',
        ));
        return;
      }

      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      final ok = map['status'] == true;
      final msg = (map['msg'] ?? map['message'] ?? '').toString();

      if (ok) {
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      } else {
        emit(state.copyWith(
          isSubmitting: false,
          isFailure: true,
          errorMessage: msg.isNotEmpty ? msg : 'Password update failed',
        ));
      }
    } on SocketException {
      emit(state.copyWith(
        isSubmitting: false,
        isFailure: true,
        errorMessage: "Network error. Please check your connection.",
      ));
    } on TimeoutException {
      emit(state.copyWith(
        isSubmitting: false,
        isFailure: true,
        errorMessage: "Request timed out. Try again.",
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        isFailure: true,
        errorMessage: e.toString(),
      ));
    }
  }
}
