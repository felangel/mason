import 'dart:convert';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/install_brick.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:universal_io/io.dart';

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
class BundleCommand extends MasonCommand with InstallBrickMixin {
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
      )
      ..addOption(
        'source',
        abbr: 's',
        help: 'The source used to find the brick to be bundled.',
        allowed: ['git', 'path', 'registry'],
        defaultsTo: 'path',
      )
      ..addOption(
        'git-ref',
        help: 'Git branch or commit to be used.'
            ' Only valid if source is set to "git".',
      )
      ..addOption(
        'git-path',
        help: 'Path of the brick in the git repository'
            ' Only valid if source is set to "git".',
      );
  }

  @override
  final String description = 'Generates a bundle from a brick template.';

  @override
  final String name = 'bundle';

  @override
  Future<int> run() async {
    final source = results['source'] as String;

    late final rest = results.rest.first;

    final Brick brick;
    if (source == 'git') {
      if (results.rest.isEmpty) {
        usageException('A repository url must be provided');
      }
      brick = Brick(
        location: BrickLocation(
          git: GitPath(
            rest,
            path: results['git-path'] as String?,
            ref: results['git-ref'] as String?,
          ),
        ),
      );
    } else if (source == 'registry') {
      if (results.rest.isEmpty) {
        usageException('A brick name must be provided');
      }
      brick = Brick(name: rest, location: const BrickLocation(version: 'any'));
    } else {
      if (results.rest.isEmpty) {
        usageException('A path to the brick template must be provided');
      }
      brick = Brick(location: BrickLocation(path: rest));
    }

    final String brickPath;
    if (brick.location.isLocal) {
      brickPath = brick.location.path!;
    } else {
      final cachedBrick = await globalBricksJson.add(brick);
      brickPath = cachedBrick.path;
    }

    final bundle = createBundle(brickPath);
    final outputDir = results['output-dir'] as String;
    final bundleType = (results['type'] as String).toBundleType();
    final bundleProgress = logger.progress('Bundling ${bundle.name}');

    try {
      late final String bundlePath;
      switch (bundleType) {
        case BundleType.dart:
          bundlePath = await _generateDartBundle(bundle, outputDir);
          break;
        case BundleType.universal:
          bundlePath = await _generateUniversalBundle(bundle, outputDir);
          break;
      }
      bundleProgress.complete('Bundled ${bundle.name}');
      logger
        ..info(
          '${lightGreen.wrap('✓')} '
          'Generated 1 file:',
        )
        ..detail('  $bundlePath');
    } catch (_) {
      bundleProgress.fail();
      rethrow;
    }

    return ExitCode.success.code;
  }
}

Future<String> _generateDartBundle(
  MasonBundle bundle,
  String outputDir,
) async {
  final file = File(path.join(outputDir, '${bundle.name}_bundle.dart'));
  await file.create(recursive: true);
  await file.writeAsString(
    "// GENERATED CODE - DO NOT MODIFY BY HAND\n// ignore_for_file: prefer_single_quotes, public_member_api_docs, lines_longer_than_80_chars, implicit_dynamic_list_literal, implicit_dynamic_map_literal\n\nimport 'package:mason/mason.dart';\n\nfinal ${bundle.name.camelCase}Bundle = MasonBundle.fromJson(<String, dynamic>${json.encode(bundle.toJson())});",
  );
  return canonicalize(file.path);
}

Future<String> _generateUniversalBundle(
  MasonBundle bundle,
  String outputDir,
) async {
  final file = File(path.join(outputDir, '${bundle.name}.bundle'));
  await file.create(recursive: true);
  await file.writeAsBytes(await bundle.toUniversalBundle());
  return canonicalize(file.path);
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
