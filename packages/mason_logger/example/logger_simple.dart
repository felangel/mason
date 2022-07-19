import 'package:mason_logger/mason_logger.dart';

void main() async {
  final logger = Logger()..info('Starting');

  final progress1 = logger.progress('Progress 1');

  logger.info('HAHA get rekt');

  await Future<void>.delayed(const Duration(seconds: 2));

  progress1.fail('Failed progress 1');
}
