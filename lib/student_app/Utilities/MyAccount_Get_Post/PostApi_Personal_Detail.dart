import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Model/PersonalDetailPost_Model.dart';
import '../ApiConstants.dart';

class PersonalDetailPostApi {
  static Future<void> updatePersonalDetails({
    required PersonalDetailUpdateRequest request,
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String dob,
    required String state,
    required String city,
    required VoidCallback onSuccess,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      print('🌐 Step 2: Resolving State ID for "$state"...');
      final stateId = await _resolveStateId(state);
      print('✅ State ID: $stateId');

      final cityId = await _resolveCityId(city, stateId);

      var headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      var body = json.encode({
        "first_name": firstName,
        "last_name": lastName,
        "dob": dob,
        "gender": "Female",
        "country": 101,
        "state": int.tryParse(stateId),
        "city": int.tryParse(cityId),
        "pincode": "000000",
        "linkedin": "",
        "bio": "",
      });


      var response = await http.post(
        Uri.parse(ApiConstantsStu.updatePersonalDetail),
        headers: headers,
        body: body,
      );


      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        print('📦 Response body: $res');
        print('❌ Response body: ${response.body}');

        if (res["status"] == true) {
          print('✅ Step 6: onSuccess triggered');
          onSuccess();
        } else {
          print('❌ Server responded with error message: ${res["msg"]}');
          _showError(context, res["msg"] ?? "Something went wrong");
        }
      } else {
        print('❌ Server responded with status: ${response.statusCode}');
        _showError(context, "Server error: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      _showError(context, "Unexpected error: $e");
    }
  }


  static Future<String> _resolveStateId(String stateName) async {

    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    final response = await http.post(
      Uri.parse(ApiConstantsStu.stateListUrl),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      },
      body: json.encode({"country_id": 101, "state_name": stateName}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == true && data["data"] is List && data["data"].isNotEmpty) {
        return data["data"][0]["id"].toString();
      }
    }

    return '';
  }

  static Future<String> _resolveCityId(String cityName, String stateId) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    final response = await http.post(
      Uri.parse(ApiConstantsStu.city_list),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      },
      body: json.encode({
        "state_id": stateId,
        "city_name": cityName,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == true && data["data"] is List && data["data"].isNotEmpty) {
        return data["data"][0]["id"].toString();
      }
    }

    return '';
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
