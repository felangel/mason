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
  const GeneratorHooks({
    this.preGenHook,
    this.postGenHook,
    this.pubspec,
    this.checksum = '',
  });

  /// Creates [GeneratorHooks] from a provided [BrickYaml].
  static Future<GeneratorHooks> fromBrickYaml(BrickYaml brick) async {
    HookFile? preGenHook;
    HookFile? postGenHook;
    List<int>? pubspec;

    final accumulator = AccumulatorSink<Digest>();
    final sink = sha1.startChunkedConversion(accumulator);

    try {
      final brickRoot = File(brick.path!).parent.path;
      final hooksDirectory = Directory(p.join(brickRoot, BrickYaml.hooks));
      final pubspecFilePath = p.join(hooksDirectory.path, 'pubspec.yaml');
      final preGenFilePath = p.join(
        hooksDirectory.path,
        GeneratorHook.preGen.toFileName(),
      );
      final postGenFilePath = p.join(
        hooksDirectory.path,
        GeneratorHook.postGen.toFileName(),
      );
      final dartFiles = hooksDirectory.existsSync()
          ? hooksDirectory
              .listSync(recursive: true)
              .where(_isHookFile)
              .cast<File>()
          : const <File>[];

      for (final file in dartFiles) {
        final bytes = await file.readAsBytes();
        sink.add(bytes);
        if (file.path == pubspecFilePath) {
          pubspec ??= bytes;
        } else if (file.path == preGenFilePath) {
          preGenHook ??= HookFile.fromBytes(file.path, bytes);
        } else if (file.path == postGenFilePath) {
          postGenHook ??= HookFile.fromBytes(file.path, bytes);
        }
      }
    } finally {
      sink.close();
    }

    return GeneratorHooks(
      preGenHook: preGenHook,
      postGenHook: postGenHook,
      pubspec: pubspec,
      checksum: accumulator.events.firstOrNull?.toString() ?? '',
    );
  }

  /// Hook run immediately before the `generate` method is invoked.
  final HookFile? preGenHook;

  /// Hook run immediately after the `generate` method is invoked.
  final HookFile? postGenHook;

  /// Contents of the hooks `pubspec.yaml` if exists.
  final List<int>? pubspec;

  /// The hash of the hooks directory and its contents.
  final String checksum;

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

    if (preGenHook != null && !preGenHook!.module(checksum).existsSync()) {
      await _compile(hook: preGenHook!, logger: logger);
    }

    if (postGenHook != null && !postGenHook!.module(checksum).existsSync()) {
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

  Future<bool> _installDependencies() async {
    final hook = preGenHook ?? postGenHook;
    var installedDependencies = false;
    if (hook == null) return installedDependencies;

    final hookDirectory = hook.directory;
    final pubspec = this.pubspec;

    if (pubspec != null) {
      final packageConfigFile = File(
        p.join(hookDirectory.path, '.dart_tool', 'package_config.json'),
      );

      if (!packageConfigFile.existsSync()) {
        await _dartPubGet(workingDirectory: hookDirectory.path);
        installedDependencies = true;
      }
    }
    return installedDependencies;
  }

  Future<void> _compile({required HookFile hook, Logger? logger}) async {
    final uri = await _getHookUri(hook, checksum);

    if (uri == null) throw HookMissingRunException(hook.path);

    final progress = logger?.progress('Compiling ${p.basename(hook.path)}');
    final result = await Process.run(
      'dart',
      ['compile', 'kernel', uri.toFilePath()],
      runInShell: true,
    );

    File(uri.toFilePath()).delete().ignore();

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

    var installedDependencies = false;
    var compiledHook = false;
    final module = hook.module(checksum);
    if (!module.existsSync()) {
      installedDependencies = await _installDependencies();
      await _compile(hook: hook, logger: logger);
      compiledHook = true;
    }

    Future<Isolate> spawnIsolate(Uri uri) {
      return Isolate.spawnUri(
        uri,
        [json.encode(vars)],
        messagePort.sendPort,
        paused: true,
      );
    }

    final uri = module.uri.hasAbsolutePath
        ? module.uri
        : Uri.file(canonicalize(module.uri.path));
    final cwd = Directory.current.path;
    if (workingDirectory != null) Directory.current = workingDirectory;

    Isolate? isolate;
    try {
      isolate = await spawnIsolate(uri);
    } on IsolateSpawnException catch (error) {
      Never throwHookExecutionException(IsolateSpawnException error) {
        Directory.current = cwd;
        final msg = error.message;
        final content =
            msg.contains('Error: ') ? msg.split('Error: ').last : msg;
        throw HookExecutionException(hook.path, content.trim());
      }

      final shouldRetry = !installedDependencies || !compiledHook;

      // If we just installed dependencies and compiled the hook,
      // then there is no reason to retry.
      if (!shouldRetry) throwHookExecutionException(error);

      Directory.current = cwd;

      // Failure to spawn the isolate could be due to changes in the pub cache.
      // We attempt to reinstall hook dependencies.
      await _dartPubGet(workingDirectory: hook.directory.path);

      // Failure to spawn the isolate could be due to changes in the Dart SDK.
      // We attempt to recompile the hook.
      await _compile(hook: hook, logger: logger);

      if (workingDirectory != null) Directory.current = workingDirectory;

      // Retry spawning the isolate if the hook
      // has been successfully recompiled.
      try {
        isolate = await spawnIsolate(uri);
      } on IsolateSpawnException catch (error) {
        throwHookExecutionException(error);
      }
    }

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

    messagePort.close();
    errorPort.close();
    exitPort.close();

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

Future<Uri?> _getHookUri(HookFile hook, String checksum) async {
  final decoded = utf8.decode(hook.content);
  if (!_runRegExp.hasMatch(decoded)) return null;

  try {
    await hook.buildDirectory.delete(recursive: true);
  } catch (_) {}

  final intermediate = hook.intermediate(checksum)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      _generatedHookCode('../../../${p.basename(hook.path)}'),
    );

  return Uri.file(intermediate.path);
}

String _generatedHookCode(String hookPath) => '''
// GENERATED CODE - DO NOT MODIFY BY HAND
import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';
import 'package:mason/mason.dart';
import '$hookPath' as hook;

void main(List<String> args, SendPort port) {
  hook.run(_HookContext._(port, vars: json.decode(args.first)));
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

bool _isHookFile(FileSystemEntity entity) {
  final isFile = entity is File;
  if (!isFile) return false;
  final ext = p.extension(entity.path);
  return ext == '.dart' || ext == '.yaml';
}
