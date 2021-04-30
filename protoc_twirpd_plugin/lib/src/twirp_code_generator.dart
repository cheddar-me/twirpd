// @dart=2.11

import 'dart:io';
import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protoc_plugin/protoc.dart';
import 'package:protoc_plugin/src/dart_options.pb.dart';
import 'package:protoc_plugin/src/plugin.pb.dart';

import 'twirp_file_generator.dart';

class TwirpCodeGenerator extends CodeGenerator {
  final Stream<List<int>> _streamIn;
  final IOSink _streamOut;

  TwirpCodeGenerator(
    Stream<List<int>> streamIn,
    IOSink streamOut,
  )   : _streamIn = streamIn,
        _streamOut = streamOut,
        super(streamIn, streamOut);

  @override
  void generate({
    Map<String, SingleOptionParser> optionParsers,
    OutputConfiguration config,
  }) {
    config ??= DefaultOutputConfiguration();
    final parsers = {...?optionParsers};

    var extensions = ExtensionRegistry();
    Dart_options.registerAllExtensions(extensions);

    _streamIn
        .fold(
            BytesBuilder(), (BytesBuilder builder, data) => builder..add(data))
        .then((builder) => builder.takeBytes())
        .then((List<int> bytes) {
      var request = CodeGeneratorRequest.fromBuffer(bytes, extensions);
      var response = CodeGeneratorResponse();

      // Parse the options in the request. Return the errors is any.
      var options = _parseGenerationOptions(request, response, parsers);
      if (options == null) {
        _streamOut.add(response.writeToBuffer());
        return;
      }

      // Create a syntax tree for each .proto file given to us.
      // (We may import it even if we don't generate the .pb.dart file.)
      var generators = <TwirpFileGenerator>[];
      for (var file in request.protoFile) {
        generators.add(TwirpFileGenerator(file, options));
      }

      // Collect field types and importable files.
      _link(options, generators);

      // Generate the .pb.dart file if requested.
      for (var gen in generators) {
        var name = gen.descriptor.name;
        if (request.fileToGenerate.contains(name)) {
          response.file.addAll(gen.generateFiles(config));
        }
      }
      response.supportedFeatures =
          Int64(CodeGeneratorResponse_Feature.FEATURE_PROTO3_OPTIONAL.value);

      _streamOut.add(response.writeToBuffer());
    });
  }

  GenerationOptions _parseGenerationOptions(
    CodeGeneratorRequest request,
    CodeGeneratorResponse response,
    Map<String, SingleOptionParser> optionParsers,
  ) {
    final metadataParser = GenerateMetadataParser();
    final parsers = {
      ...?optionParsers,
      'kythe': metadataParser,
    };
    if (genericOptionsParser(request, response, parsers)) {
      return GenerationOptions(
        useGrpc: false,
        generateMetadata: metadataParser.generateKytheInfo,
      );
    }
    return null;
  }

  /// Resolves all cross-references in a set of proto files.
  void _link(
    GenerationOptions options,
    Iterable<TwirpFileGenerator> files,
  ) {
    var ctx = GenerationContext(options);

    // Register the targets of cross-references.
    for (var f in files) {
      ctx.registerProtoFile(f);

      for (var m in f.messageGenerators) {
        m.register(ctx);
      }
      for (var e in f.enumGenerators) {
        e.register(ctx);
      }
    }

    for (var f in files) {
      f.resolve(ctx);
    }

    for (var f in files) {
      for (var s in f.twirpGenerators) {
        s.resolve(ctx);
      }
    }
  }
}
