// ignore_for_file: prefer_const_constructors

import 'package:mason/mason.dart';
import 'package:mason_cli/src/install_brick.dart';
import 'package:test/test.dart';

void main() {
  group('resolveBrickLocation', () {
    test('returns original location when locked location is null', () {
      final location = BrickLocation();
      expect(
        resolveBrickLocation(location: location, lockedLocation: null),
        equals(location),
      );
    });

    test('returns original location when using a local path', () {
      final location = BrickLocation(path: '.');
      final lockedLocation = BrickLocation();
      expect(
        resolveBrickLocation(
          location: location,
          lockedLocation: lockedLocation,
        ),
        equals(location),
      );
    });

    test('returns original location when locked location is null (git)', () {
      final location = BrickLocation(
        git: GitPath('https://github.com/felangel/mason'),
      );
      final lockedLocation = BrickLocation();
      expect(
        resolveBrickLocation(
          location: location,
          lockedLocation: lockedLocation,
        ),
        equals(location),
      );
    });

    test('returns original location when locked location is not similar (git)',
        () {
      final location = BrickLocation(
        git: GitPath(
          'https://github.com/felangel/mason',
          path: 'bricks/hello',
        ),
      );
      final lockedLocation = BrickLocation(
        git: GitPath(
          'https://github.com/felangel/mason',
          path: 'bricks/widget',
        ),
      );
      expect(
        resolveBrickLocation(
          location: location,
          lockedLocation: lockedLocation,
        ),
        equals(location),
      );
    });

    test('returns locked location when locations are similar (git)', () {
      final location = BrickLocation(
        git: GitPath(
          'https://github.com/felangel/mason',
          path: 'bricks/hello',
        ),
      );
      final lockedLocation = BrickLocation(
        git: GitPath(
          'https://github.com/felangel/mason',
          path: 'bricks/hello',
          ref: 'test-ref',
        ),
      );
      expect(
        resolveBrickLocation(
          location: location,
          lockedLocation: lockedLocation,
        ),
        equals(lockedLocation),
      );
    });

    test('returns original location when locked location is null (version)',
        () {
      final location = BrickLocation(version: '1.0.0');
      final lockedLocation = BrickLocation();
      expect(
        resolveBrickLocation(
          location: location,
          lockedLocation: lockedLocation,
        ),
        equals(location),
      );
    });

    test('returns original location when locked version is incompatible', () {
      final location = BrickLocation(version: '^1.0.0');
      final lockedLocation = BrickLocation(version: '0.1.2');
      expect(
        resolveBrickLocation(
          location: location,
          lockedLocation: lockedLocation,
        ),
        equals(location),
      );
    });

    test('returns locked location when locked version is compatible', () {
      final location = BrickLocation(version: '^1.0.0');
      final lockedLocation = BrickLocation(version: '1.1.2');
      expect(
        resolveBrickLocation(
          location: location,
          lockedLocation: lockedLocation,
        ),
        equals(lockedLocation),
      );
    });
  });
}
