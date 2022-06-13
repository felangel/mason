import 'package:flutter/material.dart';

class {{name.pascalCase()}}Screen extends StatefulWidget {
  {{name.pascalCase()}}Screen({Key? key}) : super(key: key);

  @override
  State<{{name.pascalCase()}}Screen> createState() => _{{name.pascalCase()}}ScreenState();
}

class _{{name.pascalCase()}}ScreenState extends State<{{name.pascalCase()}}Screen> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}