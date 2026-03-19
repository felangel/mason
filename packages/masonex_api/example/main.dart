import 'package:masonex_api/masonex_api.dart';

const email = 'my@email.com';
const password = 't0pS3cret!'; // cspell:disable-line

Future<void> main() async {
  final masonexApi = MasonexApi();

  final user = await masonexApi.login(email: email, password: password);
  print('Logged in as ${user.email}!');

  masonexApi.logout();
  print('Logged out!');

  masonexApi.close();
}
