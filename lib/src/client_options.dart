import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'client_credentials.dart';

const _defaultUserAgent = 'twirp-dart/0.0.1';

/// Options for configuring a [Client].
class ClientOptions {
  final ClientCredentials credentials;
  final String prefix;
  final String userAgent;
  final int maxRetries;
  final Duration Function(int retryCount) retryDelay;
  final bool Function(http.BaseResponse) whenRetry;

  const ClientOptions({
    this.credentials = const ClientCredentials.secure(),
    this.prefix = '/twirp',
    this.userAgent = _defaultUserAgent,
    this.maxRetries = 5,
    this.retryDelay = _defaultDelay,
    this.whenRetry = _defaultWhen,
  });
}

Duration _defaultDelay(int retryCount) =>
    const Duration(milliseconds: 200) * math.pow(2, retryCount);

bool _defaultWhen(http.BaseResponse response) =>
    response.statusCode == 429 || response.statusCode >= 500;
