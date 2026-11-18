import 'package:date_strip_report/date_strip_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(
  Widget child, {
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) =>
    MaterialApp(
      theme: theme,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );

/// Fill color of the pill that contains [label].
Color? tabFill(WidgetTester tester, String label) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}

void main() {
  group('accessibility', () {
    testWidgets('meets Flutter tap-target, label and contrast guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(DateStripReport(initialDate: DateTime(2026, 11, 18))),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('tabs are buttons in a mutually exclusive group',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(DateStripReport(initialDate: DateTime(2026, 11, 18))),
      );

      expect(
        tester.getSemantics(find.text('Monthly')),
        containsSemantics(
          label: 'Monthly',
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Quarterly')),
        containsSemantics(
          label: 'Quarterly',
          isButton: true,
          isSelected: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('navigation buttons have tooltips and a disabled state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 1, 18),
            startDate: DateTime(2026, 1, 1),
          ),
        ),
      );

      expect(find.byTooltip('Previous period'), findsOneWidget);
      expect(find.byTooltip('Next period'), findsOneWidget);
      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.byTooltip('Previous period'),
            matching: find.byType(IconButton),
          ),
        ),
        containsSemantics(isButton: true, isEnabled: false),
      );
      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.byTooltip('Next period'),
            matching: find.byType(IconButton),
          ),
        ),
        containsSemantics(isButton: true, isEnabled: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('the selected period is announced as a live region',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(DateStripReport(initialDate: DateTime(2026, 11, 18))),
      );

      expect(
        find.bySemanticsLabel('2026, November'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('2026, November')),
        containsSemantics(isLiveRegion: true),
      );
      await tester.tap(find.byTooltip('Next period'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('2026, December'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('translated tooltips', (tester) async {
      await tester
          .pumpWidget(app(const DateStripReport(locale: LocaleType.vi)));
      expect(find.byTooltip('Kỳ trước'), findsOneWidget);
      expect(find.byTooltip('Kỳ sau'), findsOneWidget);
    });

    testWidgets('large text on a narrow screen does not overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: app(
            DateStripReport(
              initialDate: DateTime(2026, 9, 1),
              initialDateType: DateType.half,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets('tab titles shrink instead of breaking inside a word',
        (tester) async {
      tester.view.physicalSize = const Size(300 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const DateStripReport()));

      double lineHeight(String label) =>
          tester.renderObject<RenderBox>(find.text(label)).size.height;
      // "Quarterly" is the longest word; it must stay on one line.
      expect(lineHeight('Quarterly'), lineHeight('Yearly'));
      expect(lineHeight('Half Year'), lineHeight('Yearly'));
      expect(tester.takeException(), isNull);
    });
  });

  group('keyboard', () {
    testWidgets('Tab focuses the tabs, Enter selects, arrows step',
        (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            onDateSelected: results.add,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Monthly
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Quarterly
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(results.last.info, 'Quarter 4');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(results.last.info, 'Quarter 1');
      expect(results.last.fromDate, DateTime(2027));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(results.last.info, 'Quarter 3');
    });

    testWidgets('arrow keys respect range limits', (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            endDate: DateTime(2026, 12, 1),
            onDateSelected: results.add,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(results, hasLength(1));
    });

    testWidgets('in right-to-left layouts the arrow keys follow the visuals',
        (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            onDateSelected: results.add,
          ),
          direction: TextDirection.rtl,
        ),
      );
      // "Previous" is laid out on the right in RTL.
      expect(
        tester.getCenter(find.byTooltip('Previous period')).dx,
        greaterThan(tester.getCenter(find.byTooltip('Next period')).dx),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(results.last.info, 'October');
    });
  });

  group('theming', () {
    testWidgets('defaults come from the ColorScheme', (tester) async {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      );
      await tester.pumpWidget(
        app(DateStripReport(initialDate: DateTime(2026, 11, 18)), theme: theme),
      );

      expect(tabFill(tester, 'Monthly'), theme.colorScheme.primary);
      expect(tabFill(tester, 'Yearly'), theme.colorScheme.surface);
      expect(
        tester.widget<Text>(find.text('November')).style?.color,
        theme.colorScheme.onSurface,
      );
    });

    testWidgets('dark theme', (tester) async {
      final theme = ThemeData(brightness: Brightness.dark);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(DateStripReport(initialDate: DateTime(2026, 11, 18)), theme: theme),
      );

      expect(
        tester.widget<Text>(find.text('November')).style?.color,
        theme.colorScheme.onSurface,
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('explicit colors still win (1.x look)', (tester) async {
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            selectedColor: Colors.green,
            unSelectedColor: Colors.white,
            textColor: Colors.green,
            navigationColor: Colors.black,
            navigationDisableColor: Colors.black12,
          ),
        ),
      );

      expect(tabFill(tester, 'Monthly'), Colors.green);
      expect(tabFill(tester, 'Quarterly'), Colors.white);
      expect(
        tester.widget<Text>(find.text('November')).style?.color,
        Colors.green,
      );
      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Next period'),
          matching: find.byType(IconButton),
        ),
      );
      expect(next.color, Colors.black);
      expect(next.disabledColor, Colors.black12);
    });
  });
}
