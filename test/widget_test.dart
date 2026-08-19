// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:vertexis/main.dart';
import 'package:vertexis/services/data_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Initialize a mock or real data service for the test
    final svc = DataService();

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: svc,
        child: const MarshBitesApp(),
      ),
    );

    // Verify that the login screen is shown.
    expect(find.text('Sign In'), findsAtLeastNWidgets(1));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
