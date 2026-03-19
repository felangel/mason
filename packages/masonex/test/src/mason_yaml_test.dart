// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:masonex/masonex.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('MasonexYaml', () {
    test('can be (de)serialized', () {
      final brickLocation = BrickLocation(path: '.');
      final instance = MasonexYaml({'example': brickLocation});
      final result = MasonexYaml.fromJson(instance.toJson());
      expect(result.bricks.length, equals(1));
      expect(result.bricks.keys.first, equals('example'));
      expect(
        result.bricks.values.first,
        isA<BrickLocation>().having((b) => b.path, 'path', brickLocation.path),
      );
    });

    group('findNearest', () {
      test('returns null when there is no masonex.yaml', () {
        expect(MasonexYaml.findNearest(Directory('/')), isNull);
      });

      test('returns masonex.yaml when there is one in the current directory', () {
        final directory = Directory.systemTemp.createTempSync();
        final file = File(
          path.join(directory.path, MasonexYaml.file),
        )..createSync();
        expect(
          MasonexYaml.findNearest(directory),
          isA<File>().having((f) => f.path, 'path', file.path),
        );
      });

      test('returns masonex.yaml when there is one in the parent directory', () {
        final directory = Directory.systemTemp.createTempSync();
        final file = File(
          path.join(directory.path, MasonexYaml.file),
        )..createSync();
        final nestedDirectory = Directory(
          path.join(directory.path, 'nested'),
        )..createSync();
        expect(
          MasonexYaml.findNearest(nestedDirectory),
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
          'https://github.com/felangel/masonex',
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
  });

  group('GitPath', () {
    test('can be (de)serialized', () {
      final instance = GitPath(
        'https://github.com/felangel/masonex',
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
