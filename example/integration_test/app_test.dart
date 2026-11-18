// End-to-end checks of the demo app on a real device, simulator or emulator:
//
//   cd example
//   flutter test integration_test/app_test.dart -d <device id>
import 'package:date_strip_report/date_strip_report.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The ResultDate most recently shown by the demo's result card.
String resultCardText(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(Card).at(1),
        matching: find.byType(Text),
      ),
    )
    .map((t) => t.data)
    .join(' ');

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settle(tester);
  await tester.tap(finder);
  await settle(tester);
}

Future<void> scrollToTop(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(DateStripReport));
  await settle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('selection, navigation and range limits', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await settle(tester);
    final now = DateTime.now();
    expect(resultCardText(tester), contains('month'));
    expect(resultCardText(tester), contains('${now.year}-'));

    await tester.tap(find.text('Quarterly'));
    await settle(tester);
    expect(resultCardText(tester), contains('quarter'));
    final quarter = (now.month - 1) ~/ 3 + 1;
    expect(resultCardText(tester), contains('Quarter $quarter'));

    await tester.tap(find.byTooltip('Next period'));
    await settle(tester);
    expect(
      resultCardText(tester),
      contains('Quarter ${quarter == 4 ? 1 : quarter + 1}'),
    );
    await tester.tap(find.byTooltip('Previous period'));
    await settle(tester);
    expect(resultCardText(tester), contains('Quarter $quarter'));

    // Range 2024-03-15 .. 2026-10-20 (exclusive). Today (after the range)
    // is clamped into the last quarter, which is partial.
    await tapVisible(tester, find.text('Limit to a date range'));
    await scrollToTop(tester);
    await tester.tap(find.text('Quarterly'));
    await settle(tester);
    expect(resultCardText(tester), contains('2026-10-19'));
    expect(find.text('partial'), findsOneWidget);
    final next = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Next period'),
        matching: find.byType(IconButton),
      ),
    );
    expect(next.onPressed, isNull, reason: 'next is disabled at range end');

    // Walk back to the first quarter of the range.
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byTooltip('Previous period'));
      await tester.pump();
    }
    await settle(tester);
    expect(resultCardText(tester), contains('2024-03-15'));
    expect(resultCardText(tester), contains('2024-03-31'));
  });

  testWidgets('custom labels, dark theme and keyboard', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await settle(tester);

    await tapVisible(tester, find.text('Custom labels'));
    await scrollToTop(tester);
    expect(find.text('Mensuel'), findsOneWidget);
    expect(find.byTooltip('Période suivante'), findsOneWidget);

    await tester.tap(find.byTooltip('Dark theme'));
    await settle(tester);
    expect(find.byTooltip('Light theme'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(DateStripReport))).brightness,
      Brightness.dark,
    );

    // Hardware keyboard: focus the first tab, then step with the arrows.
    final before = resultCardText(tester);
    Focus.of(tester.element(find.text('Mensuel'))).requestFocus();
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await settle(tester);
    expect(resultCardText(tester), isNot(before));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await settle(tester);
    expect(resultCardText(tester), before);
  });

  testWidgets('large text does not overflow', (tester) async {
    await tester.pumpWidget(
      MediaQuery.fromView(
        view: tester.view,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
            ),
            child: const DemoApp(),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
