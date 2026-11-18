// Pure calendar arithmetic used by DateStripReport. Not exported from the
// public library; covered directly by test/src/date_period_test.dart.
//
// All values are calendar dates at local midnight built with the
// DateTime(year, month, day) constructor, which normalizes out-of-range
// months and days. No Duration arithmetic is used, so results are correct in
// time zones where a daylight-saving change happens at midnight.

import 'package:flutter/foundation.dart';

import 'result_date.dart';

/// Strips the time of day from [date], keeping its calendar date.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// The last calendar day before [end] (a local midnight).
///
/// Normally `DateTime(y, m, d - 1)`. A few time zones skipped a whole calendar
/// day (Pacific/Kiritimati: 1994-12-31, Pacific/Apia: 2011-12-30); DateTime
/// then rolls the missing day forward onto [end], so step back further.
DateTime dayBefore(DateTime end) {
  var back = 1;
  var day = DateTime(end.year, end.month, end.day - back);
  while (!day.isBefore(end)) {
    back++;
    day = DateTime(end.year, end.month, end.day - back);
  }
  return day;
}

/// Number of months covered by one period of [type].
int monthSpanOf(DateType type) => switch (type) {
      DateType.month => 1,
      DateType.quarter => 3,
      DateType.half => 6,
      DateType.year => 12,
    };

/// One calendar month, quarter, half-year or year.
@immutable
class Period {
  /// The period of [type] that contains [date].
  factory Period.containing(DateTime date, DateType type) {
    final span = monthSpanOf(type);
    final firstMonth = ((date.month - 1) ~/ span) * span + 1;
    return Period._(DateTime(date.year, firstMonth), type);
  }

  const Period._(this.start, this.type);

  /// First day of the period.
  final DateTime start;

  /// Granularity of the period.
  final DateType type;

  int get _span => monthSpanOf(type);

  /// Last day of the period (inclusive).
  DateTime get lastDay => dayBefore(endExclusive);

  /// First day after the period.
  DateTime get endExclusive => DateTime(start.year, start.month + _span);

  /// 1-based index of the period within its year: month 1–12, quarter 1–4,
  /// half 1–2, year 1.
  int get number => (start.month - 1) ~/ _span + 1;

  /// The period [steps] periods away (negative steps go back in time).
  Period shift(int steps) =>
      Period._(DateTime(start.year, start.month + _span * steps), type);

  @override
  bool operator ==(Object other) =>
      other is Period && other.start == start && other.type == type;

  @override
  int get hashCode => Object.hash(start, type);

  @override
  String toString() => 'Period(${type.name} $start)';
}

/// An optional, possibly one-sided range of selectable calendar dates.
///
/// [first] is inclusive and [endExclusive] is exclusive, matching how
/// `DateStripReport.startDate` and `DateStripReport.endDate` have always
/// behaved. Times of day are ignored.
@immutable
class DateBounds {
  /// Normalizes and validates a `startDate` / `endDate` pair.
  ///
  /// Throws an [ArgumentError] when both are given and [startDate] is not
  /// before [endDate] on the calendar (the range would be empty).
  factory DateBounds(DateTime? startDate, DateTime? endDate) {
    final first = startDate == null ? null : dateOnly(startDate);
    final end = endDate == null ? null : dateOnly(endDate);
    if (first != null && end != null && !first.isBefore(end)) {
      throw ArgumentError(
        'startDate (${_ymd(first)}) must be before endDate (${_ymd(end)}). '
        'endDate is exclusive, so the range would be empty.',
      );
    }
    return DateBounds._(first, end);
  }

  const DateBounds._(this.first, this.endExclusive);

  /// No restriction.
  static const DateBounds unbounded = DateBounds._(null, null);

  /// First selectable date, or `null` for no lower bound.
  final DateTime? first;

  /// First date after the range, or `null` for no upper bound.
  final DateTime? endExclusive;

  /// Last selectable date, or `null` for no upper bound.
  DateTime? get last {
    final end = endExclusive;
    return end == null ? null : dayBefore(end);
  }

  /// Whether the calendar date of [date] is selectable.
  bool contains(DateTime date) {
    final day = dateOnly(date);
    final first = this.first;
    final end = endExclusive;
    return (first == null || !day.isBefore(first)) &&
        (end == null || day.isBefore(end));
  }

  /// The calendar date of [date], moved to the nearest selectable date.
  DateTime clamp(DateTime date) {
    final day = dateOnly(date);
    final first = this.first;
    final last = this.last;
    if (first != null && day.isBefore(first)) return first;
    if (last != null && day.isAfter(last)) return last;
    return day;
  }

  /// Whether at least one day of [period] is selectable.
  bool overlaps(Period period) {
    final first = this.first;
    final end = endExclusive;
    return (end == null || period.start.isBefore(end)) &&
        (first == null || period.endExclusive.isAfter(first));
  }

  /// First selectable day of [period]. Only meaningful when [overlaps].
  DateTime clampedStart(Period period) {
    final first = this.first;
    return first != null && period.start.isBefore(first) ? first : period.start;
  }

  /// Last selectable day of [period]. Only meaningful when [overlaps].
  DateTime clampedLastDay(Period period) {
    final last = this.last;
    final lastDay = period.lastDay;
    return last != null && lastDay.isAfter(last) ? last : lastDay;
  }

  @override
  bool operator ==(Object other) =>
      other is DateBounds &&
      other.first == first &&
      other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(first, endExclusive);

  static String _ymd(DateTime d) => '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
