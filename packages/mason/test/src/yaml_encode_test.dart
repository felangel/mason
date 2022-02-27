import 'package:mason/mason.dart';
import 'package:test/test.dart';

void main() {
  group('Yaml', () {
    group('encode', () {
      test('handles empty map correctly', () {
        const input = <String, dynamic>{};
        const expected = '';
        expect(Yaml.encode(input), equals(expected));
      });

      test('handles {string:string} correctly', () {
        const input = <String, dynamic>{'key': 'value'};
        const expected = 'key: value';
        expect(Yaml.encode(input), equals(expected));
      });

      test('handles {string:string} correctly (semver)', () {
        const input = <String, dynamic>{'key': '1.2.3'};
        const expected = 'key: 1.2.3';
        expect(Yaml.encode(input), equals(expected));
      });

      test('handles {string:bool} correctly', () {
        const input = <String, dynamic>{'key': false};
        const expected = 'key: false';
        expect(Yaml.encode(input), equals(expected));
      });

      test('handles {string:num} correctly', () {
        const input = <String, dynamic>{'key': 42};
        const expected = 'key: 42';
        expect(Yaml.encode(input), equals(expected));
      });

      test('handles {string:map} correctly', () {
        const input = <String, dynamic>{
          'key': {'foo': 'bar'}
        };
        const expected = '''
key:
  foo: bar''';
        expect(Yaml.encode(input), equals(expected));
      });

      test('handles {string:list} correctly', () {
        const input = <String, dynamic>{
          'key': ['a', 1, false]
        };
        const expected = '''
key:
  - a
  - 1
  - false''';
        expect(Yaml.encode(input), equals(expected));
      });

      test('handles {string:list} correctly (multiline)', () {
        const input = <String, dynamic>{
          'key': ['a', 1, false, 'abc\ndef']
        };
        const expected = '''
key:
  - a
  - 1
  - false
  - |
        abc
        def''';
        expect(Yaml.encode(input), equals(expected));
      });
    });
  });
}
