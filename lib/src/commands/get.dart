import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart' as p;

import '../command.dart';
import '../git.dart';
import '../mason_yaml.dart';

/// {@template get_command}
/// `mason get` command which gets all remote bricks.
/// {@endtemplate}
class GetCommand extends MasonCommand {
  /// {@macro get_command}
  GetCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      defaultsTo: false,
      help: 'Overwrites cached bricks',
    );
  }

  @override
  final String description = 'Gets all remote bricks';

  @override
  final String name = 'get';

  @override
  Future<int> run() async {
    final getDone = logger.progress('getting bricks');
    if (masonYamlFile == null) {
      getDone();
      logger.err(
        '''Cannot find ${MasonYaml.file}.\nDid you forget to run mason init?''',
      );
      return ExitCode.usage.code;
    }

    final force = argResults['force'] == true;
    if (force) {
      cache.clear();
    }

    await Future.forEach<Brick>(masonYaml.bricks.values, _download);
    await bricksJson.create(recursive: true);
    await bricksJson.writeAsString(cache.encode);
    getDone();
    return ExitCode.success.code;
  }

  /// Downloads remote bricks to `.brick-cache`.
  Future<void> _download(Brick brick) async {
    if (brick.path != null && (cache.read(brick.path) == null)) {
      return cache.write(
        brick.path,
        File(p.join(entryPoint.path, brick.path)).absolute.path,
      );
    }
    if (brick.git != null && (cache.read(brick.git.url) == null)) {
      final dirName = brick.git.ref != null
          ? '${brick.git.url}-${brick.git.ref}'
          : brick.git.url;
      final directory = Directory(p.join(cache.rootDir, 'git', dirName));
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
      await directory.create(recursive: true);
      await Git.run(['clone', brick.git.url, directory.path]);
      if (brick.git.ref != null) {
        await Git.run(
          ['checkout', brick.git.ref],
          processWorkingDir: directory.path,
        );
      }
      return cache.write(brick.git.url, directory.path);
    }
  }
}
