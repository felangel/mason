import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';

String testFixturesPath(Directory cwd, {String suffix = ''}) {
  return path.join(cwd.path, 'test', 'fixtures', suffix);
}

void setUpTestingEnvironment(Directory cwd, {String suffix = ''}) {
  try {
    final testDir = Directory(testFixturesPath(cwd, suffix: suffix));
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
    testDir.createSync(recursive: true);
    Directory.current = testDir.path;
    File(
      path.join(Directory.current.path, '.mason', 'bricks.json'),
    ).deleteSync();
  } catch (_) {}
}
