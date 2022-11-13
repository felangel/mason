import 'package:mason_logger/mason_logger.dart';

Future<void> main() async {
  final logger = Logger();
  final progress = logger.progress('Calculating');
  await Future<void>.delayed(const Duration(seconds: 1));
  progress.update('This is taking longer than expected');
  await Future<void>.delayed(const Duration(seconds: 1));
  progress.update('Almost done');
  await Future<void>.delayed(const Duration(seconds: 1));
  progress.complete('Done');
}
