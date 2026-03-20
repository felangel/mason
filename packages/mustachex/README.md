# MUSTACHE EXtended for Dart

The features of the unmaintained [mustache](https://pub.dev/packages/mustache) and [mustache_template](https://pub.dev/packages/mustache_template) with the addition of:

- recasing variables
- missing variables fulfillment function
- hasVarName check

Take in consideration that those package's code has been ported to this repo for maintainability reasons.

All with nested transitive variables handling

## Usage

A simple usage example:

```dart
import 'package:mustachex/mustachex.dart';

main() async {
  var template = "{{#hasFoo}} this won't be rendered {{/hasFoo}}"
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

  var processor = MustachexProcessor(
      initialVariables: vars, missingVarFulfiller: fulfillmentFunction);
  var rendered = await processor.process(template);
  assert(rendered == 'Hello World!');
}
```

## Features summary

### Variables recasing

You can recase your variables by simply adding and _\_xxxCase_ termination:

| example                | alternative  | result        |
| ---------------------- | ------------ | ------------- |
| {{ var_snakeCase }}    | {{ var_sc }} | snake_case    |
| {{ var_dotCase }}      |              | dot.case      |
| {{ var_pathCase }}     |              | path/case     |
| {{ var_paramCase }}    |              | param-case    |
| {{ var_pascalCase }}   | {{ var_pc }} | PascalCase    |
| {{ var_headerCase }}   |              | Header-Case   |
| {{ var_titleCase }}    |              | Title Case    |
| {{ var_camelCase }}    | {{ var_cc }} | camelCase     |
| {{ var_sentenceCase }} |              | Sentence case |
| {{ var_constantCase }} |              | CONSTANT_CASE |

---

### Missing variables fullfillment

the fulfillment function should be of this kind:

```dart
String foo(MissingVariableException variable) => 'new_var_value_for_${variable.varName}';
```

and supposing the source of the missing exception was the following:

```dart
var src = '{{#parent1}}{{#parent2}}'
          '{{var_paramCase}}'
          '{{/parent2}}{{/parent1}}';
```

`variable` will have all this values:

```dart

variable.recasing; // 'paramCase'
variable.request; // 'var_paramCase'
variable.varName; // 'var'
variable.parentCollections; // ['parent1', 'parent2']
variable.humanReadableVariable; // "['parent1'],['parent2'],['var']"
variable.parentCollectionsWithVarName; // ['parent1', 'parent2', 'var']
variable.parentCollectionsWithRequest; // ['parent1', 'parent2', 'var_paramCase']

```

### hasFoo guard

The mustache's sections that begins with _has_ will automatically include a variable with the same name that will contain **true** or **false** depending on the context in which it was computed.

Supposing a mustache code of:

```mustache
{{#hasFoo}}hasFoo was true{{/hasFoo}}
{{^hasFoo}}hasFoo was false{{/hasFoo}}
```

And the following JSON:

```dart
var json = {'foo': valueOfFoo}
```

| valueOfFoo | hasFoo value | rendered mustache |
| ---------- | ------------ | ----------------- |
| `null`     | false        | hasFoo was false  |
| `[]`       | false        | hasFoo was false  |
| `{}`       | false        | hasFoo was false  |
| `''`       | false        | hasFoo was false  |
| `'a'`      | true         | hasFoo was true   |
| `{'a':1}`  | true         | hasFoo was true   |
| `['a']`    | true         | hasFoo was true   |
| `false`    | true         | hasFoo was false  |
| `true`     | true         | hasFoo was true   |
