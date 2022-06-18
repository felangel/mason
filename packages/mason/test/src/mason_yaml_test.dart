// ignore_for_file: prefer_const_constructors

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

class MockGitPath extends Mock implements GitPath {}

void main() {
  group('MasonYaml', () {
    test('can be (de)serialized', () {
      final brickLocation = BrickLocation(path: '.');
      final instance = MasonYaml({'example': brickLocation});
      final result = MasonYaml.fromJson(instance.toJson());
      expect(result.bricks.length, equals(1));
      expect(result.bricks.keys.first, equals('example'));
      expect(
        result.bricks.values.first,
        isA<BrickLocation>().having((b) => b.path, 'path', brickLocation.path),
      );
    });

    group('findNearest', () {
      test('returns null when there is no mason.yaml', () {
        expect(MasonYaml.findNearest(Directory('/')), isNull);
      });

      test('returns mason.yaml when there is one in the current directory', () {
        final directory = Directory.systemTemp.createTempSync();
        final file = File(
          path.join(directory.path, MasonYaml.file),
        )..createSync();
        expect(
          MasonYaml.findNearest(directory),
          isA<File>().having((f) => f.path, 'path', file.path),
        );
      });

      test('returns mason.yaml when there is one in the parent directory', () {
        final directory = Directory.systemTemp.createTempSync();
        final file = File(
          path.join(directory.path, MasonYaml.file),
        )..createSync();
        final nestedDirectory = Directory(
          path.join(directory.path, 'nested'),
        )..createSync();
        expect(
          MasonYaml.findNearest(nestedDirectory),
          isA<File>().having((f) => f.path, 'path', file.path),
        );
      });
    });
  });

  group('BrickLocation', () {
    test('can be (de)serialized (path)', () {
      final instance = BrickLocation(path: '.');
      expect(
        BrickLocation.fromJson(instance.toJson()),
        isA<BrickLocation>().having((b) => b.path, 'path', instance.path),
      );
    });

    test('can be (de)serialized (gitPath)', () {
      final instance = BrickLocation(
        git: GitPath(
          'https://github.com/felangel/mason',
          ref: 'main',
          path: 'bricks/simple',
        ),
      );
      expect(
        BrickLocation.fromJson(instance.toJson()).git,
        isA<GitPath>()
            .having((g) => g.url, 'url', instance.git!.url)
            .having((g) => g.ref, 'ref', instance.git!.ref)
            .having((g) => g.path, 'path', instance.git!.path),
      );
    });

    test('isLocal', () {
      // ignore: avoid_redundant_argument_values
      final hostedInstance = BrickLocation(version: 'any');
      expect(hostedInstance.isLocal, isFalse);

      // ignore: avoid_redundant_argument_values
      final gitInstance = BrickLocation(git: MockGitPath());
      expect(gitInstance.isLocal, isFalse);

      final localInstance = BrickLocation(path: '.');
      expect(localInstance.isLocal, isTrue);
    });
  });

  group('GitPath', () {
    test('can be (de)serialized', () {
      final instance = GitPath(
        'https://github.com/felangel/mason',
        ref: 'main',
        path: 'bricks/simple',
      );
      expect(
        GitPath.fromJson(instance.toJson()),
        isA<GitPath>()
            .having((g) => g.url, 'url', instance.url)
            .having((g) => g.ref, 'ref', instance.ref)
            .having((g) => g.path, 'path', instance.path),
      );
    });
  });
}
