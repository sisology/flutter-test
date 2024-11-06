import 'package:flutter/material.dart';

class AnotherLogin extends StatelessWidget {
  const AnotherLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Another Login'),
      ),
      body: Center(
        child: Text('Another Login Page'),
      ),
    );
  }
}