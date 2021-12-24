import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void main() {
  group('Bundler', () {
    group('createBundle', () {
      test('throws if brick does not exist', () {
        final message =
            '''Could not find brick at ${path.join(Directory.current.path, BrickYaml.file)}''';
        expect(
          () => createBundle(Directory.current),
          throwsA(
            isA<BrickNotFoundException>().having(
              (e) => e.message,
              'message',
              message,
            ),
          ),
        );
      });

      test('returns a MasonBundle when brick exists (simple)', () {
        final bundle = createBundle(
          Directory(path.join('..', '..', 'bricks', 'simple')),
        );
        expect(bundle.name, equals('simple'));
        expect(bundle.description, equals('A Simple Static Template'));
        expect(bundle.hooks, isEmpty);
        expect(bundle.files.length, equals(1));
      });

      test('returns a MasonBundle when brick exists (hooks)', () {
        final bundle = createBundle(
          Directory(path.join('..', '..', 'bricks', 'hooks')),
        );
        expect(bundle.name, equals('hooks'));
        expect(bundle.description, equals('A Hooks Example Template'));
        expect(bundle.hooks.length, equals(2));
        expect(bundle.files.length, equals(1));
      });
    });
  });
}
