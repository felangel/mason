# mason_auth

[![build](https://github.com/felangel/mason/workflows/mason_auth/badge.svg)](https://github.com/felangel/mason/actions)
[![coverage](https://raw.githubusercontent.com/felangel/mason/master/packages/mason_auth/coverage_badge.svg)](https://github.com/felangel/mason/actions)
[![Pub](https://img.shields.io/pub/v/mason_auth.svg)](https://pub.dev/packages/mason)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

An auth client used by the [Mason CLI](https://github.com/felangel/mason).

```dart
import 'package:mason_auth/mason_auth.dart';

const email = 'my@email.com';
const password = 't0pS3cret!';

Future<void> main() async {
  final masonAuth = MasonAuth();

  final user = await masonAuth.login(email: email, password: password);
  print('Logged in as ${user.email}!');

  masonAuth.logout();
  print('Logged out!');
}

```
