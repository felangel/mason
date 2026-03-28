import 'dart:convert';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:mason/src/yaml_encode.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// {@template merger}
/// A class which helps merge two files.
/// {@endtemplate}
abstract class Merger {
  /// Merges the [newContent] with the [existingContent].
  List<int> merge(List<int> existingContent, List<int> newContent);

  /// Returns a [Merger] based on the [path].
  static Merger fromPath(String path) {
    final extension = p.extension(path);
    switch (extension) {
      case '.dart':
        return DartMerger();
      case '.json':
        return JsonMerger();
      case '.yaml':
      case '.yml':
        return YamlMerger();
      default:
        return AppendMerger();
    }
  }
}

/// {@template append_merger}
/// A [Merger] which appends the new content to the existing content.
/// {@endtemplate}
class AppendMerger extends Merger {
  @override
  List<int> merge(List<int> existingContent, List<int> newContent) {
    return [...existingContent, ...newContent];
  }
}

/// {@template json_merger}
/// A [Merger] which merges two JSON files.
/// {@endtemplate}
class JsonMerger extends Merger {
  @override
  List<int> merge(List<int> existingContent, List<int> newContent) {
    final existingSource = utf8.decode(existingContent);
    final existingJson =
        existingSource.isEmpty ? <String, dynamic>{} : json.decode(existingSource);
    final newJson = json.decode(utf8.decode(newContent));

    final mergedJson = _merge(existingJson, newJson);
    return utf8.encode(json.encode(mergedJson));
  }

  dynamic _merge(dynamic existing, dynamic incoming) {
    if (existing is Map && incoming is Map) {
      final merged = Map<String, dynamic>.from(existing);
      for (final key in incoming.keys) {
        merged[key] = _merge(existing[key], incoming[key]);
      }
      return merged;
    }
    if (existing is List && incoming is List) {
      return [...existing, ...incoming];
    }
    return incoming;
  }
}

/// {@template yaml_merger}
/// A [Merger] which merges two YAML files.
/// {@endtemplate}
class YamlMerger extends Merger {
  @override
  List<int> merge(List<int> existingContent, List<int> newContent) {
    final existingSource = utf8.decode(existingContent);
    final existingYaml =
        existingSource.isEmpty ? <dynamic, dynamic>{} : loadYaml(existingSource);
    final newYaml = loadYaml(utf8.decode(newContent));

    final mergedYaml = _merge(existingYaml, newYaml);
    if (mergedYaml is Map) {
      return utf8.encode(Yaml.encode(mergedYaml.cast<dynamic, dynamic>()));
    }
    // For non-map YAMLs, we use the simple conversion
    return utf8.encode(_toYamlString(mergedYaml));
  }

  dynamic _merge(dynamic existing, dynamic incoming) {
    if (existing is Map && incoming is Map) {
      final merged = Map<dynamic, dynamic>.from(existing);
      for (final key in incoming.keys) {
        merged[key] = _merge(existing[key], incoming[key]);
      }
      return merged;
    }
    if (existing is List && incoming is List) {
      return [...existing, ...incoming];
    }
    return incoming;
  }

  String _toYamlString(dynamic value, [int indent = 0]) {
    final spaces = '  ' * indent;
    if (value is Map) {
      return value.entries.map((e) {
        final val = _toYamlString(e.value, indent + 1);
        return '$spaces${e.key}:${val.startsWith('\n') ? val : ' $val'}';
      }).join('\n');
    }
    if (value is List) {
      if (value.isEmpty) return ' []';
      return '\n' +
          value.map((e) {
            final val = _toYamlString(e, indent + 1);
            return '$spaces- ${val.trimLeft()}';
          }).join('\n');
    }
    if (value is String) {
      if (value.contains('\n')) {
        return ' |\n' +
            value.split('\n').map((line) => '$spaces  $line').join('\n');
      }
      return value;
    }
    return '$value';
  }
}

