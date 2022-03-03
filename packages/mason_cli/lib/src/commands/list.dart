import 'dart:convert';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:path/path.dart' as path;

/// {@template list_command}
/// `mason list` command which lists all available bricks.
/// {@endtemplate}
class ListCommand extends MasonCommand {
  /// {@macro list_command}
  ListCommand({Logger? logger}) : super(logger: logger) {
    argParser.addFlag(
      'global',
      abbr: 'g',
      help: 'Lists globally installed bricks.',
    );
  }

  @override
  final String description = 'Lists installed bricks.';

  @override
  final String name = 'list';

  @override
  List<String> get aliases => ['ls'];

  @override
  Future<int> run() async {
    final isGlobal = results['global'] == true;
    final bricks = isGlobal ? globalBricks : localBricks;

    logger.info(isGlobal ? path.dirname(globalMasonYamlFile.path) : cwd.path);

    if (bricks.isEmpty) {
      logger.info('└── (empty)');
      return ExitCode.success.code;
    }

    final sortedBricks = [...bricks]..sort((a, b) => a.name.compareTo(b.name));

    for (var i = 0; i < sortedBricks.length; i++) {
      final brick = sortedBricks.elementAt(i);
      final prefix = i == sortedBricks.length - 1 ? '└──' : '├──';

      logger.info('$prefix ${brick.prettyPrint()}');
    }

    return ExitCode.success.code;
  }
}

extension on BrickYaml {
  String prettyPrint() {
    final brickPath = canonicalize(path.dirname(this.path!));
    final hostedPath = canonicalize(
      path.join(BricksJson.rootDir.path, 'hosted'),
    );
    final gitPath = canonicalize(path.join(BricksJson.rootDir.path, 'git'));
    final isHosted = path.isWithin(hostedPath, brickPath);
    final isGit = path.isWithin(gitPath, brickPath);
    final isLocal = !isHosted && !isGit;
    final nameAndVersion = '${styleBold.wrap(name)} $version';

    if (isLocal) return '$nameAndVersion -> $brickPath';
    if (isGit) {
      final subPath = brickPath.split('$gitPath/').last;
      final gitDirectory = path.split(subPath).first;
      final gitSegments = gitDirectory.split('_');
      final gitUrlSegment = gitSegments[gitSegments.length - 2];
      final gitUrl = utf8.decode(base64.decode(gitUrlSegment));
      final commitHash = gitSegments.last;
      return '$nameAndVersion -> $gitUrl#$commitHash';
    }
    final hostedUrl = path.split(brickPath.split('$hostedPath/').last).first;
    return '$nameAndVersion -> $hostedUrl';
  }
}
