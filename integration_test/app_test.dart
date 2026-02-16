import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todo_test/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Test', () {
    testWidgets('App launches and shows Login or Tasks page', (tester) async {
      // Start the app
      app.main();

      // Wait for the app to settle
      await tester.pumpAndSettle();

      // Since we start at Splash, we might see the Splash screen first.
      // But GoRouter should redirect us to Login or Tasks.

      // Check for common elements either on Login or Tasks page
      // (e.g., 'TaskFlow' title, 'Login', or 'Add Task' button)

      // Note: We use a longer timeout for the first pump because Firebase/Hive init
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final loginText = find.text('Login');
      final addTaskIcon = find.byIcon(Icons.add_rounded);
      final splashTitle = find.text('TaskFlow');

      expect(
        loginText.evaluate().isNotEmpty ||
            addTaskIcon.evaluate().isNotEmpty ||
            splashTitle.evaluate().isNotEmpty,
        true,
        reason: 'Should show Splash, Login, or Tasks page on launch',
      );
    });
  });
}
