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
    print('🚀 ═══════════════════════════════════════════════════════════');
    print('🚀 RESET PASSWORD BLOC: _handlePasswordReset called');
    print('📧 Email in state: "${state.email}"');
    print('📧 Email type: ${state.email.runtimeType}');
    print('📧 Email length: ${state.email.length}');
    print('📧 Email trimmed: "${state.email.trim()}"');
    print('🚀 ═══════════════════════════════════════════════════════════');
    
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    print('⏳ Emitted loading state');

    // ✅ COMPARE WITH LOGIN OTP
    print('🔍 COMPARING API ENDPOINTS:');
    print('   ✅ LOGIN OTP endpoint: auth/request-login-otp (uses "username" field)');
    print('   ❌ FORGOT PASSWORD endpoint: auth/forget-password (uses "email" field)');

    final url = Uri.parse('${BASE_URL}auth/forget-password');
    final body = jsonEncode({'email': state.email});
    
    print('🌐 BASE_URL: ${BASE_URL}');
    print('🌐 Final API URL: $url');
    print('📦 Request body: $body');

    try {
      print('📡 Sending POST request...');
      print('📡 Headers: {"Content-Type": "application/json"}');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('📥 ═══════════════════════════════════════════════════════════');
      print('📥 API RESPONSE RECEIVED!');
      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response body length: ${response.body.length}');
      print('📥 Response body: ${response.body}');
      print('📥 Response headers: ${response.headers}');

      final responseData = jsonDecode(response.body);
      print('📊 Parsed response:');
      print('   - status: ${responseData['status']}');
      print('   - msg: ${responseData['msg']}');
      print('   - full data: $responseData');
      print('📥 ═══════════════════════════════════════════════════════════');

      if (response.statusCode == 200 && responseData['status'] == true) {
        print('✅ SUCCESS: API accepted request');
        print('✅ Message: ${responseData['msg']}');
        print('✅ Backend SHOULD be sending OTP email to: ${state.email}');
        emit(state.copyWith(
          isLoading: false,
          successMessage: responseData['msg'] ?? 'OTP sent. Check your email!',
        ));
      } else {
        print('❌ ERROR: API rejected request');
        print('❌ Status code: ${response.statusCode}');
        print('❌ Response status field: ${responseData['status']}');
        print('❌ Error message: ${responseData['msg']}');
        print('⚠️  CHECK IF:');
        print('   1. Email exists in database?');
        print('   2. Email service is running on backend?');
        print('   3. Is API endpoint correct? (should be auth/forget-password)');
        emit(state.copyWith(
          isLoading: false,
          errorMessage: responseData['msg'] ?? 'Something went wrong.',
        ));
      }
    } catch (e) {
      print('💥 EXCEPTION during API call: $e');
      print('💥 Stack trace: ${StackTrace.current}');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send request: $e',
      ));
    }
  }

}
