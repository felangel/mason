import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.contains('build')) {
    final result = await Process.run(
      'dart',
      ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      runInShell: true,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  print('Usage: mustachex build');
}
