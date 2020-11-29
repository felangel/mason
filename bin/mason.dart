import 'package:mason/src/command_runner.dart';
import 'package:mason/src/io.dart';

void main(List<String> args) async {
  await flushThenExit(await MasonCommandRunner().run(args));
}
