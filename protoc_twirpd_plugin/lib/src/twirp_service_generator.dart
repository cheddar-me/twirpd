// @dart=2.11

import 'package:protoc_plugin/protoc.dart';
import 'package:protoc_plugin/indenting_writer.dart';
import 'package:protoc_plugin/src/descriptor.pb.dart';
import 'constants.dart';

class TwirpServiceGenerator {
  final ServiceDescriptorProto _descriptor;

  /// The generator of the .pb.dart file that will contain this service.
  final FileGenerator fileGen;

  /// The message types needed directly by this service.
  ///
  /// The key is the fully qualified name.
  /// Populated by [resolve].
  final _deps = <String, MessageGenerator>{};

  /// Maps each undefined type to a string describing its location.
  ///
  /// Populated by [resolve].
  final _undefinedDeps = <String, String>{};

  /// Fully-qualified Twirp service name.
  String _fullServiceName;

  /// Dart class name for client stub.
  String _clientClassname;

  /// List of Twirp methods.
  final _methods = <_TwirpMethod>[];

  TwirpServiceGenerator(this._descriptor, this.fileGen) {
    final name = _descriptor.name;
    final package = fileGen.package;

    if (package != null && package.isNotEmpty) {
      _fullServiceName = '$package.$name';
    } else {
      _fullServiceName = name;
    }

    // avoid: ClientClient
    _clientClassname = name.endsWith('Client') ? name : name + 'Client';
  }

  /// Finds all message types used by this service.
  ///
  /// Puts the types found in [_deps]. If a type name can't be resolved, puts it
  /// in [_undefinedDeps].
  /// Precondition: messages have been registered and resolved.
  void resolve(GenerationContext ctx) {
    for (var method in _descriptor.method) {
      if (!method.clientStreaming && !method.serverStreaming) {
        _methods.add(_TwirpMethod(this, ctx, method));
      }
    }
  }

  /// Adds a dependency on the given message type.
  ///
  /// If the type name can't be resolved, adds it to [_undefinedDeps].
  void _addDependency(GenerationContext ctx, String fqname, String location) {
    if (_deps.containsKey(fqname)) return; // Already added.

    MessageGenerator mg = ctx.getFieldType(fqname);
    if (mg == null) {
      _undefinedDeps[fqname] = location;
      return;
    }
    mg.checkResolved();
    _deps[mg.dottedName] = mg;
  }

  /// Adds dependencies of [generate] to [imports].
  ///
  /// For each .pb.dart file that the generated code needs to import,
  /// add its generator.
  void addImportsTo(Set<FileGenerator> imports) {
    for (var mg in _deps.values) {
      imports.add(mg.fileGen);
    }
  }

  /// Returns the Dart class name to use for a message type.
  ///
  /// Throws an exception if it can't be resolved.
  String _getDartClassName(String fqname) {
    var mg = _deps[fqname];
    if (mg == null) {
      var location = _undefinedDeps[fqname];
      // TODO(nichite): Throw more actionable error.
      throw 'FAILURE: Unknown type reference (${fqname}) for ${location}';
    }
    return mg.fileImportPrefix + '.' + mg.classname;
  }

  void generate(IndentingWriter out) {
    _generateClient(out);
  }

  void _generateClient(IndentingWriter out) {
    out.addBlock('class $_clientClassname extends $_client {', '}', () {
      for (final method in _methods) {
        method.generateClientMethodDescriptor(out);
      }
      out.println();
      out.println('$_clientClassname($coreImportPrefix.String host, {');
      out.println('  $coreImportPrefix.int port = 443,');
      out.println('  $_clientOptions? options,');
      out.println('  $coreImportPrefix.Iterable<$_interceptor>? interceptors,');
      out.println(
          '}) : super(host, port: port, options: options, interceptors: interceptors);');
      out.println();
      for (final method in _methods) {
        method.generateClientStub(out);
      }
    });
  }

  static final String _clientOptions = '$twirpImportPrefix.ClientOptions';
  static final String _interceptor = '$twirpImportPrefix.ClientInterceptor';
  static final String _client = '$twirpImportPrefix.Client';
}

class _TwirpMethod {
  final String _twirpName;
  final String _dartName;
  final String _serviceName;

  final String _requestType;
  final String _responseType;

  final String _argumentType;
  final String _clientReturnType;

  _TwirpMethod._(
    this._twirpName,
    this._dartName,
    this._serviceName,
    this._requestType,
    this._responseType,
    this._argumentType,
    this._clientReturnType,
  );

  factory _TwirpMethod(TwirpServiceGenerator service, GenerationContext ctx,
      MethodDescriptorProto method) {
    final twirpName = method.name;
    final dartName =
        twirpName.substring(0, 1).toLowerCase() + twirpName.substring(1);

    service._addDependency(ctx, method.inputType, 'input type of $twirpName');
    service._addDependency(ctx, method.outputType, 'output type of $twirpName');

    final requestType = service._getDartClassName(method.inputType);
    final responseType = service._getDartClassName(method.outputType);
    final clientReturnType = '$asyncImportPrefix.Future<$responseType>';

    return _TwirpMethod._(
      twirpName,
      dartName,
      service._fullServiceName,
      requestType,
      responseType,
      requestType,
      clientReturnType,
    );
  }

  void generateClientMethodDescriptor(IndentingWriter out) {
    out.println(
        'static final _\$$_dartName = $_clientMethod<$_requestType, $_responseType>(');
    out.println('    \'/$_serviceName/$_twirpName\',');
    out.println('    ($_requestType value) => value.writeToBuffer(),');
    out.println(
        '    ($coreImportPrefix.List<$coreImportPrefix.int> value) => $_responseType.fromBuffer(value));');
  }

  void generateClientStub(IndentingWriter out) {
    out.println();
    out.addBlock(
      '$_clientReturnType $_dartName($_argumentType request, {$_callOptions? options}) {',
      '}',
      () {
        out.println('return \$call(_\$$_dartName, request, options: options);');
      },
    );
  }

  static final String _callOptions = '$twirpImportPrefix.CallOptions';
  static final String _clientMethod = '$twirpImportPrefix.ClientMethod';
}
