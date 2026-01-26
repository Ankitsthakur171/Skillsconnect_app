import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Model/PersonalDetail_Model.dart';
import '../ApiConstants.dart';

class PersonalDetailApi {
  static Future<List<PersonalDetailModel>> fetchPersonalDetails({
  required String authToken,
  required String connectSid,
}) async {
    try{
      var url = Uri.parse(
         ApiConstantsStu.personalDetailApi,
      );
      var headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };
      var request = http.Request('GET', url);
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      if(response.statusCode == 200){
        final String jsonString = await response.stream.bytesToString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        final List<dynamic> personalDetail = data ['personalDetails'] ?? [] ;

        return personalDetail
            .map((e) => PersonalDetailModel.fromJson(e))
            .toList();
      } else {
        throw Exception('Failed to load personal details');
      }
    } catch (e) {
      print('❌ Error in personaldetailapi: $e');
      return [];
    }
  }
}