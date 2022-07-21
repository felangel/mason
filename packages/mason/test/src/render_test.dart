import 'dart:convert';

import 'package:mason/src/render.dart';
import 'package:mustache_template/mustache_template.dart' show Template;
import 'package:test/test.dart';

void main() {
  group('render', () {
    test('outputs unchanged string when there are no variables', () {
      const input = 'hello world';
      expect(input.render(<String, dynamic>{}), equals(input));
    });

    test('outputs correct string when there is a single variable', () {
      const name = 'dash';
      const input = 'hello {{name}}';
      const expected = 'hello $name';
      expect(input.render(<String, dynamic>{'name': name}), equals(expected));
    });

    test('outputs correct string when there is are multiple variables', () {
      const name = 'dash';
      const age = 42;
      const input = 'hello {{name}}! Age is {{age}}';
      const expected = 'hello $name! Age is $age';
      expect(
        input.render(<String, dynamic>{'name': name, 'age': age}),
        equals(expected),
      );
    });

    test('outputs correct string when variable is missing', () {
      const input = 'hello {{name}}!';
      const expected = 'hello !';
      expect(input.render(<String, dynamic>{}), equals(expected));
    });

    group('partials', () {
      test('resolve outputs correct template', () {
        const name = 'header';
        const content = 'Hello world!';
        final source = utf8.encode(content);
        expect(
          {'{{~ $name }}': source}.resolve(name),
          isA<Template>()
              .having((template) => template.name, 'name', name)
              .having((template) => template.source, 'source', content),
        );
      });

      test('resolve outputs correct template w/lambda', () {
        const name = 'header';
        const content = 'Hello {{#upperCase}}{{name}}{{/upperCase}}!';
        final source = utf8.encode(content);
        expect(
          {'{{~ $name }}': source}.resolve(name),
          isA<Template>()
              .having((template) => template.name, 'name', name)
              .having((template) => template.source, 'source', content),
        );
      });

      test('resolve outputs correct template w/lambda shorthand', () {
        const name = 'header';
        const content = 'Hello {{name.upperCase()}}!';
        final source = utf8.encode(content);
        const expected = 'Hello {{#upperCase}}{{name}}{{/upperCase}}!';
        expect(
          {'{{~ $name }}': source}.resolve(name),
          isA<Template>()
              .having((template) => template.name, 'name', name)
              .having((template) => template.source, 'source', expected),
        );
      });
    });

    group('lambdas', () {
      test('camelCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{#camelCase}}{{greeting}}{{/camelCase}}!';
        const expected = 'Greeting: helloWorld!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('constantCase outputs correct string', () {
        const greeting = 'hello world';
        const input =
            'Greeting: {{#constantCase}}{{greeting}}{{/constantCase}}!';
        const expected = 'Greeting: HELLO_WORLD!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('dotCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{#dotCase}}{{greeting}}{{/dotCase}}!';
        const expected = 'Greeting: hello.world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('headerCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{#headerCase}}{{greeting}}{{/headerCase}}!';
        const expected = 'Greeting: Hello-World!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('lowerCase outputs correct string', () {
        const greeting = 'Hello World';
        const input = 'Greeting: {{#lowerCase}}{{greeting}}{{/lowerCase}}!';
        const expected = 'Greeting: hello world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('mustacheCase outputs correct string', () {
        const greeting = 'Hello World';
        const input =
            'Greeting: {{#mustacheCase}}{{greeting}}{{/mustacheCase}}!';
        const expected = 'Greeting: {{ Hello World }}!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('pascalCase outputs correct string', () {
        const greeting = 'Hello World';
        const input = 'Greeting: {{#pascalCase}}{{greeting}}{{/pascalCase}}!';
        const expected = 'Greeting: HelloWorld!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('paramCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{#paramCase}}{{greeting}}{{/paramCase}}!';
        const expected = 'Greeting: hello-world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('pathCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{#pathCase}}{{greeting}}{{/pathCase}}!';
        const expected = 'Greeting: hello/world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('sentenceCase outputs correct string', () {
        const greeting = 'hello world';
        const input =
            'Greeting: {{#sentenceCase}}{{greeting}}{{/sentenceCase}}!';
        const expected = 'Greeting: Hello world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('snakeCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{#snakeCase}}{{greeting}}{{/snakeCase}}!';
        const expected = 'Greeting: hello_world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('titleCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{#titleCase}}{{greeting}}{{/titleCase}}!';
        const expected = 'Greeting: Hello World!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('upperCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{#upperCase}}{{greeting}}{{/upperCase}}!';
        const expected = 'Greeting: HELLO WORLD!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });
    });

    group('lambda shortcuts', () {
      test('camelCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.camelCase()}}!';
        const expected = 'Greeting: helloWorld!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('constantCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.constantCase()}}!';
        const expected = 'Greeting: HELLO_WORLD!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('dotCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.dotCase()}}!';
        const expected = 'Greeting: hello.world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('headerCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.headerCase()}}!';
        const expected = 'Greeting: Hello-World!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('lowerCase outputs correct string', () {
        const greeting = 'Hello World';
        const input = 'Greeting: {{greeting.lowerCase()}}!';
        const expected = 'Greeting: hello world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('pascalCase outputs correct string', () {
        const greeting = 'Hello World';
        const input = 'Greeting: {{greeting.pascalCase()}}!';
        const expected = 'Greeting: HelloWorld!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('paramCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.paramCase()}}!';
        const expected = 'Greeting: hello-world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('pathCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.pathCase()}}!';
        const expected = 'Greeting: hello/world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('sentenceCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.sentenceCase()}}!';
        const expected = 'Greeting: Hello world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('snakeCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.snakeCase()}}!';
        const expected = 'Greeting: hello_world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('titleCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.titleCase()}}!';
        const expected = 'Greeting: Hello World!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('upperCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.upperCase()}}!';
        const expected = 'Greeting: HELLO WORLD!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('support chaining', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting.dotCase().upperCase()}}!';
        const expected = 'Greeting: HELLO.WORLD!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('support unescaped chaining', () {
        const greeting = '"hello world"';
        const input = 'Greeting: {{{greeting.dotCase().upperCase()}}}!';
        const expected = 'Greeting: "HELLO.WORLD"!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('support multiple unescaped lambdas', () {
        const greeting = '"hello world"';
        const name = '"dash"';
        const input =
            '''Greeting: {{{greeting.upperCase()}}} Name: {{{name.upperCase()}}}!''';
        const expected = 'Greeting: "HELLO WORLD" Name: "DASH"!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting, 'name': name}),
          equals(expected),
        );
      });

      test('mixed with regular mustache syntax after', () {
        const greeting = 'hello world';
        const input =
            'Greeting: {{greeting.upperCase()}}{{#is_suffixed}}!{{/is_suffixed}}';
        var expected = 'Greeting: HELLO WORLD!';
        expect(
          input.render(
            <String, dynamic>{
              'greeting': greeting,
              'is_suffixed': true,
            },
          ),
          equals(expected),
        );
        expected = 'Greeting: HELLO WORLD';
        expect(
          input.render(
            <String, dynamic>{
              'greeting': greeting,
              'is_suffixed': false,
            },
          ),
          equals(expected),
        );
      });

      test('mixed with regular mustache syntax before', () {
        const greeting = 'hello world';
        const input =
            '{{#is_prefixed}}Greeting: {{/is_prefixed}}{{greeting.upperCase()}}!';
        var expected = 'Greeting: HELLO WORLD!';
        expect(
          input.render(
            <String, dynamic>{
              'greeting': greeting,
              'is_prefixed': true,
            },
          ),
          equals(expected),
        );
        expected = 'HELLO WORLD!';
        expect(
          input.render(
            <String, dynamic>{
              'greeting': greeting,
              'is_prefixed': false,
            },
          ),
          equals(expected),
        );
      });

      test('mixed within loop (List<String>)', () {
        const values = 'RED,GREEN,BLUE,';
        const input = 'Greeting: {{#colors}}{{..upperCase()}},{{/colors}}!';
        const expected = 'Greeting: $values!';
        expect(
          input.render(<String, dynamic>{
            'colors': ['red', 'green', 'blue']
          }),
          equals(expected),
        );
      });

      test('mixed within loop (List<Map>)', () {
        const values = 'RED,GREEN,BLUE,';
        const input = 'Greeting: {{#colors}}{{name.upperCase()}},{{/colors}}!';
        const expected = 'Greeting: $values!';
        expect(
          input.render(<String, dynamic>{
            'colors': [
              {'name': 'red'},
              {'name': 'green'},
              {'name': 'blue'}
            ]
          }),
          equals(expected),
        );
      });

      test('handles nested variables', () {
        const input = '{{greeting.name.upperCase()}}';
        const expected = 'HELLO WORLD';
        expect(
          input.render(<String, dynamic>{
            'greeting': {
              'name': 'hello world',
            },
          }),
          equals(expected),
        );
      });

      test('allows whitespace', () {
        const input = '{{ greeting.upperCase() }}';
        const expected = 'HELLO WORLD';
        expect(
          input.render(<String, dynamic>{
            'greeting': 'hello world',
          }),
          equals(expected),
        );
      });

      test('nested lambdas with whitespace', () {
        const input = '{{ greeting.dotCase().upperCase() }}';
        const expected = 'HELLO.WORLD';
        expect(
          input.render(<String, dynamic>{
            'greeting': 'hello world',
          }),
          equals(expected),
        );
      });

      test('asymmetrical curly brackets (prefix)', () {
        const input = '{{{greeting.dotCase()}}';
        const expected = '{hello.world';
        expect(
          input.render(<String, dynamic>{
            'greeting': 'hello world',
          }),
          equals(expected),
        );
      });

      test('asymmetrical curly brackets (suffix)', () {
        const input = '{{greeting.dotCase()}}}';
        const expected = 'hello.world}';
        expect(
          input.render(<String, dynamic>{
            'greeting': 'hello world',
          }),
          equals(expected),
        );
      });
    });
  });
}
