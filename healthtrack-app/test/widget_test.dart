// Smoke test tối thiểu: chỉ kiểm tra app build được theme + MaterialApp,
// không khởi tạo Supabase thật (cần .env + network) nên không test AuthGate ở đây.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthtrack_app/core/theme.dart';

void main() {
  testWidgets('App theme builds a MaterialApp without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: const Scaffold(body: Center(child: Text('HealthTrack'))),
    ));

    expect(find.text('HealthTrack'), findsOneWidget);
  });
}
