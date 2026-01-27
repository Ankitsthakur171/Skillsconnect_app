import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/Dashboard_Model.dart';

class HomeScreenDashboardApi {
  static Future<DashboardData?> fetchDashboard({String? customUrl}) async {
    try {
      print('📡 [HomeScreenDashboardApi] Fetching dashboard data...');

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      print('🔐 Auth Token: ${authToken.isEmpty ? "MISSING" : "OK (${authToken.length} chars)"}');
      print('🔐 Connect SID: ${connectSid.isEmpty ? "MISSING (will proceed without it)" : "OK"}');

      if (authToken.isEmpty) {
        print('⚠️ Missing authToken - cannot proceed');
        return null;
      }

      // Build headers - use authToken even if connectSid is missing
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      // Build cookie string
      List<String> cookieParts = [];
      if (authToken.isNotEmpty) cookieParts.add('authToken=$authToken');
      if (connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');
      
      if (cookieParts.isNotEmpty) {
        headers['Cookie'] = cookieParts.join('; ');
      }

      // Build URL - dashboard endpoint is NOT under /mobile/ path
      // Use baseUrl + projectId instead of subUrl (which includes /mobile/)
      final url = customUrl != null 
          ? Uri.parse(customUrl)
          : Uri.parse('https://api.skillsconnect.in/dcxqyqzqpdydfk/website/dashboard/student');
      print('📍 URL: $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 20));

      print('📊 Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ Failed: ${response.statusCode}');
        print('Response: ${response.body.substring(0, (response.body.length > 300 ? 300 : response.body.length))}');
        return null;
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonResponse['status'] != true) {
        print('❌ API status false');
        return null;
      }

      final data = jsonResponse['data'] as Map<String, dynamic>?;
      if (data == null) {
        print('❌ No data field');
        return null;
      }

      final dashboard = DashboardData.fromJson(data);
      print('✅ Dashboard loaded: ${dashboard.profile.name}');
      return dashboard;
    } catch (e) {
      print('❌ Error: $e');
      return null;
    }
  }
}
