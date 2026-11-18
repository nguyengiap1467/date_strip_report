// Derived from calendar_strip (https://github.com/IronLad85/flutter_calendar_strip)
// Copyright (c) 2019, Siddharth V Sakre. Licensed under the BSD 3-Clause
// License. See THIRD_PARTY_NOTICES.md for the full license text.
//
// Changes: documentation, deprecation, and getLastDayOfMonth uses calendar
// arithmetic instead of subtracting a Duration (wrong where DST changes at
// midnight).

// The file name is kept for backwards compatibility.
// ignore_for_file: file_names

/// Calendar helpers inherited from 1.x. Not used by `DateStripReport`.
///
/// This class is not exported by `package:date_strip_report/date_strip_report.dart`
/// and its name clashes with Flutter's own `DateUtils` from
/// `package:flutter/material.dart`.
@Deprecated(
  "Use Flutter's DateUtils (package:flutter/material.dart) or DateTime. "
  'Will be removed in 3.0.0.',
)
class DateUtils {
  /// [dateTime] without its time of day.
  static DateTime toMidnight(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Whether [date] is a Saturday or Sunday.
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Whether [date] is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }

  /// Whether [date] is before today.
  static bool isPastDay(DateTime date) {
    final today = toMidnight(DateTime.now());
    return date.isBefore(today);
  }

  /// Adds [days] to [date], compensating up to 3 hours of DST shift.
  static DateTime addDaysToDate(DateTime date, int days) {
    DateTime newDate = date.add(Duration(days: days));

    if (date.hour != newDate.hour) {
      final hoursDifference = date.hour - newDate.hour;

      if (hoursDifference <= 3 && hoursDifference >= -3) {
        newDate = newDate.add(Duration(hours: hoursDifference));
      } else if (hoursDifference <= -21) {
        newDate = newDate.add(Duration(hours: 24 + hoursDifference));
      } else if (hoursDifference >= 21) {
        newDate = newDate.add(Duration(hours: hoursDifference - 24));
      }
    }
    return newDate;
  }

  /// Whether [date] is before today, or today after noon.
  static bool isSpecialPastDay(DateTime date) {
    return isPastDay(date) || (isToday(date) && DateTime.now().hour >= 12);
  }

  /// First day of the current month.
  static DateTime getFirstDayOfCurrentMonth() {
    var dateTime = DateTime.now();
    dateTime = getFirstDayOfMonth(dateTime);
    return dateTime;
  }

  /// First day of next month.
  static DateTime getFirstDayOfNextMonth() {
    var dateTime = getFirstDayOfCurrentMonth();
    dateTime = addDaysToDate(dateTime, 31);
    dateTime = getFirstDayOfMonth(dateTime);
    return dateTime;
  }

  /// Last day of the current month.
  static DateTime getLastDayOfCurrentMonth() {
    return getLastDayOfMonth(DateTime.now());
  }

  /// Last day of next month.
  static DateTime getLastDayOfNextMonth() {
    return getLastDayOfMonth(getFirstDayOfNextMonth());
  }

  /// The first day of the month [months] months after [fromMonth].
  static DateTime addMonths(DateTime fromMonth, int months) {
    DateTime firstDayOfCurrentMonth = fromMonth;
    for (int i = 0; i < months; i++) {
      firstDayOfCurrentMonth =
          getLastDayOfMonth(firstDayOfCurrentMonth).add(Duration(days: 1));
    }

    return firstDayOfCurrentMonth;
  }

  /// First day of the month containing [month].
  static DateTime getFirstDayOfMonth(DateTime month) {
    return DateTime(month.year, month.month);
  }

  /// Last day of the month containing [month].
  static DateTime getLastDayOfMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0);
  }

  /// Whether [date1] and [date2] are the same calendar day.
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.day == date2.day &&
        date1.month == date2.month &&
        date1.year == date2.year;
  }

  /// Whether [date] is in the current month.
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.month == now.month && date.year == now.year;
  }

  /// The largest number of calendar rows (weeks starting on Monday) any month between [startDate] and [endDate] needs.
  static int calculateMaxWeeksNumberMonthly(
    DateTime startDate,
    DateTime endDate,
  ) {
    final int monthsNumber = calculateMonthsDifference(startDate, endDate);

    final List<int> weeksNumbersMonthly = <int>[];

    if (monthsNumber == 0) {
      return calculateWeeksNumber(startDate, endDate);
    } else {
      weeksNumbersMonthly
          .add(calculateWeeksNumber(startDate, getLastDayOfMonth(startDate)));

      DateTime firstDateOfMonth = getFirstDayOfMonth(startDate);
      for (int i = 1; i <= monthsNumber - 2; i++) {
        firstDateOfMonth = firstDateOfMonth.add(Duration(days: 31));
        weeksNumbersMonthly.add(
          calculateWeeksNumber(
            firstDateOfMonth,
            getLastDayOfMonth(firstDateOfMonth),
          ),
        );
      }

      weeksNumbersMonthly
          .add(calculateWeeksNumber(getFirstDayOfMonth(endDate), endDate));

      weeksNumbersMonthly.sort((a, b) => b.compareTo(a));
      return weeksNumbersMonthly[0];
    }
  }

  /// Number of month boundaries between [startDate] and [endDate].
  static int calculateMonthsDifference(DateTime startDate, DateTime endDate) {
    final yearsDifference = endDate.year - startDate.year;
    return 12 * yearsDifference + endDate.month - startDate.month;
  }

  /// Number of weeks (starting on Monday) spanned by [monthStartDate]..[monthEndDate].
  static int calculateWeeksNumber(
    DateTime monthStartDate,
    DateTime monthEndDate,
  ) {
    int rowsNumber = 1;

    DateTime currentDay = monthStartDate;
    while (currentDay.isBefore(monthEndDate)) {
      currentDay = currentDay.add(Duration(days: 1));
      if (currentDay.weekday == DateTime.monday) {
        rowsNumber += 1;
      }
    }

    return rowsNumber;
  }
}
