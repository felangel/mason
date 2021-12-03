import 'dart:io';

import 'package:mason/mason.dart';

void main() async {
  final generator = await MasonGenerator.fromGitPath(
    const GitPath(
      'https://github.com/felangel/mason.git',
      path: 'bricks/greeting',
    ),
  );
  final target = DirectoryGeneratorTarget(Directory.current);
  await generator.generate(target, vars: <String, dynamic>{'name': 'Dash'});
}
