import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void main() {
  group('MasonGenerator', () {
    group('.fromBrickYaml', () {
      test('constructs an instance', () async {
        const name = 'Dash';
        final brickYaml = BrickYaml(
          'hello_world',
          'A Simple Hello World Template',
          path: path.join('..', '..', 'bricks', 'hello_world', 'brick.yaml'),
          vars: const ['name'],
        );
        final generator = await MasonGenerator.fromBrickYaml(brickYaml);
        final tempDir = Directory.systemTemp.createTempSync();
        final fileCount = await generator.generate(
          DirectoryGeneratorTarget(tempDir),
          vars: <String, dynamic>{'name': name},
        );
        final file = File(path.join(tempDir.path, 'HELLO.md'));
        expect(fileCount, equals(1));
        expect(file.existsSync(), isTrue);
        expect(
          file.readAsStringSync(),
          equals(
            '# 🧱 Dash\n'
            '\n'
            'Hello Dash!\n'
            '\n'
            '_made with 💖 by mason_',
          ),
        );
      });
    });
  });
}
