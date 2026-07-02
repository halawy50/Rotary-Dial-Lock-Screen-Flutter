import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_test/rotary_lock/rotary_lock_page.dart';

void main() {
  testWidgets('RotaryLockPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RotaryLockPage()));
    expect(find.text('ENTER\nPASSCODE'), findsOneWidget);
  });
}
