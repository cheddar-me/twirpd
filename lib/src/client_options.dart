import 'client_credentials.dart';

const _defaultUserAgent = 'twirp-dart/0.0.1';

/// Options for configuring a [Client].
class ClientOptions {
  final ClientCredentials credentials;
  final String prefix;
  final String userAgent;

  const ClientOptions({
    this.credentials = const ClientCredentials.secure(),
    this.prefix = '/twirp',
    this.userAgent = _defaultUserAgent,
  });
}
