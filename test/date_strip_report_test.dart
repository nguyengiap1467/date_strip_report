import 'dart:math';

import 'package:date_strip_report/date_strip_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compares calendar fields only, so the assertions hold in every time zone.
Matcher isDay(int year, int month, int day) => predicate<DateTime>(
      (d) => d.year == year && d.month == month && d.day == day,
      '$year-$month-$day',
    );

Widget app(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );

final Finder next = find.byIcon(Icons.arrow_forward_ios);
final Finder previous = find.byIcon(Icons.arrow_back_ios);

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('regressions found in the 1.x audit', () {
    testWidgets('P1: startDate and endDate are optional', (tester) async {
      final results = <ResultDate>[];
      await tester
          .pumpWidget(app(DateStripReport(onDateSelected: results.add)));

      expect(tester.takeException(), isNull);
      final now = DateTime.now();
      expect(results.single.fromDate, isDay(now.year, now.month, 1));
      expect(results.single.dateType, DateType.month);
    });

    testWidgets('P2: onDateSelected is optional', (tester) async {
      await tester.pumpWidget(app(const DateStripReport()));
      await tapAndSettle(tester, next);
      await tapAndSettle(tester, find.text('Quarterly'));

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'P3: a range that excludes today no longer throws; '
        'the selection is clamped into the range', (tester) async {
      final results = <ResultDate>[];
      // The exact range used by the 1.x example app.
      await tester.pumpWidget(
        app(
          DateStripReport(
            startDate: DateTime(2020, 1, 1),
            endDate: DateTime(2024, 1, 1),
            onDateSelected: results.add,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        DateTime.now().isAfter(DateTime(2024)),
        isTrue,
        reason: 'this test assumes today is after the range',
      );
      expect(results.single.fromDate, isDay(2023, 12, 1));
      expect(results.single.toDate, isDay(2023, 12, 31));
      expect(results.single.info, 'December');
      expect(results.single.isPartial, isFalse);
    });

    testWidgets(
        'P4: locales without period labels fall back to English '
        'instead of crashing or showing "null"', (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            locale: LocaleType.fr,
            onDateSelected: results.add,
          ),
        ),
      );

      final texts =
          tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
      expect(texts, isNot(contains('null')));
      for (final tab in ['Quarterly', 'Half Year', 'Yearly', 'Monthly']) {
        await tapAndSettle(tester, find.text(tab));
      }

      expect(tester.takeException(), isNull);
      expect(
        results.map((r) => r.info).skip(1).take(3),
        ['Quarter 4', 'Second half', '2026'],
      );
    });

    testWidgets('P5: Chinese and Korean tab titles are correct',
        (tester) async {
      await tester
          .pumpWidget(app(const DateStripReport(locale: LocaleType.zh)));
      for (final title in ['月度', '季度', '半年度', '年度']) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('日'), findsNothing);

      await tester
          .pumpWidget(app(const DateStripReport(locale: LocaleType.ko)));
      for (final title in ['월별', '분기별', '반기별', '연도별']) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('일'), findsNothing);
    });

    testWidgets('P6: the parent may call setState from onDateSelected',
        (tester) async {
      ResultDate? latest;
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                Text('parent: ${latest?.info}'),
                Expanded(
                  child: DateStripReport(
                    initialDate: DateTime(2024, 5, 10),
                    onDateSelected: (r) => setState(() => latest = r),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('parent: May'), findsOneWidget);

      await tapAndSettle(tester, next);
      expect(find.text('parent: June'), findsOneWidget);
    });

    testWidgets('P7: leftIcon and rightIcon are used', (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2024, 5, 10),
            leftIcon: const Icon(Icons.chevron_left),
            rightIcon: const Icon(Icons.chevron_right),
            onDateSelected: results.add,
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(previous, findsNothing);
      expect(next, findsNothing);

      await tapAndSettle(tester, find.byIcon(Icons.chevron_right));
      expect(results.last.info, 'June');
      await tapAndSettle(tester, find.byIcon(Icons.chevron_left));
      expect(results.last.info, 'May');
    });

    testWidgets(
        'P8: navigation is limited from the first frame and never '
        'leaves the range', (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 11, 30), // exclusive: last day is Nov 29
            onDateSelected: results.add,
          ),
        ),
      );
      await tapAndSettle(tester, next);

      expect(results, hasLength(1), reason: '"next" must be disabled');
      expect(results.single.toDate, isDay(2026, 11, 29));
      expect(results.single.isPartial, isTrue);
    });

    testWidgets('P9: English period names have no ordinal typos',
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
      await tapAndSettle(tester, find.text('Quarterly'));
      await tapAndSettle(tester, find.text('Half Year'));
      await tapAndSettle(tester, previous);

      expect(
        results.map((r) => r.info),
        ['November', 'Quarter 4', 'Second half', 'First half'],
      );
      expect(find.textContaining(RegExp(r'\d(st|nd|rd)\b')), findsNothing);
    });

    testWidgets('hiding the month tab starts on the first visible tab',
        (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            isShowMonth: false,
            onDateSelected: results.add,
          ),
        ),
      );

      expect(results.single.dateType, DateType.quarter);
      expect(find.text('Monthly'), findsNothing);
      expect(find.text('Quarter 4'), findsOneWidget);
    });
  });

  group('date range', () {
    testWidgets('quarters that partially overlap are clamped at both ends',
        (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            startDate: DateTime(2024, 3, 15),
            endDate: DateTime(2024, 10, 20),
            initialDate: DateTime(2024, 3, 20),
            initialDateType: DateType.quarter,
            onDateSelected: results.add,
          ),
        ),
      );
      await tapAndSettle(tester, previous); // disabled: Q4 2023 is outside
      for (var i = 0; i < 4; i++) {
        await tapAndSettle(tester, next); // the 4th tap is disabled
      }

      expect(results.map((r) => r.info), [
        'Quarter 1',
        'Quarter 2',
        'Quarter 3',
        'Quarter 4',
      ]);
      expect(results.first.fromDate, isDay(2024, 3, 15));
      expect(results.first.toDate, isDay(2024, 3, 31));
      expect(results.first.isPartial, isTrue);
      expect(results[1].fromDate, isDay(2024, 4, 1));
      expect(results[1].toDate, isDay(2024, 6, 30));
      expect(results[1].isPartial, isFalse);
      expect(results.last.fromDate, isDay(2024, 10, 1));
      expect(results.last.toDate, isDay(2024, 10, 19));
      expect(results.last.isPartial, isTrue);
    });

    testWidgets('a year that contains the whole range returns the range',
        (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            startDate: DateTime(2024, 3, 15),
            endDate: DateTime(2024, 10, 20),
            initialDateType: DateType.year,
            onDateSelected: results.add,
          ),
        ),
      );
      await tapAndSettle(tester, previous);
      await tapAndSettle(tester, next);

      expect(results.single.fromDate, isDay(2024, 3, 15));
      expect(results.single.toDate, isDay(2024, 10, 19));
      expect(results.single.info, '2024');
    });

    testWidgets('initialDate is clamped into the range', (tester) async {
      final results = <ResultDate>[];
      Widget strip(DateTime initial) => DateStripReport(
            key: ValueKey(initial),
            startDate: DateTime(2024, 3, 15),
            endDate: DateTime(2024, 10, 20),
            initialDate: initial,
            onDateSelected: results.add,
          );
      await tester.pumpWidget(app(strip(DateTime(2000))));
      await tester.pumpWidget(app(strip(DateTime(2099))));

      expect(results.first.fromDate, isDay(2024, 3, 15));
      expect(results.first.info, 'March');
      expect(results.last.toDate, isDay(2024, 10, 19));
      expect(results.last.info, 'October');
    });

    testWidgets('leap years', (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2024, 1, 31),
            onDateSelected: results.add,
          ),
        ),
      );
      await tapAndSettle(tester, next);
      await tapAndSettle(tester, find.text('Yearly'));
      await tapAndSettle(tester, next);
      await tapAndSettle(tester, find.text('Monthly'));
      await tapAndSettle(tester, next);

      // Jan 31 + 1 month is February, not March.
      expect(results[1].info, 'February');
      expect(results[1].toDate, isDay(2024, 2, 29));
      expect(results[3].fromDate, isDay(2025, 1, 1));
      expect(results[3].toDate, isDay(2025, 12, 31));
      // Tab switch goes back to initialDate (Jan 2024), then +1 month.
      expect(results[5].toDate, isDay(2024, 2, 29));
    });

    testWidgets('year transitions for every period type', (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2025, 12, 15),
            onDateSelected: results.add,
          ),
        ),
      );
      await tapAndSettle(tester, next);
      expect(results.last.fromDate, isDay(2026, 1, 1));
      expect(results.last.info, 'January');
      expect(find.text('2026'), findsOneWidget);

      await tapAndSettle(tester, find.text('Quarterly'));
      expect(results.last.info, 'Quarter 4');
      await tapAndSettle(tester, next);
      expect(results.last.fromDate, isDay(2026, 1, 1));
      expect(results.last.toDate, isDay(2026, 3, 31));

      await tapAndSettle(tester, find.text('Half Year'));
      await tapAndSettle(tester, next);
      expect(results.last.fromDate, isDay(2026, 1, 1));
      await tapAndSettle(tester, previous);
      await tapAndSettle(tester, previous);
      expect(results.last.fromDate, isDay(2025, 1, 1));
      expect(results.last.toDate, isDay(2025, 6, 30));

      await tapAndSettle(tester, find.text('Yearly'));
      await tapAndSettle(tester, previous);
      expect(results.last.fromDate, isDay(2024, 1, 1));
      expect(results.last.toDate, isDay(2024, 12, 31));
    });

    testWidgets('an empty or inverted range throws ArgumentError',
        (tester) async {
      await tester.pumpWidget(
        app(
          DateStripReport(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 1),
          ),
        ),
      );
      expect(tester.takeException(), isArgumentError);

      await tester.pumpWidget(
        app(
          DateStripReport(
            key: UniqueKey(),
            startDate: DateTime(2024, 6, 1),
            endDate: DateTime(2024, 1, 1),
          ),
        ),
      );
      expect(tester.takeException(), isArgumentError);
    });

    testWidgets('hiding every tab throws ArgumentError', (tester) async {
      await tester.pumpWidget(
        app(
          const DateStripReport(
            isShowMonth: false,
            isShowQuarter: false,
            isShowHalfYear: false,
            isShowYear: false,
          ),
        ),
      );
      expect(tester.takeException(), isArgumentError);
    });

    testWidgets('random ranges and navigation never leave the range',
        (tester) async {
      final random = Random(20261118);
      const tabs = ['Monthly', 'Quarterly', 'Half Year', 'Yearly'];
      for (var scenario = 0; scenario < 40; scenario++) {
        final start = DateTime(
          2019 + random.nextInt(6),
          1 + random.nextInt(12),
          1 + random.nextInt(28),
        );
        final end = DateTime(
          start.year,
          start.month,
          start.day + 1 + random.nextInt(900),
        );
        final initial =
            DateTime(2018 + random.nextInt(10), 1 + random.nextInt(12), 15);
        final results = <ResultDate>[];
        await tester.pumpWidget(
          app(
            DateStripReport(
              key: ValueKey(scenario),
              startDate: start,
              endDate: end,
              initialDate: initial,
              onDateSelected: results.add,
            ),
          ),
        );
        for (var step = 0; step < 12; step++) {
          final action = random.nextInt(6);
          if (action < 4) {
            await tester.tap(find.text(tabs[action]).first);
          } else {
            await tester.tap(action == 4 ? next : previous);
          }
          await tester.pump();
        }

        final last = DateTime(end.year, end.month, end.day - 1);
        for (final r in results) {
          final from = r.fromDate;
          final to = r.toDate;
          final scenarioInfo = 'scenario $scenario: $start..$end -> $r';
          expect(
            from.isBefore(DateTime(start.year, start.month, start.day)),
            isFalse,
            reason: scenarioInfo,
          );
          expect(to.isAfter(last), isFalse, reason: scenarioInfo);
          expect(to.isBefore(from), isFalse, reason: scenarioInfo);
        }
      }
    });
  });

  group('runtime property changes', () {
    testWidgets('shrinking the range re-clamps and reports the selection',
        (tester) async {
      final results = <ResultDate>[];
      Widget strip({DateTime? endDate}) => DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            endDate: endDate,
            onDateSelected: results.add,
          );
      await tester.pumpWidget(app(strip()));
      await tester.pumpWidget(app(strip(endDate: DateTime(2026, 10, 1))));

      expect(results.map((r) => r.info), ['November', 'September']);
      expect(results.last.toDate, isDay(2026, 9, 30));

      // A partial overlap is reported as such.
      await tester.pumpWidget(app(strip(endDate: DateTime(2026, 9, 10))));
      expect(results.last.toDate, isDay(2026, 9, 9));
      expect(results.last.isPartial, isTrue);
    });

    testWidgets('changing locale or labels re-reports the new text',
        (tester) async {
      final results = <ResultDate>[];
      Widget strip(LocaleType locale, [DateStripLabels? labels]) =>
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            locale: locale,
            labels: labels,
            onDateSelected: results.add,
          );
      await tester.pumpWidget(app(strip(LocaleType.en)));
      await tester.pumpWidget(app(strip(LocaleType.vi)));
      expect(find.text('Tháng'), findsOneWidget);
      await tester.pumpWidget(
        app(
          strip(
            LocaleType.vi,
            DateStripLabels.english.copyWith(monthly: 'Per month'),
          ),
        ),
      );
      await tester.pump();

      expect(results.map((r) => r.info), ['November', 'Tháng 11', 'November']);
      expect(find.text('Per month'), findsOneWidget);
    });

    testWidgets('hiding the selected tab switches to the first visible one',
        (tester) async {
      final results = <ResultDate>[];
      Widget strip({required bool showMonth}) => DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            isShowMonth: showMonth,
            onDateSelected: results.add,
          );
      await tester.pumpWidget(app(strip(showMonth: true)));
      await tester.pumpWidget(app(strip(showMonth: false)));
      await tester.pump();

      expect(results.last.dateType, DateType.quarter);
      expect(results.last.info, 'Quarter 4');
    });

    testWidgets('rebuilding with equal properties does not re-report',
        (tester) async {
      final results = <ResultDate>[];
      Widget strip() => DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            startDate: DateTime(2020),
            onDateSelected: results.add,
          );
      await tester.pumpWidget(app(strip()));
      await tester.pumpWidget(app(strip()));
      await tester.pumpWidget(app(strip()));

      expect(results, hasLength(1));
    });

    testWidgets('a replaced callback receives later selections',
        (tester) async {
      final first = <ResultDate>[];
      final second = <ResultDate>[];
      Widget strip(ValueChanged<ResultDate> cb) => DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            onDateSelected: cb,
          );
      await tester.pumpWidget(app(strip(first.add)));
      await tester.pumpWidget(app(strip(second.add)));
      await tapAndSettle(tester, next);

      expect(first.map((r) => r.info), ['November']);
      expect(second.map((r) => r.info), ['December']);
    });

    testWidgets('an invalid range set at runtime throws ArgumentError',
        (tester) async {
      Widget strip(DateTime? start) =>
          DateStripReport(startDate: start, endDate: DateTime(2024));
      await tester.pumpWidget(app(strip(DateTime(2020))));
      await tester.pumpWidget(app(strip(DateTime(2025))));
      expect(tester.takeException(), isArgumentError);
    });
  });

  group('behaviour kept from 1.x', () {
    testWidgets('reports exactly once after the first frame', (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            onDateSelected: results.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(results, hasLength(1));
      expect(results.single.fromDate, isDay(2026, 11, 1));
      expect(results.single.toDate, isDay(2026, 11, 30));
    });

    testWidgets(
        'switching tabs goes back to initialDate, and tapping the '
        'selected tab reports again', (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            onDateSelected: results.add,
          ),
        ),
      );
      await tapAndSettle(tester, next);
      await tapAndSettle(tester, next);
      await tapAndSettle(tester, find.text('Quarterly'));
      await tapAndSettle(tester, find.text('Quarterly'));

      expect(results.map((r) => r.info), [
        'November',
        'December',
        'January',
        'Quarter 4',
        'Quarter 4',
      ]);
    });

    testWidgets('initialDateType selects the tab', (tester) async {
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            initialDate: DateTime(2026, 11, 18),
            initialDateType: DateType.half,
            onDateSelected: results.add,
          ),
        ),
      );
      expect(results.single.info, 'Second half');
      expect(results.single.fromDate, isDay(2026, 7, 1));
      expect(results.single.toDate, isDay(2026, 12, 31));
    });
  });

  group('deprecated 1.x API still works', () {
    testWidgets('state navigation helpers', (tester) async {
      final key = GlobalKey<DateStripReportState>();
      final results = <ResultDate>[];
      await tester.pumpWidget(
        app(
          DateStripReport(
            key: key,
            initialDate: DateTime(2026, 11, 18),
            endDate: DateTime(2027, 1, 1),
            onDateSelected: results.add,
          ),
        ),
      );
      final state = key.currentState!;
      // ignore: deprecated_member_use_from_same_package
      state.getNextMonth();
      // ignore: deprecated_member_use_from_same_package
      expect(state.enbaleNext, isFalse);
      // ignore: deprecated_member_use_from_same_package
      expect(state.enbalePrevious, isTrue);
      // ignore: deprecated_member_use_from_same_package
      state.getNextMonth(); // blocked by endDate
      // ignore: deprecated_member_use_from_same_package
      state.getPreviousYear();
      expect(state.selectedResult.info, 'December');
      expect(state.selectedResult.fromDate, isDay(2025, 12, 1));

      expect(results.map((r) => r.info), ['November', 'December', 'December']);
    });

    testWidgets('state date helpers keep their 1.x semantics', (tester) async {
      final key = GlobalKey<DateStripReportState>();
      await tester.pumpWidget(app(DateStripReport(key: key)));
      final s = key.currentState!;
      final a = DateTime(2024, 5, 1, 23);
      final b = DateTime(2024, 5, 1, 1);
      // ignore: deprecated_member_use_from_same_package
      expect(s.isDateBefore(a, b), isFalse);
      // ignore: deprecated_member_use_from_same_package
      expect(s.isDateAfter(a, b), isTrue, reason: 'same day counts as after');
      // ignore: deprecated_member_use_from_same_package
      expect(s.getDateOnly(a), DateTime(2024, 5, 1));
      // ignore: deprecated_member_use_from_same_package
      expect(s.nullOrDefault(null, 3), 3);

      expect(
        // ignore: deprecated_member_use_from_same_package
        () => s.runPresetsAndExceptions(
          DateTime(2030),
          DateTime(2020),
          DateTime(2024),
        ),
        throwsArgumentError,
      );
    });
  });
}
