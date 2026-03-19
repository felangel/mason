import 'dart:io';

import 'package:masonex/masonex.dart';

Future<void> main() async {
  final brick = Brick.git(
    const GitPath(
      'https://github.com/felangel/masonex.git',
      path: 'bricks/greeting',
    ),
  );
  final generator = await MasonexGenerator.fromBrick(brick);
  final target = DirectoryGeneratorTarget(Directory.current);
  await generator.generate(target, vars: <String, dynamic>{'name': 'Dash'});
}
