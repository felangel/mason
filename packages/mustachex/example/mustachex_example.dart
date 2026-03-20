import 'package:mustachex/mustachex.dart';

main() async {
  var template = '{{greeting_pascalCase}} {{world_pc}}!';
  var vars = {'greeting': 'HELLO'};
  String fulfillmentFunction(MissingVariableException variable) {
    if (variable.varName == 'world') {
      return 'WORLD';
    } else {
      return 'UNIVERSE';
    }
  }

  var processor = MustachexProcessor(
      initialVariables: vars, missingVarFulfiller: fulfillmentFunction);
  var rendered = await processor.process(template);
  assert(rendered == 'Hello World!');
  print(rendered);
  var classesJSON = {
    'classes': [
      {
        'name': 'claseUno',
        'fields': [
          {'name': 'field1', 'type': 'String', 'final': true},
          {'name': 'Field2', 'type': 'int'},
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
  template = '''
{{#classes}}
class {{name_pc}} {
  {{#fields}}
  {{#hasDocs}}///{{docs}}{{/hasDocs}}
  {{#hasFinal}}final {{/hasFinal}}{{type}} {{name_cc}};
  {{/fields}}

  {{name_pc}}();

  {{#methods}}
  {{returnType_pc}} {{name_cc}}({{#hasParameters}}{{#parameters}}{{type}} {{name}},{{/parameters}}{{/hasParameters}}){}
  {{/methods}}
}
{{/classes}}
''';
  processor = MustachexProcessor(initialVariables: classesJSON);
  rendered = await processor.process(template);
  print(rendered);
}
