import 'package:http/http.dart' as http;

import 'client_credentials.dart';

const _defaultUserAgent = 'twirp-dart/0.0.1';

/// Options for configuring a [Client].
class ClientOptions {
  final ClientCredentials credentials;
  final String prefix;
  final String userAgent;

  /// Base client to perform network requests. If null, IOClient is used.
  final http.Client? baseClient;

  const ClientOptions({
    this.credentials = const ClientCredentials.secure(),
    this.prefix = '/twirp',
    this.userAgent = _defaultUserAgent,
    this.baseClient,
  });
}
