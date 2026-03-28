import 'dart:convert';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
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
        return DartRecursiveMerger();
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
    final existingJson = existingSource.isEmpty
        ? <String, dynamic>{}
        : json.decode(existingSource);
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
    final existingYaml = existingSource.isEmpty
        ? <dynamic, dynamic>{}
        : loadYaml(existingSource);
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
abstract class DartMerger extends Merger {
  Map<String, CompilationUnitMember> _getTopLevelDeclarations(
    CompilationUnit unit,
  ) {
    final declarations = <String, CompilationUnitMember>{};
    for (final declaration in unit.declarations) {
      final names = _getDeclarationNames(declaration);
      for (final name in names) {
        declarations[name] = declaration;
      }
    }
    return declarations;
  }

  List<String> _getDeclarationNames(CompilationUnitMember declaration) {
    Token? nameToken;
    if (declaration is ClassDeclaration) {
      nameToken = declaration.name;
    } else if (declaration is FunctionDeclaration) {
      nameToken = declaration.name;
    } else if (declaration is EnumDeclaration) {
      nameToken = declaration.name;
    } else if (declaration is MixinDeclaration) {
      nameToken = declaration.name;
    } else if (declaration is ExtensionDeclaration) {
      nameToken = declaration.name;
    }

    if (nameToken != null) {
      return [nameToken.lexeme];
    }

    if (declaration is TopLevelVariableDeclaration) {
      return declaration.variables.variables.map((v) => v.name.lexeme).toList();
    }
    return [];
  }

  String? _getDeclarationName(CompilationUnitMember declaration) {
    return _getDeclarationNames(declaration).firstOrNull;
  }

  String? _mergeValues(
    VariableDeclaration existing,
    VariableDeclaration incoming,
  ) {
    final existingInit = existing.initializer;
    final incomingInit = incoming.initializer;

    if (existingInit is ListLiteral && incomingInit is ListLiteral) {
      final existingElements =
          existingInit.elements.map((e) => e.toSource()).toList();
      final incomingElements =
          incomingInit.elements.map((e) => e.toSource()).toList();
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

/// {@template dart_recursive_merger}
/// A [Merger] which merges two Dart files recursively.
/// {@endtemplate}
class DartRecursiveMerger extends DartMerger {
  @override
  List<int> merge(List<int> existingContent, List<int> newContent) {
    final existingSource = utf8.decode(existingContent);
    final newSource = utf8.decode(newContent);

    final existingUnit = parseString(content: existingSource).unit;
    final newUnit = parseString(content: newSource).unit;

    final existingVariables = _getAllVariables(existingUnit);
    final existingDeclarations = _getTopLevelDeclarations(existingUnit);

    var mergedSource = existingSource;

    // Handle imports
    final brickImports = newUnit.directives.whereType<ImportDirective>();
    final targetImports =
        existingUnit.directives.whereType<ImportDirective>().toList();
    for (final brickImport in brickImports) {
      final exists = targetImports.any(
        (targetImport) =>
            targetImport.uri.toSource() == brickImport.uri.toSource(),
      );
      if (!exists) {
        mergedSource = '${brickImport.toSource()}\n$mergedSource';
      }
    }

    final handledBrickDeclarations = <CompilationUnitMember>{};

    // First, handle top-level declarations that are not variables (e.g., classes, functions)
    for (final declaration in newUnit.declarations) {
      if (declaration is! TopLevelVariableDeclaration) {
        final name = _getDeclarationName(declaration);
        if (name != null && !existingDeclarations.containsKey(name)) {
          mergedSource += '\n${declaration.toSource()}';
          handledBrickDeclarations.add(declaration);
        }
      }
    }

    // Then, handle variables
    final newVariables = _getAllVariables(newUnit);
    final newDeclarations = _getTopLevelDeclarations(newUnit);

    for (final entry in newVariables.entries) {
      final qualifiedName = entry.key;
      final newVariable = entry.value;

      if (existingVariables.containsKey(qualifiedName)) {
        final existingVariable = existingVariables[qualifiedName]!;
        final mergedValue = _mergeValues(existingVariable, newVariable);
        if (mergedValue != null) {
          final updatedUnit = parseString(content: mergedSource).unit;
          final currentVariables = _getAllVariables(updatedUnit);
          final currentVariable = currentVariables[qualifiedName]!;

          mergedSource = mergedSource.replaceRange(
            currentVariable.beginToken.offset,
            currentVariable.endToken.end,
            mergedValue,
          );
        }
      } else {
        // Only append top-level variables if they don't exist anywhere
        final variableName = qualifiedName.contains('.')
            ? qualifiedName.split('.').last
            : qualifiedName;

        if (newDeclarations.containsKey(variableName)) {
          final declaration = newDeclarations[variableName]!;
          if (!handledBrickDeclarations.contains(declaration)) {
            mergedSource += '\n${declaration.toSource()}';
            handledBrickDeclarations.add(declaration);
          }
        }
      }
    }

    return utf8.encode(mergedSource);
  }

  Map<String, VariableDeclaration> _getAllVariables(CompilationUnit unit) {
    final visitor = _VariableVisitor();
    unit.accept(visitor);
    return visitor.variables;
  }
}

class _VariableVisitor extends RecursiveAstVisitor<void> {
  final variables = <String, VariableDeclaration>{};
  String? _currentClass;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final previousClass = _currentClass;
    _currentClass = node.name.lexeme;
    super.visitClassDeclaration(node);
    _currentClass = previousClass;
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final qualifiedName = _currentClass != null
        ? '$_currentClass.${node.name.lexeme}'
        : node.name.lexeme;
    if (!variables.containsKey(qualifiedName)) {
      variables[qualifiedName] = node;
    }
    super.visitVariableDeclaration(node);
  }
}
