import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

const _equality = DeepCollectionEquality();

bool directoriesDeepEqual(
  Directory? a,
  Directory? b, {
  List<String> ignore = const <String>[],
}) {
  if (identical(a, b)) return true;
  if (a == null && b == null) return true;
  if (a == null || b == null) {
    print('null directory');
    print(a?.path);
    print(b?.path);
    return false;
  }

  final dirAContents = a.listSync(recursive: true).whereType<File>();
  final dirBContents = b.listSync(recursive: true).whereType<File>();

  if (dirAContents.length != dirBContents.length) {
    print('length mismatch');
    print(dirAContents.length);
    print(dirBContents.length);
    return false;
  }

  for (var i = 0; i < dirAContents.length; i++) {
    final fileEntityA = (dirAContents.elementAt(i));
    final fileEntityB = dirBContents.elementAt(i);

    final fileA = File(fileEntityA.path);
    final fileB = File(fileEntityB.path);

    if (path.basename(fileA.path) != path.basename(fileB.path)) {
      print('basename mismatch!');
      print(path.basename(fileA.path));
      print(path.basename(fileB.path));
      return false;
    }
    if (ignore.contains(path.basename(fileA.path))) continue;
    try {
      if (!_equality.equals(
        fileA.readAsStringSync().replaceAll('\r', '').replaceAll('\n', ''),
        fileB.readAsStringSync().replaceAll('\r', '').replaceAll('\n', ''),
      )) {
        print('file content mismatch!');
        print(
          fileA.readAsStringSync().replaceAll('\r', '').replaceAll('\n', ''),
        );
        print(
          fileB.readAsStringSync().replaceAll('\r', '').replaceAll('\n', ''),
        );
        return false;
      }
    } catch (_) {}
    if (!_equality.equals(fileA.readAsBytesSync(), fileB.readAsBytesSync())) {
      return false;
    }
  }

  return true;
}
