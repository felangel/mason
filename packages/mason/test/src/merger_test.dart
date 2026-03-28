import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Merger', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('merges Dart list variables', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))..createSync();
      File(path.join(brickFiles.path, '>>>file.dart')).writeAsStringSync('''
var list = ['banana', 'manzana'];
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.dart'))
        ..writeAsStringSync('''
var list = ['naranja'];
''');

      final generator = await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      expect(targetFile.readAsStringSync(), contains("var list = ['naranja', 'banana', 'manzana'];"));
    });

    test('merges Dart map variables', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))..createSync();
      File(path.join(brickFiles.path, '>>>file.dart')).writeAsStringSync('''
var map = {'b': 2, 'c': 3};
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.dart'))
        ..writeAsStringSync('''
var map = {'a': 1, 'b': 0};
''');

      final generator = await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      final content = targetFile.readAsStringSync();
      expect(content, contains("'a': 1"));
      expect(content, contains("'b': 2"));
      expect(content, contains("'c': 3"));
    });

    test('merges JSON files', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))..createSync();
      File(path.join(brickFiles.path, '>>>file.json')).writeAsStringSync('''
{
  "list": [2, 3],
  "map": {"b": 2}
}
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.json'))
        ..writeAsStringSync('''
{
  "list": [1],
  "map": {"a": 1}
}
''');

      final generator = await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      final content = targetFile.readAsStringSync();
      expect(content, contains('"list":[1,2,3]'));
      expect(content, contains('"map":{"a":1,"b":2}'));
    });

    test('merges YAML files', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))..createSync();
      File(path.join(brickFiles.path, '>>>file.yaml')).writeAsStringSync('''
list:
  - banana
  - manzana
map:
  b: 2
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.yaml'))
        ..writeAsStringSync('''
list:
  - naranja
map:
  a: 1
  b: 0
''');

      final generator = await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      final content = targetFile.readAsStringSync();
      expect(content, contains('- naranja'));
      expect(content, contains('- banana'));
      expect(content, contains('- manzana'));
      expect(content, contains('a: 1'));
      expect(content, contains('b: 2'));
    });

    test('appends new Dart variables', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))
        ..createSync();
      File(path.join(brickFiles.path, '>>>file.dart')).writeAsStringSync('''
final newVar = 'new';
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))
        ..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.dart'))
        ..writeAsStringSync('''
var oldVar = 'old';
''');

      final generator =
          await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      final content = targetFile.readAsStringSync();
      expect(content, contains("var oldVar = 'old';"));
      expect(content, contains("final newVar = 'new';"));
    });

    test('merges Dart list variables in complex file', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))
        ..createSync();
      File(path.join(brickFiles.path, '>>>file.dart')).writeAsStringSync('''
var list = ['banana', 'manzana'];
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))
        ..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.dart'))
        ..writeAsStringSync('''
import 'dart:math';

class PublicClass {
  void sayHi() => print('hi');
}

class _PrivateClass {
  int get value => 42;
}

var list = ['naranja'];

void main() {
  print('Running...');
  PublicClass().sayHi();
}
''');

      final generator =
          await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      final content = targetFile.readAsStringSync();
      expect(content, contains("import 'dart:math';"));
      expect(content, contains('class PublicClass'));
      expect(content, contains('class _PrivateClass'));
      expect(content, contains("var list = ['naranja', 'banana', 'manzana'];"));
      expect(content, contains('void main()'));
    });

    test('merges Dart list variables inside classes', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))
        ..createSync();
      File(path.join(brickFiles.path, '>>>file.dart')).writeAsStringSync('''
class MyClass {
  static var list = ['banana'];
}
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))
        ..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.dart'))
        ..writeAsStringSync('''
class MyClass {
  static var list = ['naranja'];
}
''');

      final generator =
          await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      final content = targetFile.readAsStringSync();
      expect(content, contains("static var list = ['naranja', 'banana']"));
    });

    test('appends new variable to file with only a class', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))
        ..createSync();
      File(path.join(brickFiles.path, '>>>file.dart')).writeAsStringSync('''
var lista = [3];
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))
        ..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.dart'))
        ..writeAsStringSync('''
class Clazz {}
''');

      final generator =
          await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      final content = targetFile.readAsStringSync();
      expect(content, contains('class Clazz {}'));
      expect(content, contains('var lista = [3];'));
    });

    test('appends new class from brick to target with existing class', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))
        ..createSync();
      File(path.join(brickFiles.path, '>>>file.dart')).writeAsStringSync('''
class NewClass {}
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))
        ..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.dart'))
        ..writeAsStringSync('''
class ExistingClass {}
''');

      final generator =
          await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      final content = targetFile.readAsStringSync();
      expect(content, contains('class ExistingClass {}'));
      expect(content, contains('class NewClass {}'));
    });

    test('merges imports', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))
        ..createSync();
      File(path.join(brickFiles.path, '>>>file.dart')).writeAsStringSync('''
import 'package:new_pkg/new_pkg.dart';

var list = ['banana'];
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))
        ..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.dart'))
        ..writeAsStringSync('''
import 'package:old_pkg/old_pkg.dart';

var list = ['naranja'];
''');

      final generator =
          await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      final content = targetFile.readAsStringSync();
      expect(content, contains("import 'package:new_pkg/new_pkg.dart';"));
      expect(content, contains("import 'package:old_pkg/old_pkg.dart';"));
      expect(content, contains("var list = ['naranja', 'banana']"));
    });

    test('handles variables with same name in different scopes', () async {
      final brickDir = Directory(path.join(tempDir.path, 'brick'))..createSync();
      File(path.join(brickDir.path, 'brick.yaml')).writeAsStringSync('''
name: test_brick
description: test
version: 0.1.0
''');
      final brickFiles = Directory(path.join(brickDir.path, '__brick__'))
        ..createSync();
      File(path.join(brickFiles.path, '>>>file.dart')).writeAsStringSync('''
var list = ['top_banana'];

class MyClass {
  static var list = ['class_banana'];
}
''');

      final targetDir = Directory(path.join(tempDir.path, 'target'))
        ..createSync();
      final targetFile = File(path.join(targetDir.path, 'file.dart'))
        ..writeAsStringSync('''
var list = ['top_naranja'];

class MyClass {
  static var list = ['class_naranja'];
}
''');

      final generator =
          await MasonGenerator.fromBrick(Brick.path(brickDir.path));
      await generator.generate(DirectoryGeneratorTarget(targetDir));

      final content = targetFile.readAsStringSync();
      expect(content, contains("var list = ['top_naranja', 'top_banana']"));
      expect(content, contains("static var list = ['class_naranja', 'class_banana']"));
    });
  });
}
