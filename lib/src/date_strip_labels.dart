import 'package:flutter/foundation.dart';

import '../i18n_calendar_strip.dart';

/// Every user-visible string shown by `DateStripReport`.
///
/// Use [DateStripLabels.forLocale] for the built-in translations, or build
/// your own to translate the widget into any language:
///
/// ```dart
/// DateStripReport(
///   labels: DateStripLabels.forLocale(LocaleType.fr).copyWith(
///     monthly: 'Mensuel',
///     quarterly: 'Trimestriel',
///     halfYearly: 'Semestriel',
///     yearly: 'Annuel',
///     quarters: ['T1', 'T2', 'T3', 'T4'],
///     halves: ['S1', 'S2'],
///     previousPeriod: 'Période précédente',
///     nextPeriod: 'Période suivante',
///   ),
///   onDateSelected: print,
/// )
/// ```
@immutable
class DateStripLabels {
  /// Creates a full set of labels.
  ///
  /// [months] must have 12 entries, [quarters] 4 and [halves] 2. A list of the
  /// wrong length falls back to [english] for that list. [yearPattern] must
  /// contain `{year}`, which is replaced by the four-digit year.
  const DateStripLabels({
    required this.monthly,
    required this.quarterly,
    required this.halfYearly,
    required this.yearly,
    required this.months,
    required this.quarters,
    required this.halves,
    this.yearPattern = '{year}',
    this.previousPeriod = 'Previous period',
    this.nextPeriod = 'Next period',
  });

  /// The built-in labels for [locale].
  ///
  /// Any entry missing from that locale's table falls back to [english], so
  /// this never returns `null` or empty strings. Period labels are translated
  /// for English, Vietnamese, Chinese, Japanese and Korean; other locales get
  /// their month names plus English period labels.
  factory DateStripLabels.forLocale(LocaleType locale) {
    if (locale == LocaleType.en) return english;
    final table = i18nObjInLocale(locale) ?? const <String, Object>{};

    String text(String key, String fallback) {
      final value = table[key];
      return value is String && value.isNotEmpty ? value : fallback;
    }

    List<String> list(String key, List<String> fallback) {
      final value = table[key];
      if (value is List<String> && value.length == fallback.length) {
        return List<String>.unmodifiable(value);
      }
      return fallback;
    }

    return DateStripLabels(
      monthly: text('monthly', english.monthly),
      quarterly: text('quarterly', english.quarterly),
      halfYearly: text('halfYearly', english.halfYearly),
      yearly: text('yearly', english.yearly),
      months: list('periodMonth', list('monthLong', english.months)),
      quarters: list('quarter', english.quarters),
      halves: list('halfYear', english.halves),
      yearPattern: text('yearPattern', english.yearPattern),
      previousPeriod: text('previousPeriod', english.previousPeriod),
      nextPeriod: text('nextPeriod', english.nextPeriod),
    );
  }

  /// The default English labels.
  static const DateStripLabels english = DateStripLabels(
    monthly: 'Monthly',
    quarterly: 'Quarterly',
    halfYearly: 'Half Year',
    yearly: 'Yearly',
    months: [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ],
    quarters: ['Quarter 1', 'Quarter 2', 'Quarter 3', 'Quarter 4'],
    halves: ['First half', 'Second half'],
  );

  /// Title of the month tab.
  final String monthly;

  /// Title of the quarter tab.
  final String quarterly;

  /// Title of the half-year tab.
  final String halfYearly;

  /// Title of the year tab.
  final String yearly;

  /// Month names, January first (12 entries).
  final List<String> months;

  /// Quarter names, Q1 first (4 entries).
  final List<String> quarters;

  /// Half-year names, January–June first (2 entries).
  final List<String> halves;

  /// How a year is written, with `{year}` as placeholder, e.g. `{year}年`.
  final String yearPattern;

  /// Tooltip and screen-reader label of the "previous" button.
  final String previousPeriod;

  /// Tooltip and screen-reader label of the "next" button.
  final String nextPeriod;

  /// Name of [month] (1–12).
  String monthName(int month) => _pick(months, english.months, month);

  /// Name of [quarter] (1–4).
  String quarterName(int quarter) => _pick(quarters, english.quarters, quarter);

  /// Name of half-year [half] (1–2).
  String halfName(int half) => _pick(halves, english.halves, half);

  /// [year] formatted with [yearPattern].
  String formatYear(int year) => yearPattern.contains('{year}')
      ? yearPattern.replaceAll('{year}', '$year')
      : '$year';

  static String _pick(List<String> values, List<String> fallback, int n) =>
      values.length == fallback.length ? values[n - 1] : fallback[n - 1];

  /// Returns a copy with the given fields replaced.
  DateStripLabels copyWith({
    String? monthly,
    String? quarterly,
    String? halfYearly,
    String? yearly,
    List<String>? months,
    List<String>? quarters,
    List<String>? halves,
    String? yearPattern,
    String? previousPeriod,
    String? nextPeriod,
  }) =>
      DateStripLabels(
        monthly: monthly ?? this.monthly,
        quarterly: quarterly ?? this.quarterly,
        halfYearly: halfYearly ?? this.halfYearly,
        yearly: yearly ?? this.yearly,
        months: months ?? this.months,
        quarters: quarters ?? this.quarters,
        halves: halves ?? this.halves,
        yearPattern: yearPattern ?? this.yearPattern,
        previousPeriod: previousPeriod ?? this.previousPeriod,
        nextPeriod: nextPeriod ?? this.nextPeriod,
      );

  @override
  bool operator ==(Object other) =>
      other is DateStripLabels &&
      other.monthly == monthly &&
      other.quarterly == quarterly &&
      other.halfYearly == halfYearly &&
      other.yearly == yearly &&
      listEquals(other.months, months) &&
      listEquals(other.quarters, quarters) &&
      listEquals(other.halves, halves) &&
      other.yearPattern == yearPattern &&
      other.previousPeriod == previousPeriod &&
      other.nextPeriod == nextPeriod;

  @override
  int get hashCode => Object.hash(
        monthly,
        quarterly,
        halfYearly,
        yearly,
        Object.hashAll(months),
        Object.hashAll(quarters),
        Object.hashAll(halves),
        yearPattern,
        previousPeriod,
        nextPeriod,
      );
}
