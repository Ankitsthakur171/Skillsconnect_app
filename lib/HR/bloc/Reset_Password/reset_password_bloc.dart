import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../Constant/constants.dart';
import 'reset_password_event.dart';
import 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc() : super(ResetPasswordState()) {
    on<EmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email));
    });

    on<SubmitReset>(_handlePasswordReset);
  }

  Future<void> _handlePasswordReset(
      SubmitReset event, Emitter<ResetPasswordState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    final url = Uri.parse(
        '${BASE_URL}auth/forget-password');
    final body = jsonEncode({'email': state.email});

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
          successMessage: responseData['msg'] ?? 'Password reset email sent.',
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: responseData['msg'] ?? 'Something went wrong.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send request. Please try again later.',
      ));
    }
  }

}
