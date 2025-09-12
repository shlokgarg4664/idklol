// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sports_app/main.dart';

void main() {
  testWidgets('App builds and shows HomeScreen overlay instruction', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Allow a couple of frames for async initializations
    await tester.pump(const Duration(milliseconds: 50));
    // Verify that the app title is set and at least renders MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
    // Since HomeScreen shows an initializing text, assert one of the known strings
    expect(find.textContaining('Initializing AI'), findsWidgets);
  });
}
