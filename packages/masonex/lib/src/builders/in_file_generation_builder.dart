import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:mason/mason.dart';
import 'package:masonex_annotations/masonex_annotations.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as p;

class InFileGenerationBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$lib$': ['brick.yaml']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inFileGenerations = <String, Map<String, String>>{};
    final annotationCheckers = [
      TypeChecker.fromRuntime(GenerateBefore),
      TypeChecker.fromRuntime(GenerateAfter),
      TypeChecker.fromRuntime(GenerationMerge),
    ];

    final assets = buildStep.findAssets(Glob('**/*.dart'));
    await for (final asset in assets) {
      final content = await buildStep.readAsString(asset);
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('@GenerateBefore') ||
            line.contains('@GenerateAfter') ||
            line.contains('@GenerationMerge')) {
          final idMatch = RegExp(r"\((['\x22])(.+?)\1\)").firstMatch(line);
          if (idMatch != null) {
            final id = idMatch.group(2)!;
            final templateLine = line.substring(line.indexOf(':') + 1).trim();
            if (templateLine.isNotEmpty) {
              inFileGenerations[asset.path] ??= {};
              inFileGenerations[asset.path]![id] = templateLine;
            }
          }
        }
      }
    }

    if (inFileGenerations.isNotEmpty) {
      final brickYamlAsset = AssetId(buildStep.inputId.package, 'brick.yaml');
      if (await buildStep.canRead(brickYamlAsset)) {
        final content = await buildStep.readAsString(brickYamlAsset);
        // Assuming brick.yaml is YAML, but BrickYaml.fromJson handles it
        // We use a simple YAML modification to preserve other fields if possible,
        // or just re-serialize if that's acceptable.
        final brickYaml = BrickYaml.fromJson(loadYaml(content) as Map);
        final updatedBrickYaml = brickYaml.copyWith(
          inFileGenerations: {
            ...brickYaml.inFileGenerations,
            ...inFileGenerations,
          },
        );

        await buildStep.writeAsString(
          brickYamlAsset,
          Yaml.encode(updatedBrickYaml.toJson()),
        );
      }
    }
  }
}
