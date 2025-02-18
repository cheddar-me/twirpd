![https://github.com/twitchtv/twirp/blob/main/logo.png](https://github.com/twitchtv/twirp/blob/main/logo.png)

# Twirpd - Twirp client for Dart

A client implementation of the awesome Twirp Specification written in Dart.

## Getting started
### Installation

Add the depenendcy to your app's pubspec.yaml (and run an implicit flutter pub get):
```yaml
dependencies:
  twirpd: <latest_version>
```

### Install Protoc
Make sure you have protoc or buf installed.

**Mac:**
```
brew install protobuf
```
**Linux:**
```
apt-get install protobuf
```

## Code Generation
**twirpd** relies on [twirpd-protoc-plugin](https://github.com/cheddar-me/twirpd-protoc-plugin) to generate protobuf message definitions and client code

First you need to install `twirpd-protoc-plugin` by running:
```
dart pub global activate twirpd-protoc-plugin
```
Then you can use `protoc` command to generate all needed files:
```
protoc \
  --twirpd_out={PATH_TO_OUTPUT_DIR} \
  -I {PATH_TO_DIR_WITH_PROTOS} {PROTO_FILE_NAMES}
```
For example:
```
protoc \
  --twirpd_out=lib/src/generated \
  -I proto my_service.proto
```

If you are using external Google proto messages, you can include them in the command, for example:
```
protoc \
  --twirpd_out=lib/src/generated \
  -I proto my_service.proto google/protobuf/timestamp.proto
```

This should generate all the code you need.

## Using it
Let's consider HelloWorld service:
```proto
syntax = "proto3";

service HelloWorld {
  rpc Hello(HelloReq) returns (HelloResp);
}

message HelloReq {
  string subject = 1;
}

message HelloResp {
  string text = 1;
}
```
The HelloWorldClient class is already generated for you and ready to use:
```dart
HelloWorldClient client = HelloWorldClient(
  'https://yourbackend.com',
  port: 8080,
);
```
It has all the methods defined in the `proto` file:
```dart
HelloReq request = HelloReq(subject: 'Hey mom!');
HelloResp response = await client.hello(request);
print(response.text);
```

## Customization
### ClientInterceptors
You can add your own client interceptors to change the request you're about to send.
```dart
HelloWorldClient client = HelloWorldClient(
  'https://yourbackend.com',
  port: 8080,
  interceptors: [
    MyCredentialsInterceptor(),
  ],
);
```
For example to add credentials headers:
```dart
class MyCredentialsInterceptor implements ClientInterceptor {
  final MyCredentialsStorage storage;

  const MyCredentialsInterceptor(this.storage);

  @override
  Future<R> intercept<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientCallInvoker<Q, R> invoker,
  ) {
    return invoker(method, request, _addAuthToken(options));
  }

  CallOptions _addAuthToken(CallOptions options) {
    return options.mergedWith(CallOptions(
      metadata: {'authorization': 'Bearer ${storage.authToken}'},
    ));
  }
}
```

### Using own http client
twirpd uses plain `Client` from `http` package under the hood. By default it creates `IOClient` but you can provide other implementation, for example RetryClient:
```dart
HelloWorldClient client = HelloWorldClient(
  'https://yourbackend.com',
  port: 8080,
  options: ClientOptions(
    client: RetryClient(), //<-- Any http client
  ),
);
```

### Call Options
You can also set extra metadata through `CallOptions` if you want to change the behavior of a specific request invocation. The `metadata` is added to the headers and can be also picked up by the interceptors.
```dart
await client.hello(
  request,
  options: CallOptions(
    metadata: {'specific_header': 'Only for this call'}, 
  ),
);
```

## Learn more
- [Announcing Twirp](https://blog.twitch.tv/en/2018/01/16/twirp-a-sweet-new-rpc-framework-for-go-5f2febbf35f/)
- [Meet Twirp!](https://twitchtv.github.io/twirp/docs/intro.html)
- [Twitch's twirp repository](https://github.com/twitchtv/twirp)



Made with 💛 at [Cheddar](https://cheddar.me/).
