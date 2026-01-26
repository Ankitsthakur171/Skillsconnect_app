import 'dart:convert';

class ContactRequest {
  final String name;
  final String phone;
  final String email;
  final String subject;
  final String message;

  ContactRequest({
    required this.name,
    required this.phone,
    required this.email,
    required this.subject,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'subject': subject,
    'message': message,
  };

  String toRawJson() => json.encode(toJson());
}

class ContactResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final int statusCode;

  ContactResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  factory ContactResponse.fromJson(Map<String, dynamic> json, int statusCode) {
    final msg = json['message']?.toString() ??
        json['msg']?.toString() ??
        json['error']?.toString() ??
        '';
    final successFlag = json['success'] == true || (statusCode >= 200 && statusCode < 300);

    return ContactResponse(
      success: successFlag,
      message: msg,
      data: json,
      statusCode: statusCode,
    );
  }

  factory ContactResponse.fromRawJson(String str, int statusCode) {
    try {
      if (str.trim().isEmpty) {
        return ContactResponse(
          success: false,
          message: 'Empty response body',
          data: null,
          statusCode: statusCode,
        );
      }
      final parsed = json.decode(str);
      if (parsed is Map<String, dynamic>) {
        return ContactResponse.fromJson(parsed, statusCode);
      } else {
        return ContactResponse(
          success: statusCode >= 200 && statusCode < 300,
          message: parsed.toString(),
          data: {'value': parsed},
          statusCode: statusCode,
        );
      }
    } catch (e) {
      return ContactResponse(
        success: false,
        message: 'Non-JSON response: ${str.trim()}',
        data: null,
        statusCode: statusCode,
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data,
    'statusCode': statusCode,
  };
}
