import 'dart:io';

import 'package:masonex/src/git.dart';
import 'package:test/test.dart';

void main() {
  group('Git', () {
    group('run', () {
      test('throws when operation fails', () async {
        expect(
          () => Git.run(['clone', 'https://github.com/felangel/masonexs']),
          throwsA(isA<ProcessException>()),
        );
      });

      test('completes when operation succeeds', () async {
        expect(Git.run(['--version']), completes);
      });
    });
  });
}
