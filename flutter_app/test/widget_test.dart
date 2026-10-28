// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kaskita/main.dart';
import 'package:kaskita/widgets/bottom_nav.dart';

void main() {
  testWidgets('app boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const KasKitaApp());

    expect(find.byType(KasKitaApp), findsOneWidget);
  });

  testWidgets('bottom navigation fits a narrow phone width',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 360,
            height: 800,
            child: Scaffold(
              bottomNavigationBar: BottomNav(index: 0, onTap: (_) {}),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('KasTarget'), findsOneWidget);
    expect(find.text('Komunitas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
