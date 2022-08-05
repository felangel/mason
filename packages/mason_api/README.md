# mason_api

[![build](https://github.com/felangel/mason/workflows/mason_api/badge.svg)](https://github.com/felangel/mason/actions)
[![coverage](https://raw.githubusercontent.com/felangel/mason/master/packages/mason_api/coverage_badge.svg)](https://github.com/felangel/mason/actions)
[![Pub](https://img.shields.io/pub/v/mason_api.svg)](https://pub.dev/packages/mason)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A Dart API client used by [package:mason_cli](https://github.com/felangel/mason).

```dart
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
```
