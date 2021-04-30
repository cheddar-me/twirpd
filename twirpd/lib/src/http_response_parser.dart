import 'dart:convert';
import 'package:http/http.dart' as http;

import 'twirp_exception.dart';
import 'twirp_exception_helper.dart';

class HttpResponseParser {
  static R parse<R>(
    http.Response response,
    R Function(List<int> value) responseDeserializer,
  ) {
    if (response.statusCode == 200) {
      return responseDeserializer(response.bodyBytes);
    }
    throw _parseError(response);
  }

  static TwirpException _parseError(http.Response response) {
    if (response.statusCode >= 300 && response.statusCode <= 399) {
      final status = _statusFromResponse(response);
      final location = response.headers['Location'] ?? '';
      final message =
          'unexpected HTTP status code $status received, Location=$location';
      return _errorFromIntermediary(response.statusCode, message, location);
    }

    final json = _decodeResponse(response);
    final code = _extractErrorCode(json);
    final message = _extractMessage(json);
    final metadata = _extractMetadata(json);
    if (code != null && message != null && metadata != null) {
      return TwirpException(code, message, metadata);
    }

    final status = _statusFromResponse(response);
    final msg = 'Error from intermediary with HTTP status code $status';
    return _errorFromIntermediary(response.statusCode, msg, response.body);
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      return json is Map<String, dynamic> ? json : {};
    } catch (e) {
      return {};
    }
  }

  static String? _extractMessage(Map<String, dynamic> json) {
    return json['msg'] is String ? json['msg'] : null;
  }

  static ErrorCode? _extractErrorCode(Map<String, dynamic> json) {
    return json['code'] is String ? stringToErrorCodeMap[json['code']] : null;
  }

  static Map<String, String>? _extractMetadata(Map<String, dynamic> json) {
    if (!json.containsKey('meta')) {
      return {};
    }
    if (json['meta'] is Map<String, String>) {
      return json['meta'];
    }
    return null;
  }

  static String _statusFromResponse(http.Response response) =>
      response.reasonPhrase != null
          ? '${response.statusCode} ${response.reasonPhrase}'
          : response.statusCode.toString();

  static TwirpException _errorFromIntermediary(
    int statusCode,
    String message,
    String bodyOrLocation,
  ) {
    final code = _errorCodeFromStatus(statusCode);
    final metadata = <String, String>{
      'http_error_from_intermediary': 'true',
      'status_code': statusCode.toString(),
      if (statusCode >= 300 && statusCode <= 399)
        'location': bodyOrLocation
      else
        'body': bodyOrLocation
    };
    return TwirpException(code, message, metadata);
  }

  static ErrorCode _errorCodeFromStatus(int status) {
    if (status >= 300 && status <= 399) {
      return ErrorCode.Internal;
    }
    switch (status) {
      case 400:
        return ErrorCode.Internal;
      case 401:
        return ErrorCode.Unauthenticated;
      case 403:
        return ErrorCode.PermissionDenied;
      case 404:
        return ErrorCode.BadRoute;
      case 429:
        return ErrorCode.Unavailable;
      case 502:
        return ErrorCode.Unavailable;
      case 503:
        return ErrorCode.Unavailable;
      case 504:
        return ErrorCode.Unavailable;
      default:
        return ErrorCode.Unknown;
    }
  }
}
