import 'package:mason_logger/mason_logger.dart';

Future<void> main() async {
  final logger = Logger()
    ..info('info')
    ..alert('alert')
    ..err('error')
    ..success('success')
    ..warn('warning')
    ..detail('detail');

  final favoriteAnimal = logger.prompt('What is your favorite animal?\n');
  final done = logger.progress('Displaying progress');
  await Future<void>.delayed(const Duration(seconds: 1));
  done('Done displaying progress!');
  logger.info('Your favorite animal is $favoriteAnimal!');
}
