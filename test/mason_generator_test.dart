import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import 'bundles/bundles.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('MasonGenerator', () {
    late Logger logger;

    setUp(() {
      logger = MockLogger();
    });

    group('.fromBundle', () {
      test('creates a generator from bundle (pre hooks)', () async {
        final generator = await MasonGenerator.fromBundle(legacyGreetingBundle);
        final hooks = generator.hooks;

        expect(hooks.preGen, isNull);
        expect(hooks.postGen, isNull);
        expect(generator.id, equals('greeting'));

        final target = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(target, logger),
        );
        expect(fileCount, equals(1));
        expect(
          File(path.join(target.path, 'GREETINGS.md')).existsSync(),
          isTrue,
        );
        target.deleteSync(recursive: true);
      });

      test('creates a generator from bundle (no hooks)', () async {
        final generator = await MasonGenerator.fromBundle(greetingBundle);
        final hooks = generator.hooks;

        expect(hooks.preGen, isNull);
        expect(hooks.postGen, isNull);
        expect(generator.id, equals('greeting'));

        final target = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(target, logger),
        );
        expect(fileCount, equals(1));
        expect(
          File(path.join(target.path, 'GREETINGS.md')).existsSync(),
          isTrue,
        );
        target.deleteSync(recursive: true);
      });

      test('creates a generator from bundle (with hooks)', () async {
        final generator = await MasonGenerator.fromBundle(hooksBundle);
        final hooks = generator.hooks;

        expect(hooks.preGen, isNotNull);
        expect(hooks.postGen, isNotNull);
        expect(generator.id, equals('hooks'));

        final target = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(target, logger),
        );
        expect(fileCount, equals(1));
        expect(
          File(path.join(target.path, 'hooks.md')).existsSync(),
          isTrue,
        );
        target.deleteSync(recursive: true);
      });
    });
  });
}
