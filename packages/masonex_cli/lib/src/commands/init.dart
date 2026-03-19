import 'package:masonex/masonex.dart';
import 'package:masonex_cli/src/command.dart';
import 'package:masonex_cli/src/install_brick.dart';

/// {@template init_command}
/// `masonex init` command which initializes a new `masonex.yaml`.
/// {@endtemplate}
class InitCommand extends MasonexCommand with InstallBrickMixin {
  /// {@macro init_command}
  InitCommand({super.logger});

  @override
  final String description = 'Initialize masonex in the current directory.';

  @override
  final String name = 'init';

  @override
  Future<int> run() async {
    if (masonexInitialized) {
      logger.err('Existing ${MasonexYaml.file} at ${localMasonexYamlFile.path}');
      return ExitCode.usage.code;
    }
    final progress = logger.progress('Initializing');
    final target = DirectoryGeneratorTarget(cwd);
    final generator = _MasonexYamlGenerator();
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

class _MasonexYamlGenerator extends MasonexGenerator {
  _MasonexYamlGenerator()
      : super(
          '__masonex_init__',
          'Initialize a new ${MasonexYaml.file}',
          files: [TemplateFile(MasonexYaml.file, _masonexYamlContent)],
        );

  static const _masonexYamlContent = '''
# Register bricks which can be consumed via the Masonex CLI.
# Run "masonex get" to install all registered bricks.
# To learn more, visit https://docs.brickhub.dev.
bricks:
  # Bricks can be imported via version constraint from a registry.
  # Uncomment the following line to import the "hello" brick from BrickHub.
  # hello: 0.1.0+2
  # Bricks can also be imported via remote git url.
  # Uncomment the following lines to import the "widget" brick from git.
  # widget:
  #   git:
  #     url: https://github.com/felangel/masonex.git
  #     path: bricks/widget
''';
}
