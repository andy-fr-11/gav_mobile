// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gav_mobile/features/auth/screens/welcome_page.dart';

void main() {
  testWidgets('Welcome screen renders for the unauthenticated state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));

    expect(find.text('Bienvenue chez'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Découvrir nos services'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Découvrir nos services'));
    await tester.pumpAndSettle();

    expect(find.text('Nos Services'), findsOneWidget);
  });
}
