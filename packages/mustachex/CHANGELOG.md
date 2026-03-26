## 1.1.0
- Added `processBytes()` method to `MustachexProcessor` for binary data support
- When a variable's value is `Uint8List` or `List<int>`, raw bytes are written directly without string conversion
- Text portions are UTF-8 encoded, producing a single `List<int>` output
- Existing `process()` method remains unchanged for backward compatibility

## 1.0.0
- Introduced mustache_template code. All test passing.

## 0.9.9+1
- export LambdaContext

## 0.9.9
- Introduced mustache_template code. Almsot all code is working, will be fully working on next 1.0.0 version after twerking the dependencies with mustache_recase

## 0.1.4
- Added support for emojis

## 0.1.3
- Fixed bug that didn't use mustache_recase package lambdas
- Minor version bump
## 0.1.2
- Fixed a bug when recasing inside hasXxx guards
- Fixed fauty bug
## 0.1.1

- now {"foo": false} will render {{#hasFoo}} as true instead of false
## 0.1.0

- NNBD, packages versions upgrades and all tests passings

## 0.0.1

- Initial version
