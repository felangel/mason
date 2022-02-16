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
        const input = 'Greeting: {{greeting|camelCase}}!';
        const expected = 'Greeting: helloWorld!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('constantCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting|constantCase}}!';
        const expected = 'Greeting: HELLO_WORLD!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('dotCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting|dotCase}}!';
        const expected = 'Greeting: hello.world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('headerCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting|headerCase}}!';
        const expected = 'Greeting: Hello-World!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('lowerCase outputs correct string', () {
        const greeting = 'Hello World';
        const input = 'Greeting: {{greeting|lowerCase}}!';
        const expected = 'Greeting: hello world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('pascalCase outputs correct string', () {
        const greeting = 'Hello World';
        const input = 'Greeting: {{greeting|pascalCase}}!';
        const expected = 'Greeting: HelloWorld!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('paramCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting|paramCase}}!';
        const expected = 'Greeting: hello-world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('pathCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting|pathCase}}!';
        const expected = 'Greeting: hello/world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('sentenceCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting|sentenceCase}}!';
        const expected = 'Greeting: Hello world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('snakeCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting|snakeCase}}!';
        const expected = 'Greeting: hello_world!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('titleCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting|titleCase}}!';
        const expected = 'Greeting: Hello World!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });

      test('upperCase outputs correct string', () {
        const greeting = 'hello world';
        const input = 'Greeting: {{greeting|upperCase}}!';
        const expected = 'Greeting: HELLO WORLD!';
        expect(
          input.render(<String, dynamic>{'greeting': greeting}),
          equals(expected),
        );
      });
    });
  });
}
