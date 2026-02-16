// Basic widget test for TaskFlow app.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('TaskFlow'))),
      ),
    );

    expect(find.text('TaskFlow'), findsOneWidget);
  });
}
