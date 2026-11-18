// Tests for APIs kept only for 1.x compatibility.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:date_strip_report/date-utils.dart' as legacy;
import 'package:date_strip_report/date_strip_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SlideFadeTransition', () {
    testWidgets('fades the child in', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SlideFadeTransition(id: 'a', child: Text('hello')),
        ),
      );
      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fade.opacity.value, 0);
      await tester.pumpAndSettle();
      expect(fade.opacity.value, 1);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('disposing during the delay leaves no timer or error',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SlideFadeTransition(id: 'a', delay: 300, child: Text('x')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
      // In 1.x the pending Future.delayed called forward() on a disposed
      // controller; flutter_test also fails on still-pending timers.
      expect(tester.takeException(), isNull);
    });

    testWidgets('changing id replays the animation', (tester) async {
      Widget build(String id) => Directionality(
            textDirection: TextDirection.ltr,
            child: SlideFadeTransition(id: id, child: const Text('x')),
          );
      await tester.pumpWidget(build('a'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(build('b'));
      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fade.opacity.value, 0);
      await tester.pumpAndSettle();
      expect(fade.opacity.value, 1);
    });
  });

  group('DateUtils (date-utils.dart)', () {
    test('month helpers', () {
      final feb = legacy.DateUtils.getLastDayOfMonth(DateTime(2024, 2, 10));
      expect([feb.year, feb.month, feb.day, feb.hour], [2024, 2, 29, 0]);
      final dec = legacy.DateUtils.getLastDayOfMonth(DateTime(2025, 12, 1));
      expect([dec.year, dec.month, dec.day], [2025, 12, 31]);
      expect(
        legacy.DateUtils.getFirstDayOfMonth(DateTime(2025, 12, 31, 8)),
        DateTime(2025, 12),
      );
      expect(
        legacy.DateUtils.calculateMonthsDifference(
          DateTime(2024, 11),
          DateTime(2026, 2),
        ),
        15,
      );
    });

    test('day helpers', () {
      expect(
        legacy.DateUtils.isSameDay(DateTime(2024, 1, 1, 1), DateTime(2024)),
        isTrue,
      );
      expect(legacy.DateUtils.isWeekend(DateTime(2026, 11, 21)), isTrue);
      expect(legacy.DateUtils.isWeekend(DateTime(2026, 11, 18)), isFalse);
      expect(
        legacy.DateUtils.toMidnight(DateTime(2024, 5, 6, 7, 8)),
        DateTime(2024, 5, 6),
      );
    });
  });
}
