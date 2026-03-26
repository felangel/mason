import 'dart:typed_data';

import 'package:mustachex/mustachex.dart';
import 'package:test/test.dart';

void main() {
  group('Mustache extended', () {
    test('in a nutshell example', () async {
      var template =
          "{{#hasFoo}} this will be rendered because the hasFoo guard only checks if foo is defined or not, not it's value {{/hasFoo}}"
          '{{greeting_pascalCase}} {{world_pc}}!'
          '{{#hasBar}} This neither {{/hasBar}}';
      var vars = {'greeting': 'HELLO', 'foo': false};
      String fulfillmentFunction(MissingVariableException variable) {
        if (variable.varName == 'world') {
          return 'WORLD';
        } else {
          return 'UNIVERSE';
        }
      }

      // mustachex needs a processor to process templates
      var processor = MustachexProcessor(
          initialVariables: vars, missingVarFulfiller: fulfillmentFunction);
      var processedString = await processor.process(template);
      expect(processedString, contains('Hello World!'),
          reason:
              "from the greeting variable, 'HELLO', and the _pascalCase modifier, the "
              "final result should be 'Hello'. And from the not defined 'world' variable, the "
              "output 'WORLD' should be obtained from the fulfillmentFunction. As the _pc modifier, "
              "which is a shortcut from _pascalCase, the final result should be 'World'. So the final "
              'result is expected to be Hello World!');
      expect(processedString, contains('this will be rendered'),
          reason: 'As for the 0.1.1 version, now the hasXXX '
              'guards only checks if the variable is defined or not, not it\'s value. '
              'So this will be rendered because foo is defined, even if it\'s value is false.');
      expect(await processor.process('{{greeting_pc}} {{xxx_pc}}!'),
          equals('Hello Universe!'));
    });
    test('hasFoo guard behavior', () async {
      final hasFooStr =
          'this will be rendered because hasFoo only checks if foo is'
          ' defined or not, not it\'s value (false)';
      final hasBarStr =
          'this won\'t be rendered because hasBar will be false, because no bar is defined';
      final doesNotHasBazStr =
          'This won\'t be rendered because although baz is defined, '
          'the ^negation operator will make it false';
      final doesNotHasSorpiStr =
          'This will be rendered because sorpi is not defined and the ^ operator is present';
      var template = '{{#hasFoo}} $hasFooStr {{/hasFoo}}'
          '{{#hasBar}} $hasBarStr {{/hasBar}}'
          '{{^hasBaz}} $doesNotHasBazStr {{/hasBaz}}'
          '{{^hasSorpi}} $doesNotHasSorpiStr {{/hasSorpi}}';
      var vars = {'foo': false, 'baz': true};

      var processor = MustachexProcessor(initialVariables: vars);
      var processedString = await processor.process(template);
      expect(processedString, contains(hasFooStr));
      expect(processedString, isNot(contains(hasBarStr)));
      expect(processedString, isNot(contains(doesNotHasBazStr)));
      expect(processedString, contains(doesNotHasSorpiStr));
    });
    test('función de partials', () async {
      var partials = <String, String>{
        'foo': '''Foo: hola {{foo}}''',
        'bar': '''hello {{foo}}'''
      };
      String? partialsFunc(MissingPartialException e) =>
          partials[e.partialName!];

      var workingProcessor = MustachexProcessor(
          partialsResolver: partialsFunc, initialVariables: {'foo': 'f00'});
      var processorWithoutPartialsResolver =
          MustachexProcessor(initialVariables: {'foo': 'f00'});
      var template = '{{>foo}}\n{{> bar}}';
      var processed = await workingProcessor.process(template);
      expect(processorWithoutPartialsResolver.process(template),
          throwsA(isA<MissingPartialsResolverFunction>()));
      expect(processed, contains('hola f00'));
      expect(processed, contains('hello f00'));
      expect(workingProcessor.process('{{>nonExistentPartial}}'),
          throwsA(isA<MissingPartialException>()));
    });
    test('guarda de has', () async {
      var vars = {
        'items': [
          {'name': 'uno'},
          {'name': 'dos'}
        ]
      };
      var processor = MustachexProcessor(initialVariables: vars);
      var template = '{{#hasItems}}{{#items}} -{{name}}{{/items}}{{/hasItems}}';
      var procesado = await processor.process(template);
      expect(procesado, contains('-uno'));
      expect(procesado, contains('-dos'));
      template = '{{#hasSorpos}}{{#items}} -{{name}}{{/items}}{{/hasSorpos}}';
      procesado = await processor.process(template);
      expect(procesado, isNot(contains('-uno')));
      expect(procesado, isNot(contains('-dos')));
    });
    test('recasing functions', () async {
      final input = '{{#pascal_case}}recaseMe{{/pascal_case}}'
          '{{#camel_case}}recaseMe{{/camel_case}}'
          '{{#snake_case}}recaseMe{{/snake_case}}'
          '{{#constantCase}}recaseMe{{/constantCase}}'
          '{{#sentenceCase}}recaseMe{{/sentenceCase}}'
          '{{#paramCase}}recaseMe{{/paramCase}}';
      var processor = MustachexProcessor();
      var procesado = await processor.process(input);
      expect(procesado, contains('RecaseMe'));
      expect(procesado, contains('recaseMe'));
      expect(procesado, contains('recase_me'));
      expect(procesado, contains('RECASE_ME'));
      expect(procesado, contains('Recase me'));
      expect(procesado, contains('recase-me'));
    });
    test('renderiza clases', () async {
      var classesJSON = {
        'classes': [
          {
            'name': 'claseUno',
            'fields': [
              {'name': 'field1', 'type': 'String', 'final': true},
              {'name': 'Field2', 'type': 'int', 'docs': 'tieneDocs'},
            ],
            'methods': []
          },
          {
            'name': 'clase_dos',
            'fields': [
              {'name': 'field1', 'type': 'int'},
            ],
            'methods': [
              {
                'name': 'METHOD_UNO',
                'returnType': 'String',
                'parameters': [
                  {'name': 'param1', 'type': 'String'},
                  {'name': 'param2', 'type': 'double'}
                ]
              },
              {'name': 'method-dos', 'returnType': 'String'}
            ]
          }
        ]
      };
      var vars = VariablesResolver(classesJSON);
      var processor = MustachexProcessor(variablesResolver: vars);
      var template = '''
      {{#classes}}
      class {{name_pc}} {
        {{#fields}}
        {{#hasDocs}}///{{#constant_case}}{{docs}}{{/constant_case}}{{/hasDocs}}
        {{#hasDocs}}///{{docs_pc}}{{/hasDocs}}
        {{#hasFinal}}final {{/hasFinal}}{{type}} {{name_cc}};
        {{/fields}}

        {{name_pc}}();

        {{#methods}}
        {{returnType_pc}} {{name_cc}}({{#hasParameters}}{{#parameters}}{{type}} {{name}},{{/parameters}}{{/hasParameters}}){}
        {{/methods}}
      }
      {{/classes}}
      ''';
      var procesado = await processor.process(template);
      expect(procesado, contains('class ClaseUno'));
      expect(procesado, contains('///TieneDocs'),
          reason: 'The {{varName_pc}} recasing should work properly');
      expect(procesado, contains('///TIENE_DOCS'),
          reason:
              'The {{#constant_case}}{{/constant_case}} recasing should work properly');
      expect(procesado, contains('final String field1;'));
      expect(procesado, contains('int field2;'));
      expect(procesado, contains('String methodDos()'));
      expect(procesado, contains('String param1,double param2'));
      //puts nothing as methods
      expect(
          procesado, contains(RegExp(r'ClaseUno\(\);\s*}\s*class ClaseDos')));
    });
    test('Missing variable has good exception', () async {
      var vars = {
        'parent1': [
          {
            'parent2': [
              {'variable': 'sorpi'}
            ]
          },
          {'parent2': []},
        ]
      };
      var p = MustachexProcessor(variablesResolver: VariablesResolver(vars));
      var src = '{{#parent1}}{{#parent2}}'
          '{{var_paramCase}}'
          '{{/parent2}}{{/parent1}}';
      // var t = Template(src);
      // t.renderString(vars);
      // expect(() => p.process(src), throwsA(MissingNestedVariableException));
      MissingVariableException? exception;
      try {
        await p.process(src);
      } on MissingNestedVariableException catch (e) {
        exception = e.missingVariableException;
      }
      expect(exception, isNotNull);
      expect(exception!.humanReadableVariable,
          equals("['parent1'],['parent2'],['var']"));
      expect(exception.parentCollectionsWithRequest,
          equals(['parent1', 'parent2', 'var_paramCase']));
      expect(exception.parentCollectionsWithVarName,
          equals(['parent1', 'parent2', 'var']));
      expect(exception.recasing, equals('paramCase'));
      expect(exception.request, equals('var_paramCase'));
      expect(exception.varName, equals('var'));
      expect(exception.parentCollections, equals(['parent1', 'parent2']));
    });
    test('processes with symbols between', () async {
      final s = '-';
      final variables = {
        'v1': 'u${s}n${s}o',
        'v2': 'd${s}o${s}s',
      };
      var p = MustachexProcessor(initialVariables: variables);
      var src = '{{ v1 }}${s}{{ v2 }}${s}{{ v1 }}';
      final rendered = await p.process(src);
      expect(rendered, 'u${s}n${s}o${s}d${s}o${s}s${s}u${s}n${s}o');
    });
    test('processes with emojis & with different delimiters', () async {
      final variables = {
        'name': "TEST",
        'number': "1234",
      };
      var p = MustachexProcessor(initialVariables: variables);
      var src = '{{ name }} 😭 {{ number }} 😭😭';
      final renderedNormal = await p.process(src);
      src = '{{=<% %>=}}<% name %> 😭 <% number %> 😭😭';
      final renderedChanged = await p.process(src);
      expect(renderedNormal, 'TEST 😭 1234 😭😭');
      expect(renderedChanged, 'TEST 😭 1234 😭😭');
    });

    group('Binary data support', () {
      test('Uint8List variable renders exact bytes without corruption',
          () async {
        final binaryData =
            Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
        var p = MustachexProcessor(initialVariables: {'img': binaryData});
        var result = await p.processBytes('{{{img}}}');
        expect(result, equals(binaryData));
      });

      test('Mixed text and binary data renders correctly', () async {
        final binaryData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
        var p = MustachexProcessor(
            initialVariables: {'data': binaryData, 'name': 'test'});
        var result = await p.processBytes('{{name}}: {{{data}}} end');
        // "test: " in UTF-8
        final prefix = 'test: '.codeUnits;
        final suffix = ' end'.codeUnits;
        expect(result.sublist(0, prefix.length), equals(prefix));
        expect(
            result.sublist(prefix.length, prefix.length + binaryData.length),
            equals(binaryData));
        expect(result.sublist(prefix.length + binaryData.length),
            equals(suffix));
      });

      test('List<int> works the same as Uint8List', () async {
        final binaryData = <int>[0x00, 0x01, 0x02, 0xFF, 0xFE];
        var p = MustachexProcessor(initialVariables: {'raw': binaryData});
        var result = await p.processBytes('{{{raw}}}');
        expect(result, equals(binaryData));
      });

      test('processBytes with only text returns UTF-8 encoded string',
          () async {
        var p = MustachexProcessor(initialVariables: {'name': 'hello'});
        var result = await p.processBytes('{{name}} world');
        expect(result, equals('hello world'.codeUnits));
      });

      test('regular process() still works normally (backward compat)',
          () async {
        var p = MustachexProcessor(initialVariables: {'name': 'hello'});
        var result = await p.process('{{name}} world');
        expect(result, equals('hello world'));
      });
    });
  });
}
