import 'package:mason_logger/mason_logger.dart';

Future<void> main() async {
  final logger = Logger()
    ..info('info')
    ..alert('alert')
    ..err('error')
    ..success('success')
    ..warn('warning')
    ..detail('detail')
    ..info('');

  final favoriteAnimal = logger.prompt(
    'What is your favorite animal?',
    defaultValue: '🐈',
  );
  final likesCats = logger.confirm('Do you like cats?', defaultValue: true);
  final done = logger.progress('Calculating');
  await Future<void>.delayed(const Duration(seconds: 1));
  done('Done!');
  logger
    ..info('Your favorite animal is a $favoriteAnimal!')
    ..alert(likesCats ? 'You are a cat person!' : 'You are not a cat person.');
}
