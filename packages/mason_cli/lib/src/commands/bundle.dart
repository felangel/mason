import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

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
      )
      ..addOption(
        'source',
        abbr: 's',
        help: 'The source used to find the brick to be bundled.',
        allowed: ['git', 'path', 'hosted'],
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

    final Brick brick;
    if (source == 'git') {
      if (results.rest.isEmpty) {
        usageException('A repository url must be provided');
      }
      brick = Brick(
        location: BrickLocation(
          git: GitPath(
            results.rest.first,
            path: results['git-path'] as String?,
            ref: results['git-ref'] as String?,
          ),
        ),
      );
    } else if (source == 'hosted') {
      if (results.rest.isEmpty) {
        usageException('A brick name must be provided');
      }
      brick = Brick(
        name: results.rest.first,
        location: const BrickLocation(version: 'any'),
      );
    } else {
      if (results.rest.isEmpty) {
        usageException('A path to the brick template must be provided');
      }
      brick = Brick(location: BrickLocation(path: results.rest.first));
    }

    BricksJson? tempBricksJson;

    final Directory brickDirectory;
    if (brick.location.path != null) {
      brickDirectory = Directory(brick.location.path!);
    } else {
      tempBricksJson = BricksJson.temp();
      final cachedBrick = await tempBricksJson.add(brick);
      brickDirectory = Directory(cachedBrick.path);
    }

    if (!brickDirectory.existsSync()) {
      throw BrickNotFoundException(brickDirectory.path);
    }

    final bundle = createBundle(brickDirectory);
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
        ..info(darkGray.wrap('  $bundlePath'));
    } catch (_) {
      bundleProgress.fail();
      rethrow;
    } finally {
      tempBricksJson?.clear();
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
    "// GENERATED CODE - DO NOT MODIFY BY HAND\n// ignore_for_file: type=lint, implicit_dynamic_list_literal, implicit_dynamic_map_literal, inference_failure_on_collection_literal\n\nimport 'package:mason/mason.dart';\n\nfinal ${bundle.name.camelCase}Bundle = MasonBundle.fromJson(<String, dynamic>${json.encode(bundle.toJson())});",
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
