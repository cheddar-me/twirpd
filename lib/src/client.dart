import 'dart:async';
import 'package:http/http.dart' as http;

import 'twirp_exception.dart';
import 'call_options.dart';
import 'client_interceptor.dart';
import 'client_method.dart';
import 'client_options.dart';
import 'http_response_parser.dart';

class Client {
  final String host;
  final int port;

  final ClientOptions _options;
  final List<ClientInterceptor> _interceptors;

  Client(
    this.host, {
    this.port = 443,
    ClientOptions? options,
    Iterable<ClientInterceptor>? interceptors,
  })  : _options = options ?? const ClientOptions(),
        _interceptors = List.unmodifiable(interceptors ?? Iterable.empty());

  Future<R> $call<Q, R>(
    ClientMethod<Q, R> method,
    Q request, {
    CallOptions? options,
  }) {
    var invoker = (method, request, options) {
      return _sendRequest<Q, R>(method, request, options);
    };

    var callOptions = CallOptions(
      metadata: {
        'User-Agent': _options.userAgent,
      },
    );

    for (final i in _interceptors.reversed) {
      final delegate = invoker;
      invoker = (method, request, options) {
        return i.intercept<Q, R>(method, request, options, delegate);
      };
    }

    return invoker(method, request, callOptions.mergedWith(options));
  }

  Future<R> _sendRequest<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
  ) {
    final uri = _buildUri(method.path);
    final headers = _buildHeaders(options);
    final body = method.requestSerializer(request);
    return http
        .post(uri, headers: headers, body: body)
        .then((response) => _parseResponse(response, method))
        .catchError((e) => throw _wrap(e));
  }

  Uri _buildUri(String path) {
    final prefix = _pathPrefix;
    final isSecure = _options.credentials.isSecure;
    final scheme = isSecure ? 'https' : 'http';
    var port;
    if (isSecure && this.port != 443) {
      port = this.port;
    } else if (!isSecure && this.port != 80) {
      port = this.port;
    }
    return Uri(scheme: scheme, host: host, port: port, path: '$prefix$path');
  }

  String get _pathPrefix {
    var prefix = _options.prefix;
    if (prefix.isNotEmpty && !prefix.startsWith('/')) {
      prefix = '/$prefix';
    }
    if (prefix.isNotEmpty && prefix.endsWith('/')) {
      prefix = prefix.substring(0, prefix.lastIndexOf('/'));
    }
    return prefix;
  }

  Map<String, String> _buildHeaders(CallOptions options) {
    final map = <String, String>{}..addAll(options.metadata);
    return Map.unmodifiable(
      map..addAll({'Content-Type': 'application/protobuf'}),
    );
  }

  R _parseResponse<Q, R>(http.Response response, ClientMethod<Q, R> method) {
    return HttpResponseParser.parse(response, method.responseDeserializer);
  }

  TwirpException _wrap(dynamic e) {
    if (e is TwirpException) {
      return e;
    }
    return TwirpException.internal(e.toString());
  }
}
