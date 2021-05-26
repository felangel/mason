import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:path/path.dart' as p;

import 'brick_yaml.dart';
import 'exception.dart';
import 'logger.dart';
import 'mason_cache.dart';
import 'mason_yaml.dart';

/// {@template brick_not_found_exception}
/// Thrown when a brick registered in the `mason.yaml` cannot be found locally.
/// {@endtemplate}
class BrickNotFoundException extends MasonException {
  /// {@macro brick_not_found_exception}
  const BrickNotFoundException(String path)
      : super('Could not find brick at $path');
}

/// {@template mason_yaml_name_mismatch}
/// Thrown when a brick's name in `mason.yaml` does not match
/// the name in `brick.yaml`.
/// {@endtemplate}
class MasonYamlNameMismatch extends MasonException {
  /// {@macro mason_yaml_name_mismatch}
  MasonYamlNameMismatch(String message) : super(message);
}

/// {@template mason_yaml_parse_exception}
/// Thrown when a `mason.yaml` cannot be parsed.
/// {@endtemplate}
class MasonYamlParseException extends MasonException {
  /// {@macro mason_yaml_parse_exception}
  const MasonYamlParseException(String message) : super(message);
}

/// {@template brick_yaml_parse_exception}
/// Thrown when a `brick.yaml` cannot be parsed.
/// {@endtemplate}
class BrickYamlParseException extends MasonException {
  /// {@macro brick_yaml_parse_exception}
  const BrickYamlParseException(String message) : super(message);
}

/// {@template mason_command}
/// The base class for all mason executable commands.
/// {@endtemplate}
abstract class MasonCommand extends Command<int> {
  /// {@macro mason_command}
  MasonCommand({Logger? logger}) : _logger = logger;

  /// [MasonCache] which contains all remote brick templates.
  MasonCache get cache => _cache ??= MasonCache(bricksJson);

  MasonCache? _cache;

  Directory get _globalDirectory => Directory(masonCacheGlobalDir());

  /// Gets the directory containing the nearest `mason.yaml`.
  Directory get entryPoint {
    if (_entryPoint != null) return _entryPoint!;
    final nearestMasonYaml = MasonYaml.findNearest(cwd);
    if (nearestMasonYaml == null) {
      return _entryPoint = _globalDirectory..createSync(recursive: true);
    }
    return _entryPoint = nearestMasonYaml.parent;
  }

  /// [ArgResults] for the current command.
  ArgResults get results => argResults!;

  Directory? _entryPoint;

  /// Gets the `bricks.json` file for the current [entryPoint].
  File get bricksJson => File(p.join(entryPoint.path, '.mason', 'bricks.json'));

  /// Writes current cache to `brick.json`.
  Future<void> writeCacheToBricksJson() async {
    await bricksJson.create(recursive: true);
    await bricksJson.writeAsString(cache.encode);
  }

  /// Caches brick (remote or local).
  /// Remote bricks will be downloaded and the cached.
  Future<void> cacheBrick(Brick brick) async {
    if (brick.path != null && (cache.read(brick.path!) == null)) {
      return cache.write(
        brick.path!,
        File(p.normalize(p.join(entryPoint.path, brick.path))).absolute.path,
      );
    }
    if (brick.git != null && (cache.read(brick.git!.url) == null)) {
      await cache.downloadRemoteBrick(brick.git!);
    }
  }

  /// Gets all [BrickYaml] contents for bricks registered in the `mason.yaml`.
  Set<BrickYaml> bricks([MasonYaml? yaml]) {
    if (yaml == null && _bricks != null) return _bricks!;
    final masonYaml = yaml ?? this.masonYaml();
    final localBricks = _getBricks(masonYaml);
    final bricks = <BrickYaml>{...localBricks};
    if (masonInitializedLocally) {
      final globalBricks = _getBricks(
        this.masonYaml(masonYamlFile(_globalDirectory)),
      );
      bricks.addAll(globalBricks);
    }
    _bricks = bricks;
    return bricks;
  }

  Set<BrickYaml>? _bricks;

  /// Returns `true` if a `mason.yaml` file exists locally.
  /// This excludes the global mason configuration.
  bool get masonInitializedLocally {
    try {
      final file = masonYamlFile();
      return p.isWithin(cwd.path, file.path);
    } catch (_) {
      return false;
    }
  }

  /// Gets the nearest `mason.yaml` file.
  File masonYamlFile([Directory? entry]) {
    if (entry == null && _masonYamlFile != null) return _masonYamlFile!;
    final entryPoint = entry ?? this.entryPoint;
    final file = File(p.join(entryPoint.path, MasonYaml.file));
    if (!file.existsSync()) {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(json.encode(MasonYaml.empty.toJson()));
    }
    _masonYamlFile = file;
    return file;
  }

  File? _masonYamlFile;

  /// Gets the nearest [MasonYaml].
  MasonYaml masonYaml([File? yamlFile]) {
    if (yamlFile == null && _masonYaml != null) return _masonYaml!;
    final masonYamlFile = yamlFile ?? this.masonYamlFile();
    final masonYamlContent = masonYamlFile.readAsStringSync();
    try {
      return _masonYaml = checkedYamlDecode(
        masonYamlContent,
        (m) => MasonYaml.fromJson(m!),
      )!;
    } on ParsedYamlException catch (e) {
      throw MasonYamlParseException(
        'Malformed ${MasonYaml.file} at ${masonYamlFile.path}\n${e.message}',
      );
    }
  }

  MasonYaml? _masonYaml;

  /// [Logger] instance used to wrap stdout.
  Logger get logger => _logger ??= Logger();

  Logger? _logger;

  /// Return the current working directory.
  Directory get cwd => _cwd ??= Directory.current;

  /// An override for the directory to generate into; public for testing.
  set cwd(Directory value) => _cwd = value;

  Directory? _cwd;

  Set<BrickYaml> _getBricks(MasonYaml masonYaml) {
    final bricks = <BrickYaml>{};
    for (final entry in masonYaml.bricks.entries) {
      final brick = entry.value;
      final dirPath = cache.read(brick.path ?? brick.git!.url);
      if (dirPath == null) break;
      final filePath = brick.path != null
          ? p.join(dirPath, BrickYaml.file)
          : p.join(dirPath, brick.git?.path ?? '', BrickYaml.file);
      final file = File(filePath);
      if (!file.existsSync()) throw BrickNotFoundException(filePath);
      try {
        final brickYaml = checkedYamlDecode(
          file.readAsStringSync(),
          (m) => BrickYaml.fromJson(m!),
        ).copyWith(path: filePath);
        if (brickYaml.name != entry.key) {
          throw MasonYamlNameMismatch(
            'brick name "${brickYaml.name}": '
            'doesn\'t match provided name "${entry.key}" in ${MasonYaml.file}.',
          );
        }
        bricks.add(brickYaml);
      } on ParsedYamlException catch (e) {
        throw BrickYamlParseException(
          'Malformed ${BrickYaml.file} at ${file.path}\n${e.message}',
        );
      }
    }
    return bricks;
  }
}
