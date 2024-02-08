import 'dart:io';

import 'package:mason/src/brick_ignore.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$BrickIgnore', () {
    late File brickIgnoreFile;

    setUp(() {
      final temporaryDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => temporaryDirectory.deleteSync(recursive: true));

      brickIgnoreFile =
          File(path.join(temporaryDirectory.path, BrickIgnore.file))
            ..createSync();
    });

    test('fromFile returns normally', () {
      expect(
        () => BrickIgnore.fromFile(brickIgnoreFile),
        returnsNormally,
      );
    });

    group('isIgnored', () {
      test('returns true when the file is ignored', () {
        brickIgnoreFile.writeAsStringSync('**.md');
        final brickIgnore = BrickIgnore.fromFile(brickIgnoreFile);

        final ignoredFilePath = path.join(
          brickIgnoreFile.parent.path,
          '__brick__',
          'HELLO.md',
        );

        expect(
          brickIgnore.isIgnored(ignoredFilePath),
          isTrue,
          reason: '`HELLO.md` is under `__brick__` and is ignored by `**.md`',
        );
      });

      test(
        'returns false when the file to be ignored is not under __brick__',
        () {
          brickIgnoreFile.writeAsStringSync('**.md');
          final brickIgnore = BrickIgnore.fromFile(brickIgnoreFile);

          final ignoredFilePath =
              path.join(brickIgnoreFile.parent.path, 'HELLO.md');

          expect(
            brickIgnore.isIgnored(ignoredFilePath),
            isFalse,
            reason: '`HELLO.md` is not under `__brick__`',
          );
        },
      );

      test('returns false when the file is not ignored', () {
        brickIgnoreFile.writeAsStringSync('');
        final brickIgnore = BrickIgnore.fromFile(brickIgnoreFile);

        final ignoredFilePath = path.join(
          brickIgnoreFile.parent.path,
          '__brick__',
          'HELLO.md',
        );

        expect(
          brickIgnore.isIgnored(ignoredFilePath),
          isFalse,
          reason: '`HELLO.md` is under `__brick__` and there are no ignores',
        );
      });

      test('returns as expected when the file has comments', () {
        brickIgnoreFile.writeAsStringSync('''
# Some comment
**.md
''');
        final brickIgnore = BrickIgnore.fromFile(brickIgnoreFile);

        final ignoredFilePath = path.join(
          brickIgnoreFile.parent.path,
          '__brick__',
          'HELLO.md',
        );
        expect(
          brickIgnore.isIgnored(ignoredFilePath),
          isTrue,
          reason: '`HELLO.md` is under `__brick__` and is ignored by `**.md`',
        );

        final notIgnoredFilePath = path.join(
          brickIgnoreFile.parent.path,
          '__brick__',
          'main.dart',
        );
        expect(
          brickIgnore.isIgnored(notIgnoredFilePath),
          isFalse,
          reason: '`main.dart` is under `__brick__` and there are no ignores',
        );
      });
    });
  });
}
