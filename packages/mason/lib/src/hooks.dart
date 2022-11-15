part of 'generator.dart';

/// {@template hook_dependency_install_failure}
/// Thrown when an error occurs while installing hook dependencies.
/// {@endtemplate}
class HookDependencyInstallFailure extends MasonException {
  /// {@macro hook_dependency_install_failure}
  HookDependencyInstallFailure(String path, String error)
      : super(
          '''
Unable to install dependencies for hook: $path.
Error: $error''',
        );
}

/// {@template hook_missing_run_exception}
/// Thrown when a hook does not contain a 'run' method.
/// {@endtemplate}
class HookMissingRunException extends MasonException {
  /// {@macro hook_missing_run_exception}
  HookMissingRunException(String path)
      : super(
          '''
Unable to execute hook: $path.
Error: Method 'run' not found.
Ensure the hook contains a 'run' method:

  import 'package:mason/mason.dart';

  void run(HookContext context) {...}''',
        );
}

/// {@template hook_compile_exception}
/// Thrown when an error occurs when trying to compile a hook.
/// {@endtemplate}
class HookCompileException extends MasonException {
  /// {@macro hook_compile_exception}
  HookCompileException(String path, String error)
      : super(
          '''
Unable to compile hook: $path.
Error: $error''',
        );
}

/// {@template hook_execution_exception}
/// Thrown when an error occurs during hook execution.
/// {@endtemplate}
class HookExecutionException extends MasonException {
  /// {@macro hook_execution_exception}
  HookExecutionException(String path, String error)
      : super(
          '''
An exception occurred while executing hook: $path.
Error: $error''',
        );
}

/// Supported types of [GeneratorHooks].
enum GeneratorHook {
  /// Hook run immediately before the `generate` method is invoked.
  preGen,

  /// Hook run immediately after the `generate` method is invoked.
  postGen,
}

/// Extension on [GeneratorHook] for converting
/// a [GeneratorHook] to the corresponding file name.
extension GeneratorHookToFileName on GeneratorHook {
  /// Converts a [GeneratorHook] to the corresponding file name.
  String toFileName() {
    switch (this) {
      case GeneratorHook.preGen:
        return 'pre_gen.dart';
      case GeneratorHook.postGen:
        return 'post_gen.dart';
    }
  }
}

/// {@template generator_hooks}
/// Scripts that run automatically whenever a particular event occurs
/// in a [Generator].
/// {@endtemplate}
class GeneratorHooks {
  /// {@macro generator_hooks}
  const GeneratorHooks({this.preGenHook, this.postGenHook, this.pubspec});

  /// Creates [GeneratorHooks] from a provided [MasonBundle].
  factory GeneratorHooks.fromBundle(MasonBundle bundle) {
    HookFile? _decodeHookFile(MasonBundledFile? file) {
      if (file == null) return null;
      final path = file.path;
      final raw = file.data.replaceAll(_whiteSpace, '');
      final decoded = base64.decode(raw);
      try {
        return HookFile.fromBytes(path, decoded);
      } catch (_) {
        return null;
      }
    }

    List<int>? _decodeHookPubspec(MasonBundledFile? file) {
      if (file == null) return null;
      final raw = file.data.replaceAll(_whiteSpace, '');
      return base64.decode(raw);
    }

    final preGen = bundle.hooks.firstWhereOrNull(
      (element) {
        return p.basename(element.path) == GeneratorHook.preGen.toFileName();
      },
    );
    final postGen = bundle.hooks.firstWhereOrNull(
      (element) {
        return p.basename(element.path) == GeneratorHook.postGen.toFileName();
      },
    );
    final pubspec = bundle.hooks.firstWhereOrNull(
      (element) {
        return p.basename(element.path) == 'pubspec.yaml';
      },
    );

    return GeneratorHooks(
      preGenHook: _decodeHookFile(preGen),
      postGenHook: _decodeHookFile(postGen),
      pubspec: _decodeHookPubspec(pubspec),
    );
  }

  /// Creates [GeneratorHooks] from a provided [BrickYaml].
  static Future<GeneratorHooks> fromBrickYaml(BrickYaml brick) async {
    Future<HookFile?> getHookFile(GeneratorHook hook) async {
      try {
        final brickRoot = File(brick.path!).parent.path;
        final hooksDirectory = Directory(p.join(brickRoot, BrickYaml.hooks));
        final file =
            hooksDirectory.listSync().whereType<File>().firstWhereOrNull(
                  (element) => p.basename(element.path) == hook.toFileName(),
                );

        if (file == null) return null;
        final content = await file.readAsBytes();
        return HookFile.fromBytes(file.path, content);
      } catch (_) {
        return null;
      }
    }

    Future<List<int>?> getHookPubspec() async {
      try {
        final brickRoot = File(brick.path!).parent.path;
        final hooksDirectory = Directory(p.join(brickRoot, BrickYaml.hooks));
        final file =
            hooksDirectory.listSync().whereType<File>().firstWhereOrNull(
                  (element) => p.basename(element.path) == 'pubspec.yaml',
                );

        if (file == null) return null;
        return await file.readAsBytes();
      } catch (_) {
        return null;
      }
    }

    return GeneratorHooks(
      preGenHook: await getHookFile(GeneratorHook.preGen),
      postGenHook: await getHookFile(GeneratorHook.postGen),
      pubspec: await getHookPubspec(),
    );
  }

