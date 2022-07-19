import 'package:mason_logger/mason_logger.dart';

void main() async {
  final logger = Logger()..info('Starting 3 progresses');

  final progress1 = logger.progress('Progress 1');
  final progress2 = logger.progress('Progress 2');
  final progress3 = logger.progress('Progress 3');
  final progress4 = logger.progress('Progress 4');

  logger.info('HAHA get rekt');

  await Future<void>.delayed(const Duration(seconds: 2));

  progress1.fail('Failed progress 1');
  progress2.complete('Completed progress 2');
  progress3.cancel();
  progress4.fail('Failed progress 4');

  // final progress = logger.progress('Trying..');
  // logger.info('To ruin it');
  // logger.err('point proven');
  // await Future<void>.delayed(const Duration(seconds: 2));
  // progress.fail('BOO');
}
