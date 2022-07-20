// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mason/src/bricks_json.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

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

      final brick = Brick.path(path.join('..', '..', 'bricks', 'simple'));
      final result = await bricksJson.add(brick);

      expect(result.path, isNotEmpty);
      expect(result.brick, equals(brick));
      expect(bricksJson.encode, contains('"simple":'));

      await bricksJson.flush();

      final newBricksJson = BricksJson(directory: directory);
      expect(newBricksJson.encode, contains('"simple":'));
    });

    test('can be instantiated with global directory', () {
      final bricksJson = BricksJson.global();
      expect(bricksJson, isNotNull);
    });

    test('can be instantiated with temp directory', () {
      final bricksJson = BricksJson.temp();
      expect(bricksJson, isNotNull);
    });

    test('throws MalformedBricksJson when bricks.json is malformed', () {
      final directory = Directory.systemTemp.createTempSync();
      File(
        path.join(directory.path, '.mason', 'bricks.json'),
      )
        ..createSync(recursive: true)
        ..writeAsStringSync('[]');
      expect(
        () => BricksJson(directory: directory),
        throwsA(isA<MalformedBricksJson>()),
      );
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
        expect(bricksJson.cache, isEmpty);
      });
    });

    group('add', () {
      test('adds bricks to bricks.json (registry)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        final brick = Brick.version(name: 'greeting', version: '0.1.0+1');
        final result = await bricksJson.add(brick);
        expect(result.path, isNotEmpty);
        expect(result.brick.name, equals(brick.name));
        expect(result.brick.location.version, equals(brick.location.version));
        expect(bricksJson.encode, contains('greeting_'));
      });

      test('adds bricks to bricks.json with constraint (registry)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        final brick = Brick.version(name: 'greeting', version: '^0.1.0');
        final result = await bricksJson.add(brick);
        expect(result.path, isNotEmpty);
        expect(result.brick.name, equals(brick.name));
        expect(result.brick.location.version, equals('0.1.0+2'));
        expect(bricksJson.encode, contains('greeting_'));
      });

      test('adds bricks to bricks.json with range (registry)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        final brick = Brick.version(
          name: 'greeting',
          version: '>=0.1.0 <0.1.0+2',
        );
        final result = await bricksJson.add(brick);
        expect(result.path, isNotEmpty);
        expect(result.brick.name, equals(brick.name));
        expect(result.brick.location.version, equals('0.1.0+1'));
        expect(bricksJson.encode, contains('greeting_'));
      });

      test(
          'adds bricks to bricks.json via registry '
          'with existing empty directory', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final brick = Brick.version(name: 'greeting', version: '0.1.0+1');
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));

        final result1 = await bricksJson.add(brick);
        expect(result1.path, isNotEmpty);
        expect(bricksJson.encode, contains('greeting_'));
        Directory(result1.path)
          ..deleteSync(recursive: true)
          ..createSync();

        final result2 = await bricksJson.add(brick);
        expect(result2.path, isNotEmpty);
        expect(bricksJson.encode, contains('greeting_'));
        expect(result1.path, equals(result2.path));
      });

      test('adds bricks to bricks.json (git)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        final brick = Brick.git(
          GitPath(
            'https://github.com/felangel/mason',
            path: 'bricks/simple',
          ),
        );
        final result = await bricksJson.add(brick);
        expect(result.path, isNotEmpty);
        expect(result.brick.name, equals(brick.name));
        expect(result.brick.location.git!.url, equals(brick.location.git!.url));
        expect(
          result.brick.location.git!.path,
          equals(brick.location.git!.path),
        );
        expect(result.brick.location.git!.ref, isNotNull);
        expect(bricksJson.encode, contains('"simple":'));
      });

      test(
          'adds bricks to bricks.json via git '
          'with existing empty directory', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final brick = Brick.git(
          GitPath(
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
        expect(result1.path, isNotEmpty);
        expect(bricksJson.encode, contains('"simple":'));
        Directory(result1.path).parent.parent
          ..deleteSync(recursive: true)
          ..createSync();

        final result2 = await bricksJson.add(brick);
        expect(result2.path, isNotEmpty);
        expect(bricksJson.encode, contains('"simple":'));
        expect(result1.path, equals(result2.path));
      });

      test('adds bricks to bricks.json (git + ref)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        final brick = Brick.git(
          GitPath(
            'https://github.com/felangel/mason',
            path: 'bricks/simple',
            ref: '58a7ba95b01082dfcbcdfc0fb5208551b4cbf558',
          ),
        );
        final result = await bricksJson.add(brick);
        expect(result.path, isNotEmpty);
        expect(result.brick.name, equals(brick.name));
        expect(result.brick.location.git!.url, equals(brick.location.git!.url));
        expect(
          result.brick.location.git!.path,
          equals(brick.location.git!.path),
        );
        expect(result.brick.location.git!.ref, equals(brick.location.git!.ref));
        expect(bricksJson.encode, contains('"simple"'));
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
          Brick.path(path.join('..', '..', 'bricks', 'simple')),
        );
        expect(result.path, isNotEmpty);
        expect(bricksJson.encode, contains('"simple":'));
      });

      test(
          'throws BrickIncompatibleMasonVersion '
          'when brick is incompatible with mason version.', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));

        final brickDirectory = Directory(path.join(directory.path, 'example'))
          ..createSync(recursive: true);
        File(path.join(brickDirectory.path, BrickYaml.file)).writeAsStringSync(
          '''
name: example
description: example
version: 0.1.0+1

environment:
  mason: ">=99.99.99 <100.0.0"
''',
        );
        try {
          await bricksJson.add(Brick.path(brickDirectory.path));
          fail('should throw');
        } on BrickIncompatibleMasonVersion catch (error) {
          expect(
            error.message,
            equals(
              '''The current mason version is $packageVersion.\nBecause example requires mason version >=99.99.99 <100.0.0, version solving failed.''',
            ),
          );
        }

        expect(bricksJson.encode, equals('{}'));
      });

      test(
          'throws BrickResolveVersionException when '
          'brick does not exist (registry)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        expect(
          () => bricksJson.add(
            Brick.version(name: 'nonexistent_brick', version: '^99.99.99'),
          ),
          throwsA(isA<BrickResolveVersionException>()),
        );
      });

      test(
          'throws BrickResolveVersionException when '
          'http request throws (registry)', () async {
        final directory = Directory.systemTemp.createTempSync();
        BricksJson.testEnvironment = {
          'MASON_HOSTED_URL': 'localhost:1234',
          'MASON_CACHE': directory.path,
        };
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        expect(
          () => bricksJson.add(
            Brick.version(name: 'example', version: 'any'),
          ),
          throwsA(isA<BrickResolveVersionException>()),
        );
        BricksJson.testEnvironment = null;
      });

      test(
          'throws BrickResolveVersionException when '
          'http request returns non-200 (registry)', () async {
        final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
        final uri = 'http://${server.address.host}:${server.port}';
        final subscription = server.listen((request) {
          request.response
            ..statusCode = 500
            ..write('')
            ..close();
        });
        final directory = Directory.systemTemp.createTempSync();
        BricksJson.testEnvironment = {
          'MASON_HOSTED_URL': uri,
          'MASON_CACHE': directory.path,
        };
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        await expectLater(
          () => bricksJson.add(
            Brick.version(name: 'example', version: 'any'),
          ),
          throwsA(
            isA<BrickResolveVersionException>().having(
              (e) => e.message,
              'message',
              'Unable to fetch versions for brick "example".',
            ),
          ),
        );
        BricksJson.testEnvironment = null;
        await subscription.cancel();
        await server.close();
      });

      test(
          'throws BrickResolveVersionException when '
          'http request returns malformed body w/out latest version (registry)',
          () async {
        final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
        final uri = 'http://${server.address.host}:${server.port}';
        final subscription = server.listen((request) {
          request.response
            ..statusCode = 200
            ..write('{}')
            ..close();
        });
        final directory = Directory.systemTemp.createTempSync();
        BricksJson.testEnvironment = {
          'MASON_HOSTED_URL': uri,
          'MASON_CACHE': directory.path,
        };
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        await expectLater(
          () => bricksJson.add(
            Brick.version(name: 'example', version: 'any'),
          ),
          throwsA(
            isA<BrickResolveVersionException>().having(
              (e) => e.message,
              'message',
              'Unable to parse latest version of brick "example".',
            ),
          ),
        );
        BricksJson.testEnvironment = null;
        await subscription.cancel();
        await server.close();
      });

      test(
          'throws BrickResolveVersionException when '
          'http request returns malformed body w/out versions (registry)',
          () async {
        final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
        final uri = 'http://${server.address.host}:${server.port}';
        final subscription = server.listen((request) {
          request.response
            ..statusCode = 200
            ..write('{"latest": {"version": "42.0.0"}}')
            ..close();
        });
        final directory = Directory.systemTemp.createTempSync();
        BricksJson.testEnvironment = {
          'MASON_HOSTED_URL': uri,
          'MASON_CACHE': directory.path,
        };
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        await expectLater(
          () => bricksJson.add(
            Brick.version(name: 'example', version: '^1.0.0'),
          ),
          throwsA(
            isA<BrickResolveVersionException>().having(
              (e) => e.message,
              'message',
              'Unable to parse available versions for brick "example".',
            ),
          ),
        );
        BricksJson.testEnvironment = null;
        await subscription.cancel();
        await server.close();
      });

      test('throws BrickUnsatisfiedVersionConstraint (registry)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        expect(
          () => bricksJson.add(
            Brick.version(name: 'greeting', version: '^99.99.99'),
          ),
          throwsA(isA<BrickUnsatisfiedVersionConstraint>()),
        );
      });

      test(
          'throws BrickNotFoundException when '
          'brick does not exist (registry)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        expect(
          () => bricksJson.add(
            Brick.version(name: 'greeting', version: '0.0.0'),
          ),
          throwsA(isA<BrickNotFoundException>()),
        );
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
            Brick.git(GitPath('https://github.com/felangel/mason')),
          ),
          throwsA(isA<BrickNotFoundException>()),
        );
      });

      test(
          'throws BrickNotFoundException when '
          'brick does not exist w/path (git)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        expect(
          () => bricksJson.add(
            Brick.git(
              GitPath(
                'https://github.com/felangel/mason',
                path: 'bricks/example',
              ),
            ),
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
          () => bricksJson.add(Brick.path('simple')),
          throwsA(isA<BrickNotFoundException>()),
        );
      });

      test(
          'throws MasonYamlNameMismatch when '
          'mason.yaml contains mismatch (path)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        expect(
          () => bricksJson.add(
            Brick(
              name: 'simple1',
              location: BrickLocation(
                path: path.join('..', '..', 'bricks', 'simple'),
              ),
            ),
          ),
          throwsA(isA<MasonYamlNameMismatch>()),
        );
      });

      test(
          'throws MasonYamlNameMismatch when '
          'brick name does not match (git)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        expect(
          () => bricksJson.add(
            Brick(
              name: 'greetings',
              location: BrickLocation(
                git: GitPath(
                  'https://github.com/felangel/mason',
                  path: 'bricks/greeting',
                ),
              ),
            ),
          ),
          throwsA(isA<MasonYamlNameMismatch>()),
        );
      });

      test(
          'throws MasonYamlNameMismatch when '
          'brick name does not match (existing git)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final bricksJson = BricksJson(directory: directory);
        final file = File(
          path.join(directory.path, '.mason', 'bricks.json'),
        )..createSync(recursive: true);
        expect(file.existsSync(), isTrue);
        expect(bricksJson.encode, equals('{}'));
        await bricksJson.add(
          Brick(
            name: 'greeting',
            location: BrickLocation(
              git: GitPath(
                'https://github.com/felangel/mason',
                path: 'bricks/greeting',
              ),
            ),
          ),
        );
        expect(
          () => bricksJson.add(
            Brick(
              name: 'greetings',
              location: BrickLocation(
                git: GitPath(
                  'https://github.com/felangel/mason',
                  path: 'bricks/greeting',
                ),
              ),
            ),
          ),
          throwsA(isA<MasonYamlNameMismatch>()),
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
          Brick.path(path.join('..', '..', 'bricks', 'simple')),
        );
        expect(result.path, isNotEmpty);
        expect(bricksJson.encode, contains('"simple":'));
        expect(file.readAsStringSync(), isEmpty);
        await bricksJson.flush();
        expect(file.readAsStringSync(), contains('"simple":'));
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

        final brick = Brick(
          name: 'simple',
          location: BrickLocation(
            path: path.join('..', '..', 'bricks', 'simple'),
          ),
        );
        final result = await bricksJson.add(brick);
        expect(result.path, isNotEmpty);
        expect(bricksJson.encode, contains('"simple":'));
        bricksJson.remove(brick);
        expect(bricksJson.encode, equals('{}'));
        expect(bricksJson.cache, isEmpty);
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
