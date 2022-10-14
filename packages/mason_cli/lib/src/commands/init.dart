import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/install_brick.dart';

/// {@template init_command}
/// `mason init` command which initializes a new `mason.yaml`.
/// {@endtemplate}
class InitCommand extends MasonCommand with InstallBrickMixin {
  /// {@macro init_command}
  InitCommand({Logger? logger}) : super(logger: logger);

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
    final fetchProgress = logger.progress('Initializing');
    final target = DirectoryGeneratorTarget(cwd);
    final generator = _MasonYamlGenerator();
    await generator.generate(
      target,
      vars: <String, String>{'name': '{{name}}'},
      logger: logger,
    );
    fetchProgress.complete();

    await getBricks();

    logger
      ..info(
        '${lightGreen.wrap('✓')} Generated ${generator.files.length} file(s):',
      )
      ..flush((message) => logger.info(darkGray.wrap(message)))
      ..info('')
      ..info('Run "mason make hello" to use your first brick.');
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
# https://github.com/felangel/mason
bricks:
  # Sample Brick
  # Run `mason make hello` to try it out.
  hello: 0.1.0+1
  # Bricks can also be imported via git url.
  # Uncomment the following lines to import
  # a brick from a remote git url.
  # widget:
  #   git:
  #     url: https://github.com/felangel/mason.git
  #     path: bricks/widget
''';
}
