import 'package:mason/mason.dart';
import 'package:test/test.dart';

void main() {
  const mockText = 'This is-Some_sampleText. YouDig?';

  group('StringCaseExtensions', () {
    group('snake_case', () {
      test('from empty string.', () {
        expect(''.snakeCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(mockText.snakeCase, equals('this_is_some_sample_text_you_dig?'));
      });
    });

    group('dot.case', () {
      test('from empty string.', () {
        expect(''.dotCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(mockText.dotCase, equals('this.is.some.sample.text.you.dig?'));
      });
    });

    group('path/case', () {
      test('from empty string.', () {
        expect(''.pathCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(mockText.pathCase, equals('this/is/some/sample/text/you/dig?'));
      });
    });

    group('param-case', () {
      test('from empty string.', () {
        expect(''.paramCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(mockText.paramCase, equals('this-is-some-sample-text-you-dig?'));
      });
    });

    group('PascalCase', () {
      test('from empty string.', () {
        expect(''.pascalCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(mockText.pascalCase, equals('ThisIsSomeSampleTextYouDig?'));
      });
    });

    group('Pascal.Dot.Case', () {
      test('from empty string.', () {
        expect(''.pascalDotCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(
          mockText.pascalDotCase,
          equals('This.Is.Some.Sample.Text.You.Dig?'),
        );
      });
    });

    group('Header-Case', () {
      test('from empty string.', () {
        expect(''.headerCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(
          mockText.headerCase,
          equals('This-Is-Some-Sample-Text-You-Dig?'),
        );
      });
    });

    group('Title Case', () {
      test('from empty string.', () {
        expect(''.titleCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(mockText.titleCase, equals('This Is Some Sample Text You Dig?'));
      });
    });

    group('camelCase', () {
      test('from empty string.', () {
        expect(''.camelCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(mockText.camelCase, equals('thisIsSomeSampleTextYouDig?'));
      });
    });

    group('Sentence case', () {
      test('from empty string.', () {
        expect(''.sentenceCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(
          mockText.sentenceCase,
          equals('This is some sample text you dig?'),
        );
      });
    });

    group('CONSTANT_CASE', () {
      test('from empty string.', () {
        expect(''.constantCase, equals(''));
      });

      test('from "$mockText".', () {
        expect(
          mockText.constantCase,
          equals('THIS_IS_SOME_SAMPLE_TEXT_YOU_DIG?'),
        );
      });
    });
  });
}
