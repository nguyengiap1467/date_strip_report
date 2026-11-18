import 'package:date_strip_report/i18n_calendar_strip.dart';
import 'package:date_strip_report/src/date_strip_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateStripLabels.forLocale', () {
    test('every locale yields a complete, non-empty label set', () {
      for (final locale in LocaleType.values) {
        final l = DateStripLabels.forLocale(locale);
        final strings = [
          l.monthly,
          l.quarterly,
          l.halfYearly,
          l.yearly,
          l.previousPeriod,
          l.nextPeriod,
          for (var m = 1; m <= 12; m++) l.monthName(m),
          for (var q = 1; q <= 4; q++) l.quarterName(q),
          for (var h = 1; h <= 2; h++) l.halfName(h),
          l.formatYear(2026),
        ];
        for (final s in strings) {
          expect(s, isNotEmpty, reason: '$locale');
          expect(s, isNot('null'), reason: '$locale');
        }
        expect(l.formatYear(2026), contains('2026'), reason: '$locale');
      }
    });

    test('English (P9: no "Quarter 4st" / "Half year 2st")', () {
      final l = DateStripLabels.forLocale(LocaleType.en);
      expect(l, DateStripLabels.english);
      expect(l.quarterName(4), 'Quarter 4');
      expect(l.halfName(2), 'Second half');
      expect(l.monthName(11), 'November');
      expect(l.formatYear(2026), '2026');
    });

    test('Vietnamese keeps its existing translations', () {
      final l = DateStripLabels.forLocale(LocaleType.vi);
      expect(
        [l.monthly, l.quarterly, l.halfYearly, l.yearly],
        ['Tháng', 'Quý', 'Nửa năm', 'Năm'],
      );
      expect(l.monthName(11), 'Tháng 11');
      expect(l.quarterName(4), 'Quý 4');
      expect(l.halfName(1), 'Nửa đầu năm');
    });

    test('Chinese, Japanese and Korean (P5: tabs are no longer "日"/"일")', () {
      final zh = DateStripLabels.forLocale(LocaleType.zh);
      expect(
        [zh.monthly, zh.quarterly, zh.halfYearly, zh.yearly],
        ['月度', '季度', '半年度', '年度'],
      );
      expect(zh.monthName(11), '11月');
      expect(zh.quarterName(1), '第一季度');
      expect(zh.formatYear(2026), '2026年');

      final ja = DateStripLabels.forLocale(LocaleType.jp);
      expect(
        [ja.monthly, ja.quarterly, ja.halfYearly, ja.yearly],
        ['月次', '四半期', '半期', '年次'],
      );
      expect(ja.monthName(11), '11月');
      expect(ja.halfName(2), '下半期');
      expect(ja.formatYear(2026), '2026年');

      final ko = DateStripLabels.forLocale(LocaleType.ko);
      expect(
        [ko.monthly, ko.quarterly, ko.halfYearly, ko.yearly],
        ['월별', '분기별', '반기별', '연도별'],
      );
      expect(ko.monthName(11), '11월');
      expect(ko.quarterName(3), '3분기');
      expect(ko.formatYear(2026), '2026년');
    });

    test('locales without period labels fall back to English (P4)', () {
      final fr = DateStripLabels.forLocale(LocaleType.fr);
      expect(fr.monthly, 'Monthly');
      expect(fr.quarterName(2), 'Quarter 2');
      expect(fr.halfName(1), 'First half');
      // Month names still come from the French table.
      expect(fr.monthName(11), isNot('November'));
    });
  });

  group('custom labels', () {
    test('copyWith replaces only the given fields', () {
      final l = DateStripLabels.english.copyWith(monthly: 'Mensuel');
      expect(l.monthly, 'Mensuel');
      expect(l.quarterly, 'Quarterly');
      expect(l, isNot(DateStripLabels.english));
    });

    test('lists of the wrong length fall back to English', () {
      final l = DateStripLabels.english.copyWith(
        months: ['only one'],
        quarters: ['Q1', 'Q2'],
        halves: ['H1', 'H2'],
      );
      expect(l.monthName(3), 'March');
      expect(l.quarterName(2), 'Quarter 2');
      expect(l.halfName(2), 'H2');
    });

    test('yearPattern without placeholder falls back to the plain year', () {
      final l = DateStripLabels.english.copyWith(yearPattern: 'FY');
      expect(l.formatYear(2026), '2026');
      expect(
        DateStripLabels.english
            .copyWith(yearPattern: 'FY{year}')
            .formatYear(26),
        'FY26',
      );
    });
  });
}
