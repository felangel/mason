part of 'generator.dart';

/// File conflict resolution strategies used during
/// the generation process.
enum FileConflictResolution {
  /// Always prompt the user for each file conflict.
  prompt,

  /// Always overwrite conflicting files.
  overwrite,

  /// Always skip conflicting files.
  skip,

  /// Always append conflicting files.
  append,
}

/// The overwrite rule when generating code and a conflict occurs.
enum OverwriteRule {
  /// Always overwrite the existing file.
  alwaysOverwrite,

  /// Always skip overwriting the existing file.
  alwaysSkip,

  /// Always append the existing file.
  alwaysAppend,

  /// Overwrite one time.
  overwriteOnce,

  /// Do not overwrite one time.
  skipOnce,

  /// Append one time
  appendOnce,
}

/// Extension on [FileConflictResolution] that enables converting to
/// an [OverwriteRule].
extension FileConflictResolutionToOverwriteRule on FileConflictResolution {
  /// Converts the [FileConflictResolution] to an [OverwriteRule].
  OverwriteRule? toOverwriteRule() {
    switch (this) {
      case FileConflictResolution.overwrite:
        return OverwriteRule.alwaysOverwrite;
      case FileConflictResolution.skip:
        return OverwriteRule.alwaysSkip;
      case FileConflictResolution.append:
        return OverwriteRule.alwaysAppend;
      case FileConflictResolution.prompt:
        return null;
    }
  }
}

/// Extension on [String] that enables converting to
/// an [OverwriteRule].
extension StringToOverwriteRule on String {
  /// Converts the [String] to an [OverwriteRule].
  OverwriteRule toOverwriteRule() {
    switch (this) {
      case 'n':
        return OverwriteRule.skipOnce;
      case 'a':
        return OverwriteRule.appendOnce;
      case 'Y':
        return OverwriteRule.alwaysOverwrite;
      case 'y':
      default:
        return OverwriteRule.overwriteOnce;
    }
  }
}

/// A target for a [Generator].
/// This class knows how to create files given a path and contents.
// ignore: one_member_abstracts
abstract class GeneratorTarget {
  /// Create a file at the given path with the given contents.
  Future createFile(
    String path,
    List<int> contents, {
    Logger? logger,
    OverwriteRule? overwriteRule,
  });
}

/// {@template directory_generator_target}
/// A [GeneratorTarget] based on a provided [Directory].
/// {@endtemplate}
class DirectoryGeneratorTarget extends GeneratorTarget {
  /// {@macro directory_generator_target}
  DirectoryGeneratorTarget(this.dir) {
    dir.createSync(recursive: true);
  }

  /// The target [Directory].
  final Directory dir;

  @override
  Future<File> createFile(
    String path,
    List<int> contents, {
    Logger? logger,
    OverwriteRule? overwriteRule,
  }) async {
    var _overwriteRule = overwriteRule;
    final file = File(p.join(dir.path, path));
    final fileExists = file.existsSync();

    if (!fileExists) {
      return file
          .create(recursive: true)
          .then<File>((_) => file.writeAsBytes(contents))
          .whenComplete(
            () => logger?.delayed('  ${file.path} ${lightGreen.wrap('(new)')}'),
          );
    }

    final existingContents = file.readAsBytesSync();

    if (const ListEquality<int>().equals(existingContents, contents)) {
      logger?.delayed('  ${file.path} ${lightCyan.wrap('(identical)')}');
      return file;
    }

    final shouldPrompt = logger != null &&
        (_overwriteRule != OverwriteRule.alwaysOverwrite &&
            _overwriteRule != OverwriteRule.alwaysSkip &&
            _overwriteRule != OverwriteRule.alwaysAppend);

    if (shouldPrompt) {
      logger?.info('${red.wrap(styleBold.wrap('conflict'))} ${file.path}');
      _overwriteRule = logger
          ?.prompt(
            yellow.wrap(
              styleBold.wrap('Overwrite ${p.basename(file.path)}? (Yyna) '),
            ),
          )
          .toOverwriteRule();
    }

    switch (_overwriteRule) {
      case OverwriteRule.alwaysSkip:
      case OverwriteRule.skipOnce:
        logger?.delayed('  ${file.path} ${yellow.wrap('(skip)')}');
        return file;
      case OverwriteRule.alwaysOverwrite:
      case OverwriteRule.overwriteOnce:
      case OverwriteRule.appendOnce:
      case OverwriteRule.alwaysAppend:
      case null:
        final shouldAppend = _overwriteRule == OverwriteRule.appendOnce ||
            _overwriteRule == OverwriteRule.alwaysAppend;
        return file
            .create(recursive: true)
            .then<File>(
              (_) => file.writeAsBytes(
                contents,
                mode: shouldAppend ? FileMode.append : FileMode.write,
              ),
            )
            .whenComplete(
              () => shouldAppend
                  ? logger?.delayed(
                      '  ${file.path} ${lightBlue.wrap('(modified)')}',
                    )
                  : logger?.delayed(
                      '  ${file.path} ${lightGreen.wrap('(new)')}',
                    ),
            );
    }
  }
}