  /// Hook run immediately before the `generate` method is invoked.
  final HookFile? preGenHook;

  /// Hook run immediately after the `generate` method is invoked.
  final HookFile? postGenHook;

  /// Contents of the hooks `pubspec.yaml` if exists.
  final List<int>? pubspec;

  /// Runs the pre-generation (pre_gen) hook with the specified [vars].
  /// An optional [workingDirectory] can also be specified.
  Future<void> preGen({
    Map<String, dynamic> vars = const <String, dynamic>{},
    String? workingDirectory,
    void Function(Map<String, dynamic> vars)? onVarsChanged,
    Logger? logger,
  }) async {
    final preGenHook = this.preGenHook;
    if (preGenHook != null && pubspec != null) {
      return _runHook(
        hook: preGenHook,
        vars: vars,
        workingDirectory: workingDirectory,
        onVarsChanged: onVarsChanged,
        logger: logger,
      );
    }
  }

  /// Runs the post-generation (post_gen) hook with the specified [vars].
  /// An optional [workingDirectory] can also be specified.
  Future<void> postGen({
    Map<String, dynamic> vars = const <String, dynamic>{},
    String? workingDirectory,
    void Function(Map<String, dynamic> vars)? onVarsChanged,
    Logger? logger,
  }) async {
    final postGenHook = this.postGenHook;
    if (postGenHook != null && pubspec != null) {
      return _runHook(
        hook: postGenHook,
        vars: vars,
        workingDirectory: workingDirectory,
        onVarsChanged: onVarsChanged,
        logger: logger,
      );
    }
  }

  /// Compile all hooks into modules for faster execution.
  /// Hooks are compiled lazily by default but calling [compile]
  /// can be used to compile hooks ahead of time.
  Future<void> compile({Logger? logger}) async {
    await _installDependencies();

    if (preGenHook != null && !preGenHook!.module.existsSync()) {
      await _compile(hook: preGenHook!, logger: logger);
    }

    if (postGenHook != null && !postGenHook!.module.existsSync()) {
      await _compile(hook: postGenHook!, logger: logger);
    }
  }

  Future<void> _dartPubGet({required String workingDirectory}) async {
    final result = await Process.run(
      'dart',
      ['pub', 'get'],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    if (result.exitCode != ExitCode.success.code) {
      throw HookDependencyInstallFailure(
        workingDirectory,
        '${result.stderr}',
      );
    }
  }

  Future<void> _installDependencies() async {
    final hook = preGenHook ?? postGenHook;
    if (hook == null) return;

    final hookCacheDir = hook.cacheDirectory;
    final pubspec = this.pubspec;

    if (pubspec != null) {
      final packageConfigFile = File(
        p.join(hookCacheDir.path, '.dart_tool', 'package_config.json'),
      );

      if (!packageConfigFile.existsSync()) {
        await hookCacheDir.create(recursive: true);
        await File(
          p.join(hookCacheDir.path, 'pubspec.yaml'),
        ).writeAsBytes(pubspec);
        await _dartPubGet(workingDirectory: hookCacheDir.path);
      }
    }
  }

  Future<void> _compile({required HookFile hook, Logger? logger}) async {
    final uri = await _getHookUri(hook);

    if (uri == null) throw HookMissingRunException(hook.path);

    final progress = logger?.progress('Compiling ${p.basename(hook.path)}');
    final result = await Process.run(
      'dart',
      ['compile', 'kernel', uri.path],
      workingDirectory: hook.cacheDirectory.path,
      runInShell: true,
    );

    if (result.exitCode != ExitCode.success.code) {
      final error = result.stderr.toString();
      progress?.fail(error);
      throw HookCompileException(hook.path, error);
    }

    progress?.complete('Compiled ${p.basename(hook.path)}');
  }

  /// Runs the provided [hook] with the specified [vars].
  /// An optional [workingDirectory] can also be specified.
  Future<void> _runHook({
    required HookFile hook,
    Map<String, dynamic> vars = const <String, dynamic>{},
    void Function(Map<String, dynamic> vars)? onVarsChanged,
    String? workingDirectory,
    Logger? logger,
  }) async {
    final subscriptions = <StreamSubscription>[];
    final messagePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();

    dynamic hookError;
    subscriptions.add(errorPort.listen((dynamic error) => hookError = error));

    if (onVarsChanged != null) {
      subscriptions.add(
        messagePort.listen((dynamic message) {
          if (message is String) {
            onVarsChanged(
              json.decode(message) as Map<String, dynamic>,
            );
          }
        }),
      );
    }

    await _installDependencies();
    final hookCacheDir = hook.cacheDirectory;
    final packageConfigUri = File(
      p.join(hookCacheDir.path, '.dart_tool', 'package_config.json'),
    ).uri;
    final module = hook.module;

    if (!module.existsSync()) {
      await _compile(hook: hook, logger: logger);
    }

    Future<Isolate> spawnIsolate(Uri uri) {
      return Isolate.spawnUri(
        uri,
        [json.encode(vars)],
        messagePort.sendPort,
        paused: true,
        packageConfig: packageConfigUri,
      );
    }

    final cwd = Directory.current;
    if (workingDirectory != null) Directory.current = workingDirectory;

    final isolate = await spawnIsolate(module.uri);

    isolate
      ..addErrorListener(errorPort.sendPort)
      ..addOnExitListener(exitPort.sendPort)
      ..resume(isolate.pauseCapability!);

    try {
      await exitPort.first;
    } finally {
      Directory.current = cwd;
    }

    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }

    if (hookError != null) {
      final dynamic error = hookError;
      final content =
          error is List && error.isNotEmpty ? '${error.first}' : '$error';
      throw HookExecutionException(hook.path, content);
    }
  }
}

