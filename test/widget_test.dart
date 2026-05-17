// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/src/screens/app_root.dart';

void main() {
  testWidgets('BattleBoats login screen smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BattleBoatsApp());
    await tester.pumpAndSettle();

    expect(find.text('Command deck access'), findsOneWidget);
    expect(find.text('Enter Deck'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });
}
