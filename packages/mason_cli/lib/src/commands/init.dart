import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/install_brick.dart';

/// {@template init_command}
/// `mason init` command which initializes a new `mason.yaml`.
/// {@endtemplate}
class InitCommand extends MasonCommand with InstallBrickMixin {
  /// {@macro init_command}
  InitCommand({super.logger});

  @override
  final String description = 'Initialize mason in the current directory.';

  @override
  final String name = 'init';

  @override
  Future<int> run() async {
    if (masonInitialized) {
      logger.err('Existing ${MasonYaml.file} at ${localMasonYamlFile.path}');
      return ExitCode.usage.code;
    }
    final progress = logger.progress('Initializing');
    final target = DirectoryGeneratorTarget(cwd);
    final generator = _MasonYamlGenerator();
    await generator.generate(
      target,
      vars: <String, String>{'name': '{{name}}'},
      logger: logger,
    );

    progress.complete('Generated 1 file.');
    logger.flush((message) => logger.info(darkGray.wrap(message)));
    return ExitCode.success.code;
  }
}

class _MasonYamlGenerator extends MasonGenerator {
  _MasonYamlGenerator()
      : super(
          '__mason_init__',
          'Initialize a new ${MasonYaml.file}',
          files: [TemplateFile(MasonYaml.file, _masonYamlContent)],
        );

  static const _masonYamlContent = '''
# Register bricks which can be consumed via the Mason CLI.
# Run "mason get" to install all registered bricks.
# To learn more, visit https://docs.brickhub.dev.
bricks:
  # Bricks can be imported via version constraint from a registry.
  # Uncomment the following line to import the "hello" brick from BrickHub.
  # hello: 0.1.0+1
  # Bricks can also be imported via remote git url.
  # Uncomment the following lines to import the "widget" brick from git.
  # widget:
  #   git:
  #     url: https://github.com/felangel/mason.git
  #     path: bricks/widget
''';
}
