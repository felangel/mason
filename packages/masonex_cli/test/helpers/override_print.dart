import 'dart:async';

List<String> printLogs = <String>[];

void Function() overridePrint(void Function() fn) {
  return () {
    final spec = ZoneSpecification(
      print: (_, __, ___, String msg) {
        printLogs.add(msg);
      },
    );
    return Zone.current.fork(specification: spec).run<void>(fn);
  };
}
