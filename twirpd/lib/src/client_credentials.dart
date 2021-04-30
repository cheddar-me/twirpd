class ClientCredentials {
  final bool isSecure;

  const ClientCredentials._(this.isSecure);
  const ClientCredentials.insecure() : this._(false);
  const ClientCredentials.secure() : this._(true);
}
