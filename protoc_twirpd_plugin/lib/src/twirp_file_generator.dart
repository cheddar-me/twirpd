// @dart=2.11

import 'package:protoc_plugin/protoc.dart';
import 'package:protoc_plugin/indenting_writer.dart';
import 'package:protoc_plugin/src/descriptor.pb.dart';
import 'package:protoc_plugin/src/plugin.pb.dart';
import 'package:dart_style/src/dart_formatter.dart';
import 'twirp_service_generator.dart';
import 'constants.dart';

final _formatter = DartFormatter();

class TwirpFileGenerator extends FileGenerator {
  final twirpGenerators = <TwirpServiceGenerator>[];
  var _linked = false;

  TwirpFileGenerator(
    FileDescriptorProto descriptor,
    GenerationOptions options,
  ) : super(descriptor, options) {
    for (var service in descriptor.service) {
      twirpGenerators.add(TwirpServiceGenerator(service, this));
    }
    serviceGenerators.clear();
    clientApiGenerators.clear();
  }

  @override
  void resolve(GenerationContext ctx) {
    super.resolve(ctx);
    _linked = true;
  }

  @override
  List<CodeGeneratorResponse_File> generateFiles(OutputConfiguration config) {
    final files = super.generateFiles(config);
    files.removeWhere((f) => f.name.endsWith('.pbserver.dart'));
    files.removeWhere((f) => f.name.endsWith('.pbjson.dart'));
    if (twirpGenerators.isNotEmpty) {
      final protoUrl = Uri.file(descriptor.name);
      final dartUrl = config.outputPathFor(protoUrl, '.pbtwirp.dart');
      final file = CodeGeneratorResponse_File();
      file.name = dartUrl.path;
      file.content = generateTwirpFile(config);
      files.add(file);
    }
    return files;
  }

  String generateTwirpFile([
    OutputConfiguration config = const DefaultOutputConfiguration(),
  ]) {
    {
      if (!_linked) throw StateError("not linked");
      final out = makeWriter();
      _writeHeading(out);

      out.println(asyncImport);
      out.println();
      out.println(coreImport);
      out.println();
      out.println(twirpImport);

      // import .pb.dart files needed for requests and responses.
      final imports = <FileGenerator>{};
      for (final generator in twirpGenerators) {
        generator.addImportsTo(imports);
      }
      for (final target in imports) {
        _writeImport(out, config, target, ".pb.dart");
      }

      final resolvedImport = config.resolveImport(
        protoFileUri,
        protoFileUri,
        ".pb.dart",
      );
      out.println("export '$resolvedImport';");
      out.println();

      for (final generator in twirpGenerators) {
        generator.generate(out);
      }

      return _formatter.format(out.toString());
    }
  }

  /// Writes the header at the top of the dart file.
  void _writeHeading(IndentingWriter out) {
    out.println('///');
    out.println('//  Generated code. Do not modify.');
    out.println('//  source: ${descriptor.name}');
    out.println('//');
    out.println('// @dart = 2.12');
    out.println(
        '// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields');
    out.println();
  }

  /// Writes an import of a .dart file corresponding to a .proto file.
  /// (Possibly the same .proto file.)
  void _writeImport(
    IndentingWriter out,
    OutputConfiguration config,
    FileGenerator target,
    String extension,
  ) {
    var resolvedImport =
        config.resolveImport(target.protoFileUri, protoFileUri, extension);
    out.print("import '$resolvedImport'");
    if ((extension == ".pb.dart") || protoFileUri != target.protoFileUri) {
      out.print(' as ${target.fileImportPrefix}');
    }
    out.println(';');
  }
}
