import 'package:flutter/foundation.dart';

/// The granularity of a report period.
enum DateType {
  /// A calendar month.
  month,

  /// A calendar quarter: January–March, April–June, July–September or
  /// October–December.
  quarter,

  /// A calendar half-year: January–June or July–December.
  half,

  /// A calendar year.
  year,
}

/// The period currently selected in a `DateStripReport`.
///
/// [fromDate] and [toDate] are **inclusive** calendar dates at local midnight.
/// When a date range is configured, both are clamped to that range, so they
/// never fall outside it; [isPartial] tells you when clamping happened.
@immutable
class ResultDate {
  /// Creates a result for the period [fromDate]–[toDate] (inclusive).
  const ResultDate({
    required this.fromDate,
    required this.toDate,
    required this.info,
    required this.dateType,
    this.isPartial = false,
  });

  /// First day of the selected period (inclusive), at local midnight.
  final DateTime fromDate;

  /// Last day of the selected period (inclusive), at local midnight.
  ///
  /// Records with a time-of-day on this date are *after* this instant. When
  /// filtering timestamps, compare against [toDateExclusive] instead.
  final DateTime toDate;

  /// Human-readable label of the period, for example `November`,
  /// `Quarter 4` or `2026`, in the widget's locale.
  final String info;

  /// Granularity of the selected period.
  final DateType dateType;

  /// Whether the calendar period extends beyond the configured date range and
  /// [fromDate] and/or [toDate] were clamped to it.
  final bool isPartial;

  /// The day after [toDate], at local midnight.
  ///
  /// Use it for half-open queries such as
  /// `timestamp >= fromDate && timestamp < toDateExclusive`.
  DateTime get toDateExclusive =>
      DateTime(toDate.year, toDate.month, toDate.day + 1);

  @override
  bool operator ==(Object other) =>
      other is ResultDate &&
      other.fromDate == fromDate &&
      other.toDate == toDate &&
      other.info == info &&
      other.dateType == dateType &&
      other.isPartial == isPartial;

  @override
  int get hashCode => Object.hash(fromDate, toDate, info, dateType, isPartial);

  @override
  String toString() => 'ResultDate(${dateType.name}: '
      '${_ymd(fromDate)}..${_ymd(toDate)}, "$info"'
      '${isPartial ? ', partial' : ''})';

  static String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
