import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:path/path.dart' as path;

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
  BundleCommand({super.logger}) {
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
      ..addFlag(
        'set-exit-if-changed',
        help: 'Return exit code 70 if there are files modified.',
        negatable: false,
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
    final setExitIfChanged = results['set-exit-if-changed'] as bool;

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

    late _BrickBundleGenerator bundleGenerator;
    switch (bundleType) {
      case BundleType.dart:
        bundleGenerator = _BrickDartBundleGenerator(
          outputDirectoryPath: outputDir,
          bundle: bundle,
        );
        break;
      case BundleType.universal:
        bundleGenerator = _BrickUniversalBundleGenerator(
          outputDirectoryPath: outputDir,
          bundle: bundle,
        );
        break;
    }

    String? previousContent;
    if (setExitIfChanged) {
      final bundleFile = bundleGenerator._bundleFile;
      previousContent =
          bundleFile.existsSync() ? await bundleFile.readAsString() : '';
    }
    try {
      await bundleGenerator.generate();
      bundleProgress.complete('Generated 1 file.');

      final canonicalBundlePath =
          canonicalize(bundleGenerator._bundleFile.path);
      logger.info(darkGray.wrap('  $canonicalBundlePath'));
    } catch (_) {
      bundleProgress.fail();
      rethrow;
    } finally {
      tempBricksJson?.clear();
    }

    if (setExitIfChanged) {
      final newContent = await bundleGenerator._bundleFile.readAsString();
      if (previousContent != newContent) {
        logger.err('${lightRed.wrap('✗')} 1 file changed');
        return ExitCode.software.code;
      }
      logger.info('${lightGreen.wrap('✓')} 0 files changed');
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

/// {@template brick_bundle_generator}
/// Interface that defines a bundle generator.
///
/// A bundle generator is responsible for generating a bundle for a brick.
///
/// See also:
///
/// * [_BrickDartBundleGenerator], a bundle generator which generates a Dart
/// bundle.
/// * [_BrickUniversalBundleGenerator], a bundle generator which generates a
/// universal bundle.
/// {@endtemplate}
abstract class _BrickBundleGenerator {
  /// {@macro brick_bundle_generator}
  const _BrickBundleGenerator({
    required File bundleFile,
    required MasonBundle bundle,
  })  : _bundleFile = bundleFile,
        _bundle = bundle;

  final MasonBundle _bundle;

  final File _bundleFile;

  Future<void> generate();
}

/// {@template brick_dart_bundle_generator}
/// A bundle generator which generates a Dart bundle.
/// {@endtemplate}
class _BrickDartBundleGenerator extends _BrickBundleGenerator {
  /// {@macro brick_dart_bundle_generator}
  _BrickDartBundleGenerator({
    required String outputDirectoryPath,
    required super.bundle,
  }) : super(
          bundleFile: File(
            path.join(outputDirectoryPath, '${bundle.name}_bundle.dart'),
          ),
        );

  @override
  Future<void> generate() async {
    await _bundleFile.create(recursive: true);
    await _bundleFile.writeAsString(
      "// GENERATED CODE - DO NOT MODIFY BY HAND\n// ignore_for_file: type=lint, implicit_dynamic_list_literal, implicit_dynamic_map_literal, inference_failure_on_collection_literal\n\nimport 'package:mason/mason.dart';\n\nfinal ${_bundle.name.camelCase}Bundle = MasonBundle.fromJson(<String, dynamic>${json.encode(_bundle.toJson())});",
    );
  }
}

/// {@template brick_universal_bundle_generator}
/// A bundle generator which generates a universal bundle.
/// {@endtemplate}
class _BrickUniversalBundleGenerator extends _BrickBundleGenerator {
  /// {@macro brick_universal_bundle_generator}
  _BrickUniversalBundleGenerator({
    required String outputDirectoryPath,
    required super.bundle,
  }) : super(
          bundleFile: File(
            path.join(outputDirectoryPath, '${bundle.name}.bundle'),
          ),
        );

  @override
  Future<void> generate() async {
    await _bundleFile.create(recursive: true);
    await _bundleFile.writeAsBytes(await _bundle.toUniversalBundle());
  }
}
