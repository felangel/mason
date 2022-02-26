import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/commands/bundle.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';

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
      throw UsageException(
        'path to the bundle must be provided',
        usage,
      );
    }
    final file = File(results.rest.first);
    if (!file.existsSync()) {
      throw BundleNotFoundException(file.path);
    }

    final outputDir = results['output-dir'] as String;
    final bundleType = (results['type'] as String).toBundleType();

    final bundleName = path.basenameWithoutExtension(file.path);
    final unbundleDone = logger.progress('Unbundling $bundleName');

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
      unbundleDone('Unbundled ${bundle.name}');
      logger
        ..info(
          '${lightGreen.wrap('✓')} '
          'Generated 1 brick:',
        )
        ..detail('  ${bundle.name} ➤ ${canonicalize(outputDir)}');
    } catch (_) {
      unbundleDone();
      rethrow;
    }

    return ExitCode.success.code;
  }
}

Future<MasonBundle> _parseDartBundle(File bundleFile) async {
  final rawBundle = await bundleFile.readAsString();
  final bundleJson = json.decode(
    rawBundle.substring(
      rawBundle.indexOf('{'),
      rawBundle.lastIndexOf('}') + 1,
    ),
  ) as Map<String, dynamic>;
  return MasonBundle.fromJson(bundleJson);
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
