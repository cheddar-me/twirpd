import 'call_options.dart';
import 'client_method.dart';

typedef ClientCallInvoker<Q, R> = Future<R> Function(
    ClientMethod<Q, R> method, Q request, CallOptions options);

abstract class ClientInterceptor {
  Future<R> intercept<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientCallInvoker<Q, R> invoker,
  );
}
