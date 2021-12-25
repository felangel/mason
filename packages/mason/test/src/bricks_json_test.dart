// ignore_for_file: prefer_const_constructors

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void main() {
  group('BricksJson', () {
    test('can be instantiated with local directory', () {
      final directory = Directory.systemTemp.createTempSync();
      final bricksJson = BricksJson(directory: directory);
      expect(bricksJson, isNotNull);
    });

    test('can be instantiated with existing bricks.json', () async {
      final directory = Directory.systemTemp.createTempSync();
      final bricksJson = BricksJson(directory: directory);
      File(
        path.join(directory.path, '.mason', 'bricks.json'),
      ).createSync(recursive: true);

      expect(bricksJson.encode, equals('{}'));

      final brick = Brick(path: path.join('..', '..', 'bricks', 'simple'));
      final result = await bricksJson.add(brick);

      expect(result, isNotEmpty);
      expect(bricksJson.encode, contains('simple_'));

      await bricksJson.flush();

      final newBricksJson = BricksJson(directory: directory);
      expect(newBricksJson.encode, contains('simple_'));
    });

    test('can be instantiated with global directory', () {
      final bricksJson = BricksJson.global();
      expect(bricksJson, isNotNull);
    });

    test('can be instantiated with temp directory', () {
      final bricksJson = BricksJson.temp();
      expect(bricksJson, isNotNull);
    });

    group('clear', () {
      test('clears cache and deletes existing bricks.json', () {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        bricksJson.clear();
        expect(file.existsSync(), isFalse);
        expect(bricksJson.encode, equals('{}'));
      });
    });

    group('add', () {
      test('adds bricks to bricks.json (git)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        final result = await bricksJson.add(
          Brick(
            git: GitPath(
              'https://github.com/felangel/mason',
              path: 'bricks/simple',
            ),
          ),
        );
        expect(result, isNotEmpty);
        expect(bricksJson.encode, contains('simple_'));
      });

      test(
          'adds bricks to bricks.json via git '
          'with existing empty directory', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final brick = Brick(
          git: GitPath(
            'https://github.com/felangel/mason',
            path: 'bricks/simple',
          ),
        );
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));

        final result1 = await bricksJson.add(brick);
        expect(result1, isNotEmpty);
        expect(bricksJson.encode, contains('simple_'));
        Directory(result1)
          ..deleteSync(recursive: true)
          ..createSync();

        final result2 = await bricksJson.add(brick);
        expect(result2, isNotEmpty);
        expect(bricksJson.encode, contains('simple_'));
        expect(result1, equals(result2));
      });

      test('adds bricks to bricks.json (git + ref)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        final result = await bricksJson.add(
          Brick(
            git: GitPath(
              'https://github.com/felangel/mason',
              path: 'bricks/simple',
              ref: 'master',
            ),
          ),
        );
        expect(result, isNotEmpty);
        expect(bricksJson.encode, contains('simple_master_'));
      });

      test('adds bricks to bricks.json (path)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        final result = await bricksJson.add(
          Brick(path: path.join('..', '..', 'bricks', 'simple')),
        );
        expect(result, isNotEmpty);
        expect(bricksJson.encode, contains('simple_'));
      });

      test(
          'throws BrickNotFoundException when '
          'brick does not exist (git)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        expect(
          () => bricksJson.add(
            Brick(git: GitPath('https://github.com/felangel/mason')),
          ),
          throwsA(isA<BrickNotFoundException>()),
        );
      });

      test(
          'throws BrickNotFoundException when '
          'brick does not exist (path)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        expect(
          () => bricksJson.add(Brick(path: 'simple')),
          throwsA(isA<BrickNotFoundException>()),
        );
      });
    });

    group('flush', () {
      test('writes to bricks.json', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        expect(file.readAsStringSync(), isEmpty);
        final result = await bricksJson.add(
          Brick(path: path.join('..', '..', 'bricks', 'simple')),
        );
        expect(result, isNotEmpty);
        expect(bricksJson.encode, contains('simple_'));
        expect(file.readAsStringSync(), isEmpty);
        await bricksJson.flush();
        expect(file.readAsStringSync(), contains('simple_'));
      });
    });

    group('remove', () {
      test('updates cache', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        File(
          path.join(directory.path, '.mason', 'bricks.json'),
        ).createSync(recursive: true);
        expect(bricksJson.encode, equals('{}'));

        final brick = Brick(path: path.join('..', '..', 'bricks', 'simple'));
        final result = await bricksJson.add(brick);
        expect(result, isNotEmpty);
        expect(bricksJson.encode, contains('simple_'));
        bricksJson.remove(brick);
        expect(bricksJson.encode, equals('{}'));
      });
    });

    group('rootDir', () {
      test('uses MASON_CACHE environment when available', () {
        final directory = Directory.systemTemp.createTempSync();
        BricksJson.testEnvironment = {'MASON_CACHE': directory.path};
        expect(BricksJson.rootDir.path, equals(directory.path));
      });

      test('uses APPDATA on windows environment when APPDATA exists', () {
        final directory = Directory.systemTemp.createTempSync();
        final appDataCacheDirectory = Directory(
          path.join(directory.path, 'Mason', 'Cache'),
        )..createSync(recursive: true);
        BricksJson.testEnvironment = {'APPDATA': directory.path};
        BricksJson.testIsWindows = true;
        expect(BricksJson.rootDir.path, equals(appDataCacheDirectory.path));
      });

      test(
          'uses LOCALAPPDATA on windows environment when '
          'APPDATA cache does not exist', () {
        final directory = Directory.systemTemp.createTempSync();
        final appDataCacheDirectory = Directory(
          path.join(directory.path, 'Mason', 'Cache'),
        )..createSync(recursive: true);
        BricksJson.testEnvironment = {
          'APPDATA': '',
          'LOCALAPPDATA': directory.path
        };
        BricksJson.testIsWindows = true;
        expect(BricksJson.rootDir.path, equals(appDataCacheDirectory.path));
      });

      test('uses HOME by default', () {
        final directory = Directory.systemTemp.createTempSync();
        final appDataCacheDirectory = Directory(
          path.join(directory.path, '.mason-cache'),
        )..createSync(recursive: true);
        BricksJson.testEnvironment = {'HOME': directory.path};
        BricksJson.testIsWindows = false;
        expect(BricksJson.rootDir.path, equals(appDataCacheDirectory.path));
      });
    });
  });
}
