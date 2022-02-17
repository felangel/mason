import 'package:mason_auth/mason_auth.dart';

const email = 'hello@brickhub.dev';
const password = 't0pS3cret!';

Future<void> main() async {
  final masonAuth = MasonAuth();

  final user = await masonAuth.login(email: email, password: password);
  print('Logged in as ${user.email}!');

  masonAuth.logout();
  print('Logged out!');
}
