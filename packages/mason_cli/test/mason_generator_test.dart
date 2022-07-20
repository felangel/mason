import 'dart:io';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'bundles/bundles.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('MasonGenerator', () {
    late Logger logger;

    setUp(() {
      logger = MockLogger();
    });

    group('.fromBundle', () {
      test('creates a generator from bundle (legacy)', () async {
        final generator = await MasonGenerator.fromBundle(legacyGreetingBundle);
        final hooks = generator.hooks;

        expect(hooks.preGenHook, isNull);
        expect(hooks.postGenHook, isNull);
        expect(generator.id, equals('greeting'));

        final target = Directory.systemTemp.createTempSync();
        final files = await generator.generate(
          DirectoryGeneratorTarget(target),
          logger: logger,
        );
        expect(files.length, equals(1));
        expect(
          File(path.join(target.path, 'GREETINGS.md')).existsSync(),
          isTrue,
        );
        target.deleteSync(recursive: true);
      });

      test('creates a generator from bundle (no hooks)', () async {
        final generator = await MasonGenerator.fromBundle(greetingBundle);
        final hooks = generator.hooks;

        expect(hooks.preGenHook, isNull);
        expect(hooks.postGenHook, isNull);
        expect(generator.id, equals('greeting'));

        final target = Directory.systemTemp.createTempSync();
        final files = await generator.generate(
          DirectoryGeneratorTarget(target),
          logger: logger,
        );
        expect(files.length, equals(1));
        expect(
          File(path.join(target.path, 'GREETINGS.md')).existsSync(),
          isTrue,
        );
        target.deleteSync(recursive: true);
      });

      test('creates a generator from bundle (with hooks)', () async {
        final generator = await MasonGenerator.fromBundle(hooksBundle);
        final hooks = generator.hooks;

        expect(hooks.preGenHook, isNotNull);
        expect(hooks.postGenHook, isNotNull);
        expect(generator.id, equals('hooks'));

        const vars = {'name': 'Dash'};
        final target = Directory.systemTemp.createTempSync();

        await hooks.preGen(vars: vars, workingDirectory: target.path);
        expect(
          File(path.join(target.path, '.pre_gen.txt')).existsSync(),
          isTrue,
        );

        final files = await generator.generate(
          DirectoryGeneratorTarget(target),
          vars: vars,
          logger: logger,
        );
        expect(files.length, equals(1));
        expect(
          File(path.join(target.path, 'hooks.md')).existsSync(),
          isTrue,
        );

        await hooks.postGen(vars: vars, workingDirectory: target.path);
        expect(
          File(path.join(target.path, '.post_gen.txt')).existsSync(),
          isTrue,
        );

        target.deleteSync(recursive: true);
      });
    });
  });
}
