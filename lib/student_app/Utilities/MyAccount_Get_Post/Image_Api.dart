import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Model/Image_update_Model.dart';
import '../ApiConstants.dart';

class LoadImageApi {
  static Future<ImageUpdateModel?> fetchUserImage({
    required String authToken,
    required String connectSid,
  }) async {
    try {
      final url = Uri.parse(
        ApiConstantsStu.accountScreenUrl,
      );

      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      final request = http.Request('GET', url);
      request.headers.addAll(headers);

      final response = await request.send();

      if (response.statusCode == 200) {
        final jsonString = await response.stream.bytesToString();
        final Map<String, dynamic> data = jsonDecode(jsonString);


        final List<dynamic> personalDetails = data['personalDetails'] ?? [];

        if (personalDetails.isNotEmpty && personalDetails.first is Map<String, dynamic>) {
          final userData = personalDetails.first as Map<String, dynamic>;
          return ImageUpdateModel.fromJson(userData);
        } else {
          print("! personalDetails list is empty or invalid");
          return null;
        }
      } else {
        throw Exception('❌ Failed to load image: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Error in LoadImageApi: $e');
      return null;
    }
  }
}
