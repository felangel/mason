import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/commands/bundle.dart';
import 'package:path/path.dart' as path;

/// {@template unbundle_command}
/// `mason unbundle` command exposes the ability to generate brick templates
/// from bundles.
/// {@endtemplate}
class UnbundleCommand extends MasonCommand {
  /// {@macro unbundle_command}
  UnbundleCommand({Logger? logger}) : super(logger: logger) {
    argParser
      ..addOption(
        'output-dir',
        abbr: 'o',
        help: 'Directory where to output the generated brick template.',
        defaultsTo: '.',
      )
      ..addOption(
        'type',
        abbr: 't',
        help: 'Type of input bundle.',
        allowed: ['universal', 'dart'],
        defaultsTo: 'universal',
      );
  }

  @override
  final String description = 'Generates a brick template from a bundle.';

  @override
  final String name = 'unbundle';

  @override
  Future<int> run() async {
    if (results.rest.isEmpty) {
      usageException('path to the bundle must be provided');
    }
    final file = File(results.rest.first);
    if (!file.existsSync()) {
      logger.err('Could not find bundle at ${file.path}');
      return ExitCode.usage.code;
    }

    final outputDir = results['output-dir'] as String;
    final bundleType = (results['type'] as String).toBundleType();

    final bundleName = path.basenameWithoutExtension(file.path);
    final unbundleProgress = logger.progress('Unbundling $bundleName');

    try {
      late final MasonBundle bundle;
      switch (bundleType) {
        case BundleType.dart:
          bundle = await _parseDartBundle(file);
          break;
        case BundleType.universal:
          bundle = await _parseUniversalBundle(file);
          break;
      }
      unpackBundle(bundle, Directory(outputDir));
      unbundleProgress.complete('Unbundled ${bundle.name}');
      logger
        ..info(
          '${lightGreen.wrap('✓')} '
          'Generated 1 brick:',
        )
        ..info(darkGray.wrap('  ${canonicalize(outputDir)}'));
    } catch (_) {
      unbundleProgress.fail();
      rethrow;
    }

    return ExitCode.success.code;
  }
}

Future<MasonBundle> _parseDartBundle(File bundleFile) async {
  final rawBundle = await bundleFile.readAsString();
  return MasonBundle.fromDartBundle(rawBundle);
}

Future<MasonBundle> _parseUniversalBundle(File bundleFile) async {
  final rawBundle = await bundleFile.readAsBytes();
  return MasonBundle.fromUniversalBundle(rawBundle);
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
