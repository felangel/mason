import 'dart:io';

import 'package:mason/src/git.dart';
import 'package:test/test.dart';

void main() {
  group('Git', () {
    group('run', () {
      test('throws when operation fails', () async {
        expect(
          () => Git.run(['clone', 'https://github.com/felangel/masons']),
          throwsA(isA<ProcessException>()),
        );
      });

      test('completes when operation succeeds', () async {
        expect(Git.run(['--version']), completes);
      });
    });
  });
}
