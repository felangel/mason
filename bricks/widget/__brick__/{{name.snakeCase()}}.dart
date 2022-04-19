import 'package:flutter/material.dart';

class {{name.pascalCase()}} extends StatelessWidget {
  const {{name.pascalCase()}}({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: child,
    );
  }
}
