// ignore_for_file: prefer_const_constructors

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void main() {
  group('MasonYaml', () {
    test('can be (de)serialized', () {
      final brick = Brick(path: '.');
      final instance = MasonYaml({'example': brick});
      final result = MasonYaml.fromJson(instance.toJson());
      expect(result.bricks.length, equals(1));
      expect(result.bricks.keys.first, equals('example'));
      expect(
        result.bricks.values.first,
        isA<Brick>().having((b) => b.path, 'path', brick.path),
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

  group('Brick', () {
    test('can be (de)serialized (path)', () {
      final instance = Brick(path: '.');
      expect(
        Brick.fromJson(instance.toJson()),
        isA<Brick>().having((b) => b.path, 'path', instance.path),
      );
    });

    test('can be (de)serialized (gitPath)', () {
      final instance = Brick(
        git: GitPath(
          'https://github.com/felangel/mason',
          ref: 'main',
          path: 'bricks/simple',
        ),
      );
      expect(
        Brick.fromJson(instance.toJson()).git,
        isA<GitPath>()
            .having((g) => g.url, 'url', instance.git!.url)
            .having((g) => g.ref, 'ref', instance.git!.ref)
            .having((g) => g.path, 'path', instance.git!.path),
      );
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
