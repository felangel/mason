import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

import '../bundler.dart';
import '../command.dart';

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
  BundleCommand({Logger logger}) : super(logger: logger) {
    argParser
      ..addOption(
        'destination',
        abbr: 'd',
        help: 'destination where to write the generated bundle',
        defaultsTo: '.',
      )
      ..addOption(
        'type',
        abbr: 't',
        help: 'type of bundle to generate (universal or dart)',
        defaultsTo: 'universal',
      );
  }

  @override
  final String description = 'Generates a bundle from a brick template';

  @override
  final String name = 'bundle';

  @override
  Future<int> run() async {
    if (argResults.rest.isEmpty) {
      throw UsageException(
        'path to the brick template must be provided',
        usage,
      );
    }
    final brick = Directory(argResults.rest.first);
    if (!brick.existsSync()) {
      throw MasonException('could not find brick at ${brick.path}');
    }

    final bundle = await createBundle(brick);
    final destination = argResults['destination'] as String;
    final bundleType = (argResults['type'] as String).toBundleType();

    switch (bundleType) {
      case BundleType.dart:
        File(path.join(destination, '${bundle.name}_bundle.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync(
            "// GENERATED CODE - DO NOT MODIFY BY HAND\n// ignore_for_file: prefer_single_quotes, public_member_api_docs\n\nimport 'package:mason/mason.dart';\n\nfinal ${bundle.name.camelCase}Bundle = MasonBundle.fromJson(${json.encode(bundle.toJson())});",
          );
        break;
      case BundleType.universal:
        File(path.join(destination, '${bundle.name}.bundle'))
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
