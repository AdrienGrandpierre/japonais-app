import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_japonais_app/main.dart';

void main() {
  testWidgets('App starts and shows Hello World', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hello World!'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
