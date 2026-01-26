// contact_bloc.dart
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Constant/constants.dart';
import '../../model/contact_model.dart';
import 'contact_event.dart';
import 'contact_state.dart';

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  ContactBloc() : super(ContactInitial()) {
    on<LoadContacts>(_onLoadContacts);
  }

  Future<void> _onLoadContacts(
      LoadContacts event, Emitter<ContactState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      final currentState = state;
      List<Contact> oldContacts = [];
      if (currentState is ContactLoaded && event.page > 1) {
        oldContacts = currentState.contacts;
      } else {
        emit(ContactLoading());
      }

      final response = await http.get(
        Uri.parse(
          "${BASE_URL}calls?page=${event.page}&limit=${event.limit}",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<Contact> newContacts = (data['data'] as List)
            .map((json) => Contact.fromJson(json))
            .toList();

        final allContacts = [...oldContacts, ...newContacts];

        final hasMore = newContacts.length == event.limit;

        emit(ContactLoaded(allContacts, hasMore: hasMore));
      } else {
        emit(ContactError("Failed to load contacts: ${response.statusCode}"));
      }
    } catch (e) {
      emit(ContactError("Error: $e"));
    }
  }
}
