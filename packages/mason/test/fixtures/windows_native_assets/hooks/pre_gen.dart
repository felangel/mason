import 'package:mason/mason.dart';
import 'package:win32/win32.dart';

void run(HookContext context) {
  final int activeCodePage = GetACP();
  context.vars = <String, dynamic>{
    ...context.vars,
    'activeCodePage': '$activeCodePage',
  };
}
