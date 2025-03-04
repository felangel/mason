# 0.1.1

- chore: fix `unintended_html_in_doc_comment` lint

# 0.1.0

- chore: bump to stable v0.1.0 🎉

# 0.1.0-dev.12

- deps: tighten dependency constraints ([#1400](https://github.com/felangel/mason/issues/1400))
  - bumps the Dart SDK minimum version up to `3.5.0`

# 0.1.0-dev.11

- chore: run `dart fix --apply`
- chore: use more strict analysis options
- deps: upgrade to `mocktail ^1.0.0`
- deps: allow latest `pkg:http`
- chore: remove redundant parameter in default hosted uri
- deps: bump `cli_util` from `0.3.5` to `0.4.0`

# 0.1.0-dev.10

- deps: upgrade to `Dart >=2.19` and `very_good_analysis ^4.0.0`

# 0.1.0-dev.9

- deps: upgrade to `Dart >=2.17` and `very_good_analysis ^3.1.0`

# 0.1.0-dev.8

- fix: `login` sets in-memory credentials

# 0.1.0-dev.7

- feat: add `close`
- docs: add additional metadata to `pubspec.yaml`
- chore: upgrade to `mocktail ^0.3.0`

# 0.1.0-dev.6

- refactor(deps): remove `pkg:universal_io`

# 0.1.0-dev.5

- feat: add `search` to `MasonApi`

# 0.1.0-dev.4

- feat: add `details` to `MasonApiException`
- refactor: define internal `ErrorResponse` with `JsonSerializable`

# 0.1.0-dev.3

- chore: upgrade to Dart 2.16

# 0.1.0-dev.2

- feat: support for custom `hostedUri`

# 0.1.0-dev.1

- feat: export `MasonApi`
  - `login`, `logout`, `currentUser`, and `publish` support.
