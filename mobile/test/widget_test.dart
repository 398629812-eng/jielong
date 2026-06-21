import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jielong/main.dart';

void main() {
  testWidgets('JieLongApp root smoke test', (WidgetTester tester) async {
    // Pump the app root without waiting for SplashScreen async flow.
    await tester.pumpWidget(const JieLongApp());

    // Verify MaterialApp exists and has the expected title.
    expect(find.byType(MaterialApp), findsOneWidget);
    final MaterialApp app =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, '成语接龙');

    // Unmount the widget tree to stop animations and timers.
    await tester.pumpWidget(Container());
  });
}
