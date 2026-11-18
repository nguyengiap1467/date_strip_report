import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('demo shows the strip and the reported result', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    await tester.pump(); // first onDateSelected arrives after the first frame

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('onDateSelected'), findsOneWidget);
    expect(find.text('month'), findsOneWidget);

    await tester.tap(find.text('Quarterly'));
    await tester.pumpAndSettle();
    expect(find.text('quarter'), findsOneWidget);

    await tester.tap(find.byTooltip('Next period'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('limiting the range clamps the selection', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    await tester.pump();
    await tester.ensureVisible(find.text('Limit to a date range'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limit to a date range'));
    await tester.pumpAndSettle();

    // The demo range ends on 2026-10-19 (endDate 2026-10-20 is exclusive).
    expect(find.text('2026-10-19'), findsWidgets);
    expect(find.text('partial'), findsOneWidget);
  });

  testWidgets('dark mode and custom labels', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byTooltip('Dark theme'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Custom labels'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom labels'));
    await tester.pumpAndSettle();

    expect(find.text('Mensuel'), findsOneWidget);
    expect(find.byTooltip('Période suivante'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
