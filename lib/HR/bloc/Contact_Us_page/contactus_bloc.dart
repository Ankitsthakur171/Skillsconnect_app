// lib/bloc/contact_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
// lib/repository/contact_repository.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'contactus_event.dart';
import 'contactus_state.dart';

class ContactUsBloc extends Bloc<ContactUsEvent, ContactUsState> {
  final ContactRepository repository;

  ContactUsBloc(this.repository) : super(ContactInitial()) {
    on<SubmitContactForm>((event, emit) async {
      emit(ContactLoading());
      try {
        final result = await repository.sendContactForm(
          name: event.name,
          phone: event.phone,
          email: event.email,
          subject: event.subject,
          message: event.message,
        );

        if (result["status"] == true) {
          emit(ContactUsSuccess(result["msg"] ?? "Message sent successfully"));
        } else {
          emit(ContactUsFailure("Something went wrong"));
        }
      } catch (e) {
        emit(ContactUsFailure(e.toString()));
      }
    });
  }
}











class ContactRepository {
  final String apiUrl = "https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/contact";

  Future<Map<String, dynamic>> sendContactForm({
    required String name,
    required String phone,
    required String email,
    required String subject,
    required String message,
  }) async {
    // 🔹 SharedPreferences se token nikalna
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final body = {
      "name": name,
      "phone": phone,
      "email": email,
      "subject": subject,
      "message": message,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token", // ✅ Token add
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to send contact form (Status: ${response.statusCode})");
    }
  }
}