/// {@template hook_file}
/// This class represents a hook file in a generator.
/// The contents should be text and may contain mustache.
/// {@endtemplate}
class HookFile {
  /// {@macro hook_file}
  HookFile.fromBytes(this.path, this.content);

  /// The template file path.
  final String path;

  /// The template file content.
  final List<int> content;
}

/// A reference to core mason APIs to be used within hooks.
///
/// Each hook is defined as a `run` method which accepts a
/// [HookContext] instance.
///
/// [HookContext] exposes APIs to:
/// * read/write template vars
/// * access a [Logger] instance
///
/// ```dart
/// // pre_gen.dart
/// import 'package:mason/mason.dart';
///
/// void run(HookContext context) {
///   // Read/Write vars
///   context.vars = {...context.vars, 'custom_var': 'foo'};
///
///   // Use the logger
///   context.logger.info('hello from pre_gen.dart');
/// }
/// ```
abstract class HookContext {
  /// Getter that returns the current map of variables.
  Map<String, dynamic> get vars;

  /// Setter that enables updating the current map of variables.
  set vars(Map<String, dynamic> value);

  /// Getter that returns a [Logger] instance.
  Logger get logger;
}

final _runRegExp = RegExp(
  r'((void||Future<void>)\srun\(HookContext)',
  multiLine: true,
);

Future<Uri?> _getHookUri(HookFile hook) async {
  final decoded = utf8.decode(hook.content);
  if (!_runRegExp.hasMatch(decoded)) return null;

  final hookBuildDir = hook.buildDirectory;

  try {
    await hookBuildDir.delete(recursive: true);
  } catch (_) {}

  copyPathSync(File(hook.path).parent.path, hookBuildDir.path);
  final hookFile = File(p.join(hookBuildDir.path, '.${hook.fileHash}.dart'))
    ..createSync(recursive: true)
    ..writeAsStringSync(_generatedHookCode(decoded));

  return Uri.file(hookFile.path);
}

String _generatedHookCode(String content) => '''
// GENERATED CODE - DO NOT MODIFY BY HAND
import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';

$content

void main(List<String> args, SendPort port) {
  run(_HookContext._(port, vars: json.decode(args.first)));
}

class _HookContext implements HookContext {
  _HookContext._(this._port, {Map<String, dynamic>? vars})
      : _vars = _Vars(_port, vars: vars);

  final SendPort _port;
  _Vars _vars;

  @override
  Map<String, dynamic> get vars => _vars;

  @override
  final logger = Logger();

  @override
  set vars(Map<String, dynamic> value) {
    _vars = _Vars(_port, vars: value);
    _port.send(json.encode(_vars));
  }
}

class _Vars with MapMixin<String, dynamic> {
  const _Vars(
    this._port, {
    Map<String, dynamic>? vars,
  }) : _vars = vars ?? const <String, dynamic>{};

  final SendPort _port;
  final Map<String, dynamic> _vars;

  @override
  dynamic operator [](Object? key) => _vars[key];

  @override
  void operator []=(String key, dynamic value) {
    _vars[key] = value;
    _updateVars();
  }

  @override
  void clear() {
    _vars.clear();
    _updateVars();
  }

  @override
  Iterable<String> get keys => _vars.keys;

  @override
  dynamic remove(Object? key) {
    final dynamic result = _vars.remove(key);
    _updateVars();
    return result;
  }

  void _updateVars() => _port.send(json.encode(_vars));
}
''';
