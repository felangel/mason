import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/command.dart';
import 'package:path/path.dart' as path;

const _maxBundleSizeInBytes = 2 * 1024 * 1024; // 2 MB

/// {@template publish_command}
/// `mason publish` command which publishes a brick.
/// {@endtemplate}
class PublishCommand extends MasonCommand {
  /// {@macro publish_command}
  PublishCommand({Logger? logger, MasonApi? masonApi, int? maxBundleSize})
      : _masonApi = masonApi ?? MasonApi(),
        _maxBundleSize = maxBundleSize ?? _maxBundleSizeInBytes,
        super(logger: logger) {
    argParser.addOptions();
  }

  final MasonApi _masonApi;
  final int _maxBundleSize;

  @override
  final String description = 'Publish the current brick to brickhub.dev.';

  @override
  final String name = 'publish';

  @override
  Future<int> run() async {
    final directoryPath = results['directory'] as String;
    final brickYamlFile = File(path.join(directoryPath, BrickYaml.file));
    if (!brickYamlFile.existsSync()) {
      logger.err('Could not find ${BrickYaml.file} at ${brickYamlFile.path}.');
      return ExitCode.software.code;
    }

    final user = _masonApi.currentUser;
    if (user == null) {
      logger
        ..err('You must be logged in to publish.')
        ..err("Run 'mason login' to log in and try again.");
      return ExitCode.software.code;
    }

    if (!user.emailVerified) {
      logger.err('You must verify your email in order to publish.');
      return ExitCode.software.code;
    }

    final bundle = createBundle(Directory(directoryPath));
    final bundleProgress = logger.progress('Bundling ${bundle.name}');
    final universalBundle = await bundle.toUniversalBundle();
    bundleProgress.complete('Bundled ${bundle.name}');

    final sizeInBytes = Uint8List.fromList(universalBundle).lengthInBytes;
    if (sizeInBytes > _maxBundleSize) {
      final sizeInMb = sizeInBytes.toMegabytes().toStringAsPrecision(4);
      final maxSizeInMb = _maxBundleSize.toMegabytes().toStringAsPrecision(2);
      logger.err(
        '''Your bundle is $sizeInMb MB. Hosted bricks must be smaller than $maxSizeInMb MB.''',
      );
      return ExitCode.software.code;
    }
    final policyLink = styleUnderlined.wrap(
      link(uri: Uri.parse('https://brickhub.dev/policy')),
    );
    logger
      ..info(
        lightCyan.wrap(
          styleBold.wrap(
            '\nPublishing is forever; bricks cannot be unpublished.',
          ),
        ),
      )
      ..info('See policy details at $policyLink\n');

    final confirmed = logger.confirm(
      'Do you want to publish ${bundle.name} ${bundle.version}?',
    );

    if (!confirmed) {
      logger.err('Brick was not published.');
      return ExitCode.software.code;
    }

    final publishProgress = logger.progress(
      'Publishing ${bundle.name} ${bundle.version}',
    );

    try {
      await _masonApi.publish(bundle: universalBundle);
      publishProgress.complete('Published ${bundle.name} ${bundle.version}');
      logger.success(
        '''\nPublished ${bundle.name} ${bundle.version} to ${BricksJson.hostedUri}.''',
      );
    } on MasonApiPublishFailure catch (error) {
      publishProgress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    } catch (_) {
      publishProgress.fail();
      rethrow;
    }

    return ExitCode.success.code;
  }
}

extension on int {
  double toMegabytes() => this / math.pow(2, 20);
}

extension on ArgParser {
  void addOptions() {
    addOption(
      'directory',
      abbr: 'C',
      help: 'Run this in the specified directory',
      defaultsTo: '.',
    );
  }
}
