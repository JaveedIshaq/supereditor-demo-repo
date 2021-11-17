import 'package:flutter/material.dart';

class SuperEditorLogo extends StatelessWidget {
  const SuperEditorLogo({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 40),
      child: Image.asset(
        'assets/images/logo.gif',
        width: 188,
        height: 44,
      ),
    );
  }
}
