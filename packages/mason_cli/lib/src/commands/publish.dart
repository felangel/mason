import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:mason_api/mason_api.dart';
import 'package:mason_cli/src/command.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';

/// {@template publish_command}
/// `mason publish` command which publishes a brick.
/// {@endtemplate}
class PublishCommand extends MasonCommand {
  /// {@macro publish_command}
  PublishCommand({Logger? logger, MasonApi? masonApi})
      : _masonApi = masonApi ?? MasonApi(),
        super(logger: logger) {
    argParser.addOptions();
  }

  final MasonApi _masonApi;

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

    final directory = Directory(directoryPath);
    final bundle = createBundle(directory);

    logger.alert('\nPublishing is forever; bricks cannot be unpublished.');

    final confirmed = logger.confirm(
      'Do you want to publish ${bundle.name} ${bundle.version}?',
    );

    if (!confirmed) {
      logger.err('Brick was not published.');
      return ExitCode.software.code;
    }

    final publishDone = logger.progress('Publishing');

    try {
      await _masonApi.publish(bundle: await bundle.toUniversalBundle());
      publishDone('Published');
      logger.success(
        '''\nPublished ${bundle.name} ${bundle.version} to ${BricksJson.hostedUri}.''',
      );
    } on MasonApiPublishFailure catch (error) {
      publishDone();
      logger.err(error.message);
      return ExitCode.software.code;
    } catch (_) {
      publishDone();
      rethrow;
    }

    return ExitCode.success.code;
  }
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
