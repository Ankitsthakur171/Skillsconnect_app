// lib/errors/api_error.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

sealed class ApiFailure {
  final String title;
  final String message;
  final int? statusCode;
  final Object? raw;
  final StackTrace? stack;
  const ApiFailure(this.title, this.message, {this.statusCode, this.raw, this.stack});

  Map<String, dynamic> toLog() => {
    "title": title,
    "message": message,
    "statusCode": statusCode,
    "raw": raw?.toString(),
  };

  static ApiFailure from(Object error, [StackTrace? stack]) {
    // Dio error (optional) without importing dio
    final isDioError = error.runtimeType.toString().contains('DioException');
    if (isDioError) {
      final err = error;
      int? code;
      String? bodyText;
      try {
        final res = (err as dynamic).response;
        code = res?.statusCode;
        final data = res?.data;
        if (data is String) bodyText = data;
        if (data is Map) bodyText = jsonEncode(data);
      } catch (_) {}

      // 🔴 detect 403 subscription expired
      if (code == 403 && bodyText != null) {
        try {
          final m = json.decode(bodyText);
          if (m is Map && m['success'] == false) {
            final msg = (m['message'] ?? '').toString();
            if (msg.isNotEmpty) {
              return ApiSubscriptionExpiredFailure(
                message: msg,
                statusCode: 403,
                rawBody: bodyText,
                raw: error,
                stack: stack,
              );
            }
          }
        } catch (_) {}
      }


      String reason = 'Something went wrong.';
      try {
        final res = (err as dynamic).response;
        code = res?.statusCode;
        final data = res?.data;
        if (data is Map && data["message"] is String) {
          reason = data["message"];
        } else if (data is String && data.isNotEmpty) {
          reason = data;
        } else if (res?.statusMessage != null) {
          reason = res.statusMessage;
        }
      } catch (_) {}
      return ApiHttpFailure(statusCode: code, body: reason, raw: error, stack: stack);
    }

    if (error is TimeoutException) {
      return ApiTimeoutFailure(raw: error, stack: stack);
    }
    if (error is SocketException) {
      // NOTE: Tumhare paas offline page alag hai. Yaha bhi dikhana chaho to rehne do.
      return ApiSocketFailure(raw: error, stack: stack);
    }
    if (error is HandshakeException || error is TlsException) {
      return ApiTlsFailure(raw: error, stack: stack);
    }

    // HTTP (package:http) style or generic
    if (error is HttpException) {
      return ApiHttpFailure(statusCode: null, body: error.message, raw: error, stack: stack);
    }

    // JSON/parse
    if (error is FormatException) {
      return ApiParseFailure(raw: error, stack: stack);
    }

    // Fallback
    return ApiUnknownFailure(raw: error, stack: stack);
  }
}

class ApiHttpFailure extends ApiFailure {
  ApiHttpFailure({int? statusCode, String? body, Object? raw, StackTrace? stack})
      : super(
    'Server Error',
    _pretty(body, statusCode),
    statusCode: statusCode,
    raw: raw,
    stack: stack,
  );

  static String _pretty(String? body, int? code) {
    final base = (code != null) ? 'HTTP $code' : 'HTTP error';
    if (body == null || body.trim().isEmpty) return '$base occurred.';
    if (_isJson(body)) {
      try {
        final map = json.decode(body);
        final msg = map['message'] ?? map['error'] ?? map['detail'] ?? map.toString();
        return '$base: $msg';
      } catch (_) {}
    }
    return '$base: $body';
  }

  static bool _isJson(String s) {
    final t = s.trim();
    return (t.startsWith('{') && t.endsWith('}')) || (t.startsWith('[') && t.endsWith(']'));
  }
}

class ApiTimeoutFailure extends ApiFailure {
  ApiTimeoutFailure({Object? raw, StackTrace? stack})
      : super('Request Timeout', 'The server took too long to respond.', raw: raw, stack: stack);
}

class ApiSocketFailure extends ApiFailure {
  ApiSocketFailure({Object? raw, StackTrace? stack})
      : super('Network Error', 'A network error occurred while calling the API.', raw: raw, stack: stack);
}

class ApiTlsFailure extends ApiFailure {
  ApiTlsFailure({Object? raw, StackTrace? stack})
      : super('Secure Connection Error', 'TLS/Handshake failed for the API call.', raw: raw, stack: stack);
}

class ApiParseFailure extends ApiFailure {
  ApiParseFailure({Object? raw, StackTrace? stack})
      : super('Data Error', 'Unexpected response format from server.', raw: raw, stack: stack);
}

class ApiUnknownFailure extends ApiFailure {
  ApiUnknownFailure({Object? raw, StackTrace? stack})
      : super('Unexpected Error', 'Something went wrong while calling the API.', raw: raw, stack: stack);
}


class ApiSubscriptionExpiredFailure extends ApiFailure {
  final String rawBody;
  ApiSubscriptionExpiredFailure({
    required String message,
    int? statusCode,
    this.rawBody = '',
    Object? raw,
    StackTrace? stack,
  }) : super('Subscription Expired', message, statusCode: statusCode, raw: raw, stack: stack);
}