import 'package:flutter/material.dart';
import 'rotary_lock_widget.dart';

class RotaryLockPage extends StatelessWidget {
  const RotaryLockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RotaryLockWidget(correctCode: '1234'),
      ),
    );
  }
}
