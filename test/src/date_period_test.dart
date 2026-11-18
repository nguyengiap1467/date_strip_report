import 'dart:math';

import 'package:date_strip_report/src/date_period.dart';
import 'package:date_strip_report/src/result_date.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compares calendar fields only, so the assertions hold in every time zone.
Matcher isDay(int year, int month, int day) => predicate<DateTime>(
      (d) => d.year == year && d.month == month && d.day == day,
      '$year-$month-$day',
    );

void main() {
  group('Period.containing', () {
    test('month', () {
      final p =
          Period.containing(DateTime(2026, 11, 18, 15, 30), DateType.month);
      expect(p.start, isDay(2026, 11, 1));
      expect(p.lastDay, isDay(2026, 11, 30));
      expect(p.number, 11);
    });

    test('quarter for every month of the year', () {
      const expectedStart = [1, 1, 1, 4, 4, 4, 7, 7, 7, 10, 10, 10];
      for (var m = 1; m <= 12; m++) {
        final p = Period.containing(DateTime(2026, m, 15), DateType.quarter);
        expect(p.start, isDay(2026, expectedStart[m - 1], 1), reason: 'm=$m');
        expect(p.number, (m - 1) ~/ 3 + 1, reason: 'm=$m');
      }
    });

    test('half-year for every month of the year', () {
      for (var m = 1; m <= 12; m++) {
        final p = Period.containing(DateTime(2026, m, 28), DateType.half);
        expect(p.start, isDay(2026, m <= 6 ? 1 : 7, 1), reason: 'm=$m');
        expect(p.lastDay, isDay(2026, m <= 6 ? 6 : 12, m <= 6 ? 30 : 31));
        expect(p.number, m <= 6 ? 1 : 2);
      }
    });

    test('year', () {
      final p = Period.containing(DateTime(2026, 7, 4), DateType.year);
      expect(p.start, isDay(2026, 1, 1));
      expect(p.lastDay, isDay(2026, 12, 31));
      expect(p.endExclusive, isDay(2027, 1, 1));
      expect(p.number, 1);
    });

    test('ignores the time of day', () {
      final a = Period.containing(
        DateTime(2026, 3, 31, 23, 59, 59),
        DateType.quarter,
      );
      final b = Period.containing(DateTime(2026, 3, 1), DateType.quarter);
      expect(a, b);
    });
  });

  group('leap years', () {
    test('February length', () {
      expect(
        Period.containing(DateTime(2024, 2, 10), DateType.month).lastDay,
        isDay(2024, 2, 29),
      );
      expect(
        Period.containing(DateTime(2023, 2, 10), DateType.month).lastDay,
        isDay(2023, 2, 28),
      );
      expect(
        Period.containing(DateTime(2000, 2, 10), DateType.month).lastDay,
        isDay(2000, 2, 29),
      );
      expect(
        Period.containing(DateTime(1900, 2, 10), DateType.month).lastDay,
        isDay(1900, 2, 28),
      );
    });

    test('Q1 and H1 of a leap year include February 29', () {
      final q1 = Period.containing(DateTime(2024, 2, 29), DateType.quarter);
      expect(q1.start, isDay(2024, 1, 1));
      expect(q1.lastDay, isDay(2024, 3, 31));
      final h1 = Period.containing(DateTime(2024, 2, 29), DateType.half);
      expect(h1.lastDay, isDay(2024, 6, 30));
    });

    test('stepping from a month starting on the 29th never skips a month', () {
      var p = Period.containing(DateTime(2024, 1, 31), DateType.month);
      final starts = <int>[];
      for (var i = 0; i < 14; i++) {
        starts.add(p.start.month);
        p = p.shift(1);
      }
      expect(starts, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2]);
    });
  });

  group('Period.shift across year transitions', () {
    test('month', () {
      final dec = Period.containing(DateTime(2025, 12, 5), DateType.month);
      expect(dec.shift(1).start, isDay(2026, 1, 1));
      expect(dec.shift(-12).start, isDay(2024, 12, 1));
      expect(dec.shift(13).start, isDay(2027, 1, 1));
    });

    test('quarter', () {
      final q4 = Period.containing(DateTime(2025, 11, 1), DateType.quarter);
      expect(q4.shift(1).start, isDay(2026, 1, 1));
      expect(q4.shift(1).number, 1);
      final q1 = Period.containing(DateTime(2026, 2, 1), DateType.quarter);
      expect(q1.shift(-1).start, isDay(2025, 10, 1));
      expect(q1.shift(-1).number, 4);
    });

    test('half-year', () {
      final h1 = Period.containing(DateTime(2026, 3, 1), DateType.half);
      expect(h1.shift(-1).start, isDay(2025, 7, 1));
      expect(h1.shift(-1).lastDay, isDay(2025, 12, 31));
      expect(h1.shift(2).start, isDay(2027, 1, 1));
    });

    test('year', () {
      final y = Period.containing(DateTime(2026, 6, 1), DateType.year);
      expect(y.shift(-1).start, isDay(2025, 1, 1));
      expect(y.shift(1).lastDay, isDay(2027, 12, 31));
    });
  });

  group('DateBounds validation', () {
    test('both bounds are optional', () {
      expect(DateBounds(null, null), DateBounds.unbounded);
      expect(DateBounds(DateTime(2020), null).last, isNull);
      expect(DateBounds(null, DateTime(2020)).first, isNull);
    });

    test('rejects an empty or inverted range', () {
      expect(
        () => DateBounds(DateTime(2024, 1, 1), DateTime(2024, 1, 1)),
        throwsArgumentError,
      );
      expect(
        () => DateBounds(DateTime(2024, 5, 1), DateTime(2024, 1, 1)),
        throwsArgumentError,
      );
      // Same calendar day with different times is still empty.
      expect(
        () => DateBounds(DateTime(2024, 1, 1, 8), DateTime(2024, 1, 1, 20)),
        throwsArgumentError,
      );
    });

    test('a one-day range is valid', () {
      final b = DateBounds(DateTime(2024, 2, 29), DateTime(2024, 3, 1));
      expect(b.first, isDay(2024, 2, 29));
      expect(b.last, isDay(2024, 2, 29));
    });

    test('ignores time of day', () {
      final b = DateBounds(DateTime(2024, 1, 1, 23), DateTime(2024, 2, 1, 1));
      expect(b.first, DateTime(2024));
      expect(b.endExclusive, DateTime(2024, 2));
    });
  });

  group('DateBounds membership', () {
    final b = DateBounds(DateTime(2024, 3, 15), DateTime(2024, 10, 20));

    test('start is inclusive, end is exclusive', () {
      expect(b.contains(DateTime(2024, 3, 14)), isFalse);
      expect(b.contains(DateTime(2024, 3, 15)), isTrue);
      expect(b.contains(DateTime(2024, 10, 19, 23, 59)), isTrue);
      expect(b.contains(DateTime(2024, 10, 20)), isFalse);
      expect(b.last, isDay(2024, 10, 19));
    });

    test('clamp moves to the nearest selectable day', () {
      expect(b.clamp(DateTime(2020)), isDay(2024, 3, 15));
      expect(b.clamp(DateTime(2030)), isDay(2024, 10, 19));
      expect(b.clamp(DateTime(2024, 6, 1, 12)), DateTime(2024, 6));
    });

    test('a period overlaps when at least one of its days is selectable', () {
      Period month(int y, int m) =>
          Period.containing(DateTime(y, m), DateType.month);
      expect(b.overlaps(month(2024, 2)), isFalse);
      expect(b.overlaps(month(2024, 3)), isTrue); // partially
      expect(b.overlaps(month(2024, 10)), isTrue); // partially
      expect(b.overlaps(month(2024, 11)), isFalse);
    });

    test('a period ending the day before start does not overlap', () {
      final b2 = DateBounds(DateTime(2024, 4, 1), null);
      expect(
        b2.overlaps(Period.containing(DateTime(2024, 3), DateType.month)),
        isFalse,
      );
      expect(
        b2.overlaps(Period.containing(DateTime(2024, 4), DateType.month)),
        isTrue,
      );
    });

    test('a period starting on endDate does not overlap', () {
      final b2 = DateBounds(null, DateTime(2024, 4, 1));
      expect(
        b2.overlaps(Period.containing(DateTime(2024, 4), DateType.month)),
        isFalse,
      );
      expect(
        b2.overlaps(Period.containing(DateTime(2024, 3), DateType.month)),
        isTrue,
      );
    });

    test('partial periods are clamped to the range', () {
      final q1 = Period.containing(DateTime(2024, 3), DateType.quarter);
      expect(b.clampedStart(q1), isDay(2024, 3, 15));
      expect(b.clampedLastDay(q1), isDay(2024, 3, 31));
      final y = Period.containing(DateTime(2024), DateType.year);
      expect(b.clampedStart(y), isDay(2024, 3, 15));
      expect(b.clampedLastDay(y), isDay(2024, 10, 19));
      final q2 = Period.containing(DateTime(2024, 5), DateType.quarter);
      expect(b.clampedStart(q2), q2.start);
      expect(b.clampedLastDay(q2), q2.lastDay);
    });
  });

  group('ResultDate', () {
    test('value equality and toDateExclusive', () {
      final a = ResultDate(
        fromDate: DateTime(2024, 12),
        toDate: DateTime(2024, 12, 31),
        info: 'December',
        dateType: DateType.month,
      );
      final b = ResultDate(
        fromDate: DateTime(2024, 12),
        toDate: DateTime(2024, 12, 31),
        info: 'December',
        dateType: DateType.month,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toDateExclusive, isDay(2025, 1, 1));
      expect(
        a.toString(),
        'ResultDate(month: 2024-12-01..2024-12-31, "December")',
      );
    });
  });

  test('invariants hold for 20,000 random dates, ranges and steps', () {
    final random = Random(42);
    // Years after 2037 are avoided: there the Dart VM approximates local
    // time-zone offsets, which is visibly wrong in zones such as Pacific/Apia
    // that changed their UTC offset (DateTime(2065, 1) -> 2065-01-02 01:00).
    DateTime randomDay() => DateTime(
          1990 + random.nextInt(48),
          1 + random.nextInt(12),
          1 + random.nextInt(31), // day overflow is normalized on purpose
        );
    int days(DateTime d) => DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(1970))
        .inDays;
    for (var i = 0; i < 20000; i++) {
      final type = DateType.values[random.nextInt(4)];
      final p = Period.containing(randomDay(), type);
      final span = monthSpanOf(type);
      final steps = random.nextInt(41) - 20;

      // Shape of a period.
      expect(p.start.day, 1);
      expect((p.start.month - 1) % span, 0);
      // lastDay is the last existing day before endExclusive (normally the
      // day before; two days before where a time zone skipped a day).
      expect(p.lastDay.isBefore(p.endExclusive), isTrue);
      final following = DateTime(
        p.lastDay.year,
        p.lastDay.month,
        p.lastDay.day + 1,
      );
      expect(following.isBefore(p.endExclusive), isFalse);
      expect(Period.containing(p.lastDay, type), p);
      expect(Period.containing(p.start, type), p);
      expect(p.shift(steps).shift(-steps), p);
      expect(days(p.shift(1).start), days(p.endExclusive));

      // Clamping against a random, possibly one-sided, range.
      final a = randomDay();
      final b = DateTime(a.year, a.month, a.day + 1 + random.nextInt(1500));
      final bounds = DateBounds(
        random.nextInt(5) == 0 ? null : a,
        random.nextInt(5) == 0 ? null : b,
      );
      if (!bounds.overlaps(p)) {
        final first = bounds.first;
        final last = bounds.last;
        expect(
          (first != null && days(p.lastDay) < days(first)) ||
              (last != null && days(p.start) > days(last)),
          isTrue,
          reason: '$p is reported as outside $a..$b',
        );
        continue;
      }
      final from = bounds.clampedStart(p);
      final to = bounds.clampedLastDay(p);
      expect(days(from) <= days(to), isTrue);
      expect(bounds.contains(from) && bounds.contains(to), isTrue);
      expect(
        days(from) >= days(p.start) && days(to) <= days(p.lastDay),
        isTrue,
      );
      expect(Period.containing(bounds.clamp(p.start), type), p);
    }
  });
}
