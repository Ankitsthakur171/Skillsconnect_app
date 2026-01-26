// import 'dart:convert';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:skillsconnect/TPO/Model/tpo_contact_model.dart';
// import 'package:skillsconnect/TPO/Tpo_Contact/tpo_contact_event.dart';
// import 'package:skillsconnect/TPO/Tpo_Contact/tpo_contact_state.dart';
//
// import '../../Constant/constants.dart';
//
//
// class TpoContactBloc extends Bloc<TpoContactEvent, TpoContactState> {
//   TpoContactBloc() : super(ContactInitial()) {
//     on<TpoLoadContact>(_onLoadContacts);
//   }
//
//   Future<void> _onLoadContacts(
//       TpoLoadContact event, Emitter<TpoContactState> emit) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("auth_token");
//
//       // purane contacts preserve karo
//       final currentState = state;
//       List<TpoContactModel> oldContacts = [];
//       if (currentState is ContactLoaded && event.page > 1) {
//         oldContacts = currentState.contacts;
//       } else if (event.page == 1) {
//         emit(ContactLoading()); // sirf first page pe loader
//       }
//
//       final response = await http.get(
//         Uri.parse(
//             "${BASE_URL}calls?page=${event.page}&limit=${event.limit}"),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//       );
//
//       print("Response contacts: $response");
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//
//         List<TpoContactModel> newContacts = (data['data'] as List)
//             .map((json) => TpoContactModel.fromJson(json))
//             .toList();
//
//         // combine old + new
//         final allContacts = [...oldContacts, ...newContacts];
//
//         // agar naye items limit se kam aaye, toh hasMore = false
//         final hasMore = newContacts.length == event.limit;
//
//         emit(ContactLoaded(allContacts, hasMore: hasMore));
//       } else {
//         emit(ContactError("Failed to load contacts: ${response.statusCode}"));
//       }
//     } catch (e) {
//       emit(ContactError("Error: $e"));
//     }
//   }
// }


import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/TPO/Model/tpo_contact_model.dart';
import 'package:skillsconnect/TPO/Tpo_Contact/tpo_contact_event.dart';
import 'package:skillsconnect/TPO/Tpo_Contact/tpo_contact_state.dart';

import '../../Constant/constants.dart';

class TpoContactBloc extends Bloc<TpoContactEvent, TpoContactState> {
  TpoContactBloc() : super(ContactInitial()) {
    on<TpoLoadContact>(_onLoadContacts);
  }

  // 🔒 concurrency + throttling
  bool _inFlight = false;
  DateTime _lastHitAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _minGap = Duration(milliseconds: 900); // 0.9s gap between hits
  int _lastServedPage = 0; // duplicate page calls ko skip


  Future<void> _onLoadContacts(
      TpoLoadContact event,
      Emitter<TpoContactState> emit,
      ) async {
    try {
      // 🔁 duplicate/overlap guard
      if (_inFlight) {
        print("⛔️ Skip: request already in-flight");
        return;
      }
      if (event.page <= _lastServedPage && event.page != 1) {
        print("⛔️ Skip: duplicate page request ${event.page}");
        return;
      }

      // ⏳ throttle (avoid 429 on rapid scroll)
      final since = DateTime.now().difference(_lastHitAt);
      if (since < _minGap) {
        final wait = _minGap - since;
        print("⏳ Throttling for ${wait.inMilliseconds}ms");
        await Future.delayed(wait);
      }
      _inFlight = true;

      print("🔹 TpoContactBloc: Fetching contacts for page=${event.page}, limit=${event.limit}");
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      print("🔹 Auth token: $token");

      // purane contacts preserve karo
      final currentState = state;
      List<TpoContactModel> oldContacts = [];
      if (currentState is ContactLoaded && event.page > 1) {
        oldContacts = currentState.contacts;
        print("🔹 Old contacts preserved: ${oldContacts.length}");
      } else if (event.page == 1) {
        print("🔹 First page load — showing loader");
        emit(ContactLoading()); // sirf first page pe loader
      }

      final url = "${BASE_URL}calls?page=${event.page}&limit=${event.limit}";
      print("🔹 API URL: $url");

      Future<http.Response> _hit() => http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      // 🔂 call + one soft retry on 429
      http.Response response = await _hit();
      print("🔹 Response status: ${response.statusCode}");
      print("🔹 Raw response body: ${response.body}");

      if (response.statusCode == 429) {
        // Retry-After header ka respect (agar ho), warna 1s
        final retryAfter = response.headers['retry-after'];
        final waitSecs = int.tryParse(retryAfter ?? '') ?? 1;
        final backoff = Duration(seconds: waitSecs) + const Duration(milliseconds: 200);
        print("🔁 429 received. Backing off for ${backoff.inMilliseconds}ms then retrying...");
        await Future.delayed(backoff);
        response = await _hit();
        print("🔹 Retry status: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("🔹 Parsed response data: $data");

        final List<TpoContactModel> newContacts = (data['data'] as List)
            .map((json) => TpoContactModel.fromJson(json))
            .toList();

        print("🔹 New contacts fetched: ${newContacts.length}");

        final allContacts = [...oldContacts, ...newContacts];
        print("🔹 Total combined contacts: ${allContacts.length}");

        final hasMore = newContacts.length == event.limit;
        print("🔹 hasMore: $hasMore");

        // success -> advance markers
        _lastServedPage = event.page;
        _lastHitAt = DateTime.now();

        emit(ContactLoaded(allContacts, hasMore: hasMore));
      } else if (response.statusCode == 429) {
        // still ratelimited: soft-fail, state ko stable rakho (no error splash)
        print("❌ Still 429 after retry; keeping previous state to avoid flicker.");
        if (currentState is ContactLoaded) {
          emit(ContactLoaded(currentState.contacts, hasMore: true));
        } else {
          emit( ContactError("Too many requests, please try again later."));
        }
      } else {
        print("❌ Failed to load contacts. Status code: ${response.statusCode}");
        emit(ContactError("Failed to load contacts: ${response.statusCode}"));
      }
    } catch (e, stack) {
      print("❌ Exception while loading contacts: $e");
      print("❌ Stacktrace: $stack");
      emit(ContactError("Error: $e"));
    } finally {
      _inFlight = false;
    }
  }

}
