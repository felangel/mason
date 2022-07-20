// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mason_cli/src/command.dart';
import 'package:mason_cli/src/commands/commands.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

void main() {
  group('Command', () {
    final cwd = Directory.current;

    tearDown(() {
      Directory.current = cwd;
    });

    group('MasonYamlNotFoundException', () {
      test('has the correct message', () {
        const message =
            'Cannot find mason.yaml.\nDid you forget to run mason init?';
        expect(MasonYamlNotFoundException().message, equals(message));
      });
    });

    group('BrickYamlParseException', () {
      test('has the correct message', () {
        const message = 'test message';
        expect(BrickYamlParseException(message).message, equals(message));
      });

      test('is thrown when brick.yaml is malformed', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        final directory = Directory(path.join(tempDirectory.path, 'malformed'))
          ..createSync(recursive: true);
        final brickYaml = File(path.join(directory.path, 'brick.yaml'))
          ..writeAsStringSync(
            '''
name: malformed
description: A malformed Template
version: 0.1.0+1
''',
          );
        File(path.join(directory.path, 'mason.yaml')).writeAsStringSync(
          '''
bricks:
  malformed:
    path: ${directory.path}
  
''',
        );
        Directory.current = directory;
        final logger = MockLogger();
        when(() => logger.progress(any())).thenReturn(MockProgress());
        final command = GetCommand(logger: logger);
        await command.run();
        brickYaml.writeAsStringSync('{]');
        expect(() => command.bricks, throwsA(isA<BrickYamlParseException>()));
      });
    });

    group('MasonYamlParseException', () {
      test('has the correct message', () {
        const message = 'test message';
        expect(MasonYamlParseException(message).message, equals(message));
      });
    });
  });
}
