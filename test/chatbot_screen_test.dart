import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gav_mobile/features/chatbot/chatbot_screen.dart';
import 'package:gav_mobile/features/auth/providers/auth_provider.dart';
import 'package:gav_mobile/providers/appointment_provider.dart';
import 'package:gav_mobile/providers/order_provider.dart';

void main() {
  testWidgets('Chatbot screen renders and answers appointment requests', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AppointmentProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
        ],
        child: const MaterialApp(home: ChatbotScreen()),
      ),
    );

    expect(find.text('Assistant GAV'), findsOneWidget);
    expect(find.textContaining('Bonjour'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'je veux prendre un rendez-vous',
    );
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(find.textContaining('rendez-vous'), findsWidgets);
  });
}
