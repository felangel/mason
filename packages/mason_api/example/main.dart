import 'package:mason_api/mason_api.dart';

const email = 'my@email.com';
const password = 't0pS3cret!';

Future<void> main() async {
  final masonApi = MasonApi();

  final user = await masonApi.login(email: email, password: password);
  print('Logged in as ${user.email}!');

  masonApi.logout();
  print('Logged out!');

  masonApi.close();
}
