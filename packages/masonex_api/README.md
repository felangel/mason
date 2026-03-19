# masonex_api

[![build](https://github.com/felangel/masonex/workflows/masonex_api/badge.svg)](https://github.com/felangel/masonex/actions)
[![coverage](https://raw.githubusercontent.com/felangel/masonex/master/packages/masonex_api/coverage_badge.svg)](https://github.com/felangel/masonex/actions)
[![Pub](https://img.shields.io/pub/v/masonex_api.svg)](https://pub.dev/packages/masonex)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A Dart API client used by [package:masonex_cli](https://github.com/felangel/masonex).

```dart
import 'package:masonex_api/masonex_api.dart';

const email = 'my@email.com';
const password = 'top-secret!';

Future<void> main() async {
  final masonexApi = MasonexApi();

  final user = await masonexApi.login(email: email, password: password);
  print('Logged in as ${user.email}!');

  masonexApi.logout();
  print('Logged out!');

  masonexApi.close();
}
```
