import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Constant/constants.dart';
import '../../utils/tpo_info_manager.dart';
import '../Model/my_account_model.dart';

class Tpoprofile {
  // fetch data from api
  Future<ProfileModel> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }

    final response = await http.post(
      Uri.parse('${BASE_URL}profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', //  Send token
      },
      body: jsonEncode({'action': 'my_profile'}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true && data['details'] != null) {
        // ⬇️ yahi naya parse:
        return ProfileModel.fromApi(data);
      } else {
        throw Exception('Invalid data format');
      }
    } else {
      throw Exception('Failed to load profile');
    }
  }
  /// 🔄 Header ko server se refresh kare (image + college)
  static Future<void> refreshHeaderFromServer() async {
    final profile = await Tpoprofile().fetchProfile();

    // cache-bust so the image actually reloads
    final stampedImg = (profile.imageUrl.isNotEmpty)
        ? '${profile.imageUrl}?v=${DateTime.now().millisecondsSinceEpoch}'
        : null;

    await UserInfoManager().setUserImage(stampedImg);
    await UserInfoManager().setCollegeName(profile.collegename);
  }


// Update data from api

  Future<bool> updateProfile({
    required String firstname,
    required String lastname,
    required String email,
    required String mobile,
    required String whatsappno,
    required String linkedin,
    String? gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // Get token from shared preferences

    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }
    final url = Uri.parse("${BASE_URL}profile/submit-tpo-profile");

    final body = {
      "first_name": firstname,
      "last_name": lastname,
      "email": email,
      "mobile": mobile,
      "whatsappnumber": whatsappno,
      "linkedin": linkedin,
      if (gender != null) "gender": gender,
    };


    final headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(url, headers: headers, body: json.encode(body));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["status"] == true;
    } else {
      throw Exception("Failed to update profile");
    }
  }


}