/// {@template dart_merger}
/// A [Merger] which merges two Dart files.
/// {@endtemplate}
class DartMerger extends Merger {
  @override
  List<int> merge(List<int> existingContent, List<int> newContent) {
    final existingSource = utf8.decode(existingContent);
    final newSource = utf8.decode(newContent);

    final existingUnit = parseString(content: existingSource).unit;
    final newUnit = parseString(content: newSource).unit;

    final existingVariables = _getTopLevelVariables(existingUnit);
    final newDeclarations = _getTopLevelDeclarations(newUnit);

    var mergedSource = existingSource;

    for (final entry in newDeclarations.entries) {
      final name = entry.key;
      final newDeclaration = entry.value;
      final newVariable = newDeclaration.variables.variables
          .firstWhere((v) => v.name.lexeme == name);

      if (existingVariables.containsKey(name)) {
        final existingVariable = existingVariables[name]!;
        final mergedValue = _mergeValues(existingVariable, newVariable);
        if (mergedValue != null) {
          mergedSource = mergedSource.replaceRange(
            existingVariable.beginToken.offset,
            existingVariable.endToken.end,
            mergedValue,
          );
          // Re-parse to update offsets for subsequent replacements
          final updatedUnit = parseString(content: mergedSource).unit;
          existingVariables.clear();
          existingVariables.addAll(_getTopLevelVariables(updatedUnit));
        }
      } else {
        // Variable doesn't exist in existing file, append the entire declaration
        mergedSource += '\n${newDeclaration.toSource()}';
      }
    }

    return utf8.encode(mergedSource);
  }

  Map<String, VariableDeclaration> _getTopLevelVariables(CompilationUnit unit) {
    final variables = <String, VariableDeclaration>{};
    for (final declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (final variable in declaration.variables.variables) {
          variables[variable.name.lexeme] = variable;
        }
      }
    }
    return variables;
  }

  Map<String, TopLevelVariableDeclaration> _getTopLevelDeclarations(
    CompilationUnit unit,
  ) {
    final declarations = <String, TopLevelVariableDeclaration>{};
    for (final declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (final variable in declaration.variables.variables) {
          declarations[variable.name.lexeme] = declaration;
        }
      }
    }
    return declarations;
  }

  String? _mergeValues(VariableDeclaration existing, VariableDeclaration incoming) {
    final existingInit = existing.initializer;
    final incomingInit = incoming.initializer;

    if (existingInit is ListLiteral && incomingInit is ListLiteral) {
      final existingElements = existingInit.elements.map((e) => e.toSource()).toList();
      final incomingElements = incomingInit.elements.map((e) => e.toSource()).toList();
      final mergedElements = [...existingElements, ...incomingElements];
      return '${existing.name.lexeme} = [${mergedElements.join(', ')}]';
    }

    if (existingInit is SetOrMapLiteral && incomingInit is SetOrMapLiteral) {
      if (existingInit.isSet && incomingInit.isSet) {
        final existingElements =
            existingInit.elements.map((e) => e.toSource()).toSet();
        final incomingElements =
            incomingInit.elements.map((e) => e.toSource()).toSet();
        final mergedElements = {...existingElements, ...incomingElements};
        return '${existing.name.lexeme} = {${mergedElements.join(', ')}}';
      }
      if (!existingInit.isSet && !incomingInit.isSet) {
        final existingElements = {
          for (final e in existingInit.elements.whereType<MapLiteralEntry>())
            e.key.toSource(): e.value.toSource(),
        };
        final incomingElements = {
          for (final e in incomingInit.elements.whereType<MapLiteralEntry>())
            e.key.toSource(): e.value.toSource(),
        };
        final mergedElements = {...existingElements, ...incomingElements};
        final mergedSource = mergedElements.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
        return '${existing.name.lexeme} = {$mergedSource}';
      }
    }

    // If types don't match or aren't iterable, we might want to throw or handle differently.
    // Based on requirements, mismatch should throw error.
    throw Exception(
      'Cannot merge variables with name "${existing.name.lexeme}" because their types mismatch or are not supported for merging.',
    );
  }
}
