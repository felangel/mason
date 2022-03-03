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

      test('handles {string:map} correctly (complex)', () {
        const input = <String, dynamic>{
          'name': 'todos',
          'description': 'A Todos Template',
          'version': '0.1.0+2',
          'environment': {'mason': 'any'},
          'vars': <String, dynamic>{
            'todos': {
              'type': 'string',
              'description':
                  'JSON Array of todos ([{"todo":"Walk Dog","done":false}])',
              'default': '[{"todo":"Walk Dog","done":false}]',
              'prompt': 'What is the list of todos?'
            },
            'developers': <String, dynamic>{
              'type': 'string',
              'description': 'JSON Array of developers ([{"name": "Dash"}])',
              'default': '[{"name": "Dash"}]',
              'prompt': 'What is the list of developers?'
            }
          }
        };
        const expected = r'''
name: todos
description: A Todos Template
version: 0.1.0+2
environment:
  mason: any
vars:
  todos:
    type: string
    description: "JSON Array of todos ([{\"todo\":\"Walk Dog\",\"done\":false}])"
    default: "[{\"todo\":\"Walk Dog\",\"done\":false}]"
    prompt: "What is the list of todos?"
  developers:
    type: string
    description: "JSON Array of developers ([{\"name\": \"Dash\"}])"
    default: "[{\"name\": \"Dash\"}]"
    prompt: "What is the list of developers?"''';
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
