import 'package:mason/src/compute.dart';
import 'package:test/test.dart';

int test1(int value) => value + 1;

// ignore: only_throw_errors
int test2(int value) => throw 2;

Future<int> test1Async(int value) async => value + 1;

// ignore: only_throw_errors
Future<int> test2Async(int value) async => throw 2;

void main() {
  test('compute()', () async {
    expect(await compute(test1, 0), 1);
    expect(compute(test2, 0), throwsException);

    expect(await compute(test1Async, 0), 1);
    expect(compute(test2Async, 0), throwsException);
  });
}
