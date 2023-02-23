import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:mason/mason.dart';
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/command_runner.dart';
import 'package:path/path.dart' as path;

const _maxBundleSizeInBytes = 2 * 1024 * 1024; // 2 MB

/// {@template publish_command}
/// `mason publish` command which publishes a brick.
/// {@endtemplate}
class PublishCommand extends MasonCommand {
  /// {@macro publish_command}
  PublishCommand({
    super.logger,
    MasonApiBuilder? masonApiBuilder,
    int? maxBundleSize,
  })  : _masonApiBuilder = masonApiBuilder ?? MasonApi.new,
        _maxBundleSize = maxBundleSize ?? _maxBundleSizeInBytes {
    argParser.addOptions();
  }

  final MasonApiBuilder _masonApiBuilder;
  final int _maxBundleSize;

  @override
  final String description = 'Publish the current brick to brickhub.dev.';

  @override
  final String name = 'publish';

  Uri? _resolveHostedUri(String? host) {
    if (host == null) return BricksJson.hostedUri;

    if (host == 'none') {
      logger
        ..err('A private brick cannot be published.')
        ..err(
          '''Please change or remove the "publish_to" field in the brick.yaml before publishing.''',
        );
      return null;
    }

    final hostedUri = Uri.tryParse(host);

    if (hostedUri == null || hostedUri.host.isEmpty) {
      logger
        ..err('Invalid "publish_to" in brick.yaml: "$host"')
        ..err(
          '"publish_to" must be a valid registry url such as '
          '"https://registry.brickhub.dev" or "none" for private bricks.',
        );
      return null;
    }

    return hostedUri;
  }

  @override
  Future<int> run() async {
    final directoryPath = results['directory'] as String;
    final brickYamlFile = File(path.join(directoryPath, BrickYaml.file));
    if (!brickYamlFile.existsSync()) {
      logger.err('Could not find ${BrickYaml.file} at ${brickYamlFile.path}.');
      return ExitCode.software.code;
    }

    final brickYaml = checkedYamlDecode(
      brickYamlFile.readAsStringSync(),
      (m) => BrickYaml.fromJson(m!),
    );

    final publishTo = brickYaml.publishTo;
    final hostedUri = _resolveHostedUri(publishTo);

    if (hostedUri == null) return ExitCode.software.code;

    final masonApi = _masonApiBuilder(hostedUri: hostedUri);
    final user = masonApi.currentUser;
    if (user == null) {
      logger
        ..err('You must be logged in to publish.')
        ..err("Run 'mason login' to log in and try again.");
      masonApi.close();
      return ExitCode.software.code;
    }

    if (!user.emailVerified) {
      logger.err('You must verify your email in order to publish.');
      masonApi.close();
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
      masonApi.close();
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
      masonApi.close();
      return ExitCode.software.code;
    }

    final publishProgress = logger.progress(
      'Publishing ${bundle.name} ${bundle.version}',
    );

    try {
      await masonApi.publish(bundle: universalBundle);
      publishProgress.complete('Published ${bundle.name} ${bundle.version}');
      logger.success(
        '''\nPublished ${bundle.name} ${bundle.version} to $hostedUri.''',
      );
    } on MasonApiPublishFailure catch (error) {
      publishProgress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    } catch (_) {
      publishProgress.fail();
      rethrow;
    } finally {
      masonApi.close();
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
