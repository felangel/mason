import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:universal_io/io.dart';

import '../bundler.dart';
import '../command.dart';
import '../io.dart';

/// Supported Bundle Types
enum BundleType {
  /// Bundle Type which is supported by mason natively
  universal,

  /// Dart-specific bundle type (usually used when building Dart CLI Apps)
  dart
}

/// {@template bundle_command}
/// `mason bundle` command exposes the ability to generate bundles
/// from brick templates.
/// {@endtemplate}
class BundleCommand extends MasonCommand {
  /// {@macro bundle_command}
  BundleCommand({Logger? logger}) : super(logger: logger) {
    argParser
      ..addOption(
        'output-dir',
        abbr: 'o',
        help: 'Directory where to output the generated bundle.',
        defaultsTo: '.',
      )
      ..addOption(
        'type',
        abbr: 't',
        help: 'Type of bundle to generate.',
        allowed: ['universal', 'dart'],
        defaultsTo: 'universal',
      );
  }

  @override
  final String description = 'Generates a bundle from a brick template.';

  @override
  final String name = 'bundle';

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) {
      throw UsageException(
        'path to the brick template must be provided',
        usage,
      );
    }
    final brick = Directory(results.rest.first);
    if (!brick.existsSync()) {
      throw MasonException('could not find brick at ${brick.path}');
    }

    final bundle = await createBundle(brick);
    final outputDir = results['output-dir'] as String;
    final bundleType = (results['type'] as String).toBundleType();

    switch (bundleType) {
      case BundleType.dart:
        File(path.join(outputDir, '${bundle.name}_bundle.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync(
            "// GENERATED CODE - DO NOT MODIFY BY HAND\n// ignore_for_file: prefer_single_quotes, public_member_api_docs, lines_longer_than_80_chars\n\nimport 'package:mason/mason.dart';\n\nfinal ${bundle.name.camelCase}Bundle = MasonBundle.fromJson(<String, dynamic>${json.encode(bundle.toJson())});",
          );
        break;
      case BundleType.universal:
        File(path.join(outputDir, '${bundle.name}.bundle'))
          ..createSync(recursive: true)
          ..writeAsStringSync(json.encode(bundle.toJson()));
        break;
    }

    return ExitCode.success.code;
  }
}

extension on String {
  BundleType toBundleType() {
    switch (this) {
      case 'dart':
        return BundleType.dart;
      case 'universal':
      default:
        return BundleType.universal;
    }
  }
}
