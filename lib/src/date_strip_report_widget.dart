import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n_calendar_strip.dart';
import 'date_period.dart';
import 'date_strip_labels.dart';
import 'result_date.dart';

/// A report-period selector: tabs for month, quarter, half-year and year,
/// plus previous/next buttons to step through periods.
///
/// Every selection is reported through [onDateSelected] as a [ResultDate]
/// whose `fromDate`/`toDate` are inclusive calendar dates.
///
/// ## Date range
///
/// [startDate] is the first selectable day (inclusive) and [endDate] is the
/// first day that is **not** selectable (exclusive). Times of day are ignored
/// and either bound may be omitted. A period that only partially overlaps the
/// range is still selectable, but the reported dates are clamped to the range
/// and `ResultDate.isPartial` is `true`. Navigation never moves to a period
/// that has no selectable day.
class DateStripReport extends StatefulWidget {
  /// Creates a report-period selector.
  ///
  /// At least one of [isShowMonth], [isShowQuarter], [isShowHalfYear] and
  /// [isShowYear] must be `true`, and when both [startDate] and [endDate] are
  /// given, [startDate] must be before [endDate]. Violations throw an
  /// [ArgumentError] when the widget is built.
  const DateStripReport({
    super.key,
    this.onDateSelected,
    this.startDate,
    this.endDate,
    this.initialDate,
    this.initialDateType,
    this.rightIcon,
    this.leftIcon,
    this.isShowMonth = true,
    this.isShowQuarter = true,
    this.isShowHalfYear = true,
    this.isShowYear = true,
    this.navigationColor,
    this.navigationDisableColor,
    this.selectedColor,
    this.unSelectedColor,
    this.textColor,
    this.locale = LocaleType.en,
    this.labels,
  });

  /// Called with the selected period after the first frame, whenever the user
  /// changes the selection, and whenever a property change (range, locale,
  /// labels, visible tabs) changes the result.
  final ValueChanged<ResultDate>? onDateSelected;

  /// First selectable day (inclusive). `null` means no lower bound.
  final DateTime? startDate;

  /// First day after the selectable range (exclusive). `null` means no upper
  /// bound. For example `startDate: DateTime(2020)`, `endDate: DateTime(2021)`
  /// allows every day of 2020.
  final DateTime? endDate;

  /// The day whose period is selected initially, and again whenever the user
  /// switches tabs. Defaults to today. Clamped into the date range.
  ///
  /// Like `TextField.controller`'s initial text, changing it after the first
  /// build has no effect on the current selection.
  final DateTime? initialDate;

  /// The tab selected initially. Defaults to the first visible tab. Ignored
  /// when that tab is hidden.
  final DateType? initialDateType;

  /// Icon of the "next" button. Defaults to [Icons.arrow_forward_ios].
  final Icon? rightIcon;

  /// Icon of the "previous" button. Defaults to [Icons.arrow_back_ios].
  final Icon? leftIcon;

  /// Whether the month tab is shown.
  final bool isShowMonth;

  /// Whether the quarter tab is shown.
  final bool isShowQuarter;

  /// Whether the half-year tab is shown.
  final bool isShowHalfYear;

  /// Whether the year tab is shown.
  final bool isShowYear;

  /// Color of an enabled navigation icon.
  ///
  /// Defaults to [ColorScheme.onSurface].
  final Color? navigationColor;

  /// Color of a disabled navigation icon.
  ///
  /// Defaults to [ColorScheme.onSurface] at 38% opacity.
  final Color? navigationDisableColor;

  /// Fill of the selected tab, border of every tab and text of unselected tabs.
  ///
  /// Defaults to [ColorScheme.primary].
  final Color? selectedColor;

  /// Fill of unselected tabs and text of the selected tab.
  ///
  /// Defaults to [ColorScheme.surface].
  final Color? unSelectedColor;

  /// Color of the selected period's name.
  ///
  /// Defaults to [ColorScheme.onSurface].
  final Color? textColor;

  /// Built-in language used when [labels] is `null`.
  final LocaleType locale;

  /// Custom strings. Overrides [locale] when set.
  final DateStripLabels? labels;

  @override
  State<DateStripReport> createState() => DateStripReportState();
}

/// State of a [DateStripReport].
///
/// Most public members are kept only for compatibility with version 1.x and
/// are deprecated. Read [selectedResult] to get the current selection.
class DateStripReportState extends State<DateStripReport> {
  /// Creates the state. The optional arguments are ignored.
  DateStripReportState([
    @Deprecated('Ignored. The range is read from the widget.')
    DateTime? startDate,
    @Deprecated('Ignored. The range is read from the widget.')
    DateTime? endDate,
  ]);

  late DateBounds _bounds;
  late DateType _type;
  late DateTime _anchor;
  ResultDate? _lastReported;
  bool _reportScheduled = false;
  ArgumentError? _configError;

  List<DateType> get _visibleTypes => [
        if (widget.isShowMonth) DateType.month,
        if (widget.isShowQuarter) DateType.quarter,
        if (widget.isShowHalfYear) DateType.half,
        if (widget.isShowYear) DateType.year,
      ];

  DateStripLabels get _labels =>
      widget.labels ?? DateStripLabels.forLocale(widget.locale);

  Period get _period => Period.containing(_anchor, _type);

  bool get _canGoPrevious => _bounds.overlaps(_period.shift(-1));

  bool get _canGoNext => _bounds.overlaps(_period.shift(1));

  /// The period currently shown, with dates clamped to the range.
  ResultDate get selectedResult => _resultFor(_period);

  @override
  void initState() {
    super.initState();
    _configure(initial: true);
    _scheduleReport();
  }

  @override
  void didUpdateWidget(DateStripReport oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure(initial: false);
    // Range, locale, labels or visibility may have changed the result. The
    // parent is building right now, so report after this frame.
    _scheduleReport();
  }

  /// Validates the widget's configuration and updates bounds, type and
  /// anchor. A configuration error is rethrown from [build], so Flutter shows
  /// its error widget for this element only.
  void _configure({required bool initial}) {
    try {
      final bounds = DateBounds(widget.startDate, widget.endDate);
      final visibleTypes = _visibleTypes;
      if (visibleTypes.isEmpty) {
        throw ArgumentError(
          'DateStripReport needs at least one visible tab: isShowMonth, '
          'isShowQuarter, isShowHalfYear or isShowYear must be true.',
        );
      }
      final hadError = _configError != null;
      _configError = null;
      if (initial || hadError) {
        _bounds = bounds;
        _type = _defaultType();
        _anchor = _defaultAnchor();
        return;
      }
      if (bounds != _bounds) {
        _bounds = bounds;
        _anchor = _bounds.clamp(_anchor);
      }
      if (!visibleTypes.contains(_type)) _type = _defaultType();
    } on ArgumentError catch (error) {
      _configError = error;
      if (initial) {
        _bounds = DateBounds.unbounded;
        _type = DateType.month;
        _anchor = dateOnly(DateTime.now());
      }
    }
  }

  DateType _defaultType() {
    final visible = _visibleTypes;
    final requested = widget.initialDateType;
    return requested != null && visible.contains(requested)
        ? requested
        : visible.first;
  }

  DateTime _defaultAnchor() =>
      _bounds.clamp(widget.initialDate ?? DateTime.now());

  ResultDate _resultFor(Period period) {
    final from = _bounds.clampedStart(period);
    final to = _bounds.clampedLastDay(period);
    return ResultDate(
      fromDate: from,
      toDate: to,
      info: _periodName(period),
      dateType: period.type,
      isPartial: from != period.start || to != period.lastDay,
    );
  }

  String _periodName(Period period) {
    final labels = _labels;
    return switch (period.type) {
      DateType.month => labels.monthName(period.number),
      DateType.quarter => labels.quarterName(period.number),
      DateType.half => labels.halfName(period.number),
      DateType.year => labels.formatYear(period.start.year),
    };
  }

  String _tabTitle(DateType type) {
    final labels = _labels;
    return switch (type) {
      DateType.month => labels.monthly,
      DateType.quarter => labels.quarterly,
      DateType.half => labels.halfYearly,
      DateType.year => labels.yearly,
    };
  }

  /// Reports the selection after the current frame, unless it is unchanged.
  void _scheduleReport() {
    if (_reportScheduled) return;
    _reportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportScheduled = false;
      if (!mounted || _configError != null) return;
      final result = selectedResult;
      if (result != _lastReported) _report(result);
    });
  }

  void _report(ResultDate result) {
    _lastReported = result;
    widget.onDateSelected?.call(result);
  }

  void _selectType(DateType type) {
    setState(() {
      _type = type;
      _anchor = _defaultAnchor();
    });
    _report(selectedResult);
  }

  /// Moves the anchor by [months]; does nothing if the resulting period would
  /// have no selectable day.
  void _moveMonths(int months) {
    final target = DateTime(_anchor.year, _anchor.month + months);
    if (!_bounds.overlaps(Period.containing(target, _type))) return;
    setState(() => _anchor = _bounds.clamp(target));
    _report(selectedResult);
  }

  void _step(int direction) {
    final next = _period.shift(direction);
    if (!_bounds.overlaps(next)) return;
    setState(() => _anchor = _bounds.clamp(next.start));
    _report(selectedResult);
  }

  // ---------------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    final error = _configError;
    if (error != null) throw error;
    final colors = _ResolvedColors.of(context, widget);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final tabs = <Widget>[];
    for (final type in _visibleTypes) {
      if (tabs.isNotEmpty) tabs.add(const SizedBox(width: 16));
      tabs.add(_buildTab(colors, type, type == _type));
    }
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _step(rtl ? 1 : -1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _step(rtl ? -1 : 1),
      },
      child: FocusTraversalGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(children: tabs),
            const SizedBox(height: 16),
            _buildNavigator(colors, _period, _canGoPrevious, _canGoNext, _step),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(_ResolvedColors colors, DateType type, bool isSelected) {
    const radius = BorderRadius.all(Radius.circular(24));
    return Expanded(
      child: Semantics(
        container: true,
        button: true,
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? colors.selected : colors.unselected,
            borderRadius: radius,
            border: Border.all(color: colors.selected),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: () => _selectType(type),
              child: ConstrainedBox(
                // Minimum touch target recommended by Material and Android.
                constraints:
                    const BoxConstraints(minHeight: kMinInteractiveDimension),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Center(
                    // Keep the title on one line and shrink it when the tab
                    // is too narrow, instead of breaking inside a word.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _tabTitle(type),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.27,
                          color:
                              isSelected ? colors.unselected : colors.selected,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigator(
    _ResolvedColors colors,
    Period period,
    bool canGoPrevious,
    bool canGoNext,
    void Function(int direction) onStep,
  ) {
    final labels = _labels;
    final heading = period.type == DateType.year
        ? _tabTitle(DateType.year)
        : '${period.start.year}';
    final name = _periodName(period);
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(
              heading,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildArrow(
                colors,
                widget.leftIcon ?? const Icon(Icons.arrow_back_ios),
                labels.previousPeriod,
                canGoPrevious ? () => onStep(-1) : null,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Semantics(
                  liveRegion: true,
                  label: '$heading, $name',
                  child: ExcludeSemantics(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildArrow(
                colors,
                widget.rightIcon ?? const Icon(Icons.arrow_forward_ios),
                labels.nextPeriod,
                canGoNext ? () => onStep(1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrow(
    _ResolvedColors colors,
    Icon icon,
    String tooltip,
    VoidCallback? onPressed,
  ) =>
      IconButton(
        icon: icon,
        iconSize: 15,
        tooltip: tooltip,
        color: colors.navigation,
        disabledColor: colors.navigationDisabled,
        onPressed: onPressed,
      );

  // ---------------------------------------------------------------------------
  // Deprecated 1.x API. Kept so existing code keeps compiling.
  //
  // The names and semantics of runPresetsAndExceptions, isDateBefore,
  // isDateAfter, getDateOnly and nullOrDefault are adapted from calendar_strip
  // (https://github.com/IronLad85/flutter_calendar_strip), Copyright (c) 2019,
  // Siddharth V Sakre, BSD 3-Clause License. See THIRD_PARTY_NOTICES.md.

  /// Whether the "next" button is enabled.
  @Deprecated('Implementation detail; will be removed in 3.0.0.')
  bool get enbaleNext => _canGoNext;

  /// Whether the "previous" button is enabled.
  @Deprecated('Implementation detail; will be removed in 3.0.0.')
  bool get enbalePrevious => _canGoPrevious;

  /// Throws an [ArgumentError] if [startDate]/[endDate] form an empty range or
  /// [selectedDate] is outside it.
  @Deprecated('Validation now happens automatically; will be removed in 3.0.0.')
  void runPresetsAndExceptions(
    DateTime? selectedDate,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final bounds = DateBounds(startDate, endDate);
    if (selectedDate != null && !bounds.contains(selectedDate)) {
      throw ArgumentError.value(
        selectedDate,
        'selectedDate',
        'Selected date is out of range from start and end dates',
      );
    }
  }

  /// Whether the calendar date of [date1] is before that of [date2].
  @Deprecated('Use DateTime.isBefore; will be removed in 3.0.0.')
  bool isDateBefore(DateTime date1, DateTime date2) =>
      dateOnly(date1).isBefore(dateOnly(date2));

  /// Whether the calendar date of [date1] is on or after that of [date2].
  @Deprecated('Use DateTime.isBefore; will be removed in 3.0.0.')
  bool isDateAfter(DateTime date1, DateTime date2) =>
      !dateOnly(date1).isBefore(dateOnly(date2));

  /// [dateTimeObj] without its time of day.
  @Deprecated('Use DateUtils.dateOnly from Flutter; will be removed in 3.0.0.')
  DateTime getDateOnly(DateTime dateTimeObj) => dateOnly(dateTimeObj);

  /// [normalValue], or [defaultValue] when it is `null`.
  @Deprecated('Use the ?? operator; will be removed in 3.0.0.')
  Object? nullOrDefault(Object? normalValue, Object? defaultValue) =>
      normalValue ?? defaultValue;

  /// Reports the current selection to `onDateSelected` again.
  @Deprecated('Read selectedResult instead; will be removed in 3.0.0.')
  void setReturnDate() => _report(selectedResult);

  /// Moves the selection one month forward.
  @Deprecated('Will be removed in 3.0.0.')
  void getNextMonth() => _moveMonths(1);

  /// Moves the selection one month back.
  @Deprecated('Will be removed in 3.0.0.')
  void getPreviousMonth() => _moveMonths(-1);

  /// Moves the selection one quarter forward.
  @Deprecated('Will be removed in 3.0.0.')
  void getNextQuarter() => _moveMonths(3);

  /// Moves the selection one quarter back.
  @Deprecated('Will be removed in 3.0.0.')
  void getPreviousQuarter() => _moveMonths(-3);

  /// Moves the selection one half-year forward.
  @Deprecated('Will be removed in 3.0.0.')
  void getNextHalf() => _moveMonths(6);

  /// Moves the selection one half-year back.
  @Deprecated('Will be removed in 3.0.0.')
  void getPreviousHalf() => _moveMonths(-6);

  /// Moves the selection one year forward.
  @Deprecated('Will be removed in 3.0.0.')
  void getNextYear() => _moveMonths(12);

  /// Moves the selection one year back.
  @Deprecated('Will be removed in 3.0.0.')
  void getPreviousYear() => _moveMonths(-12);

  /// The navigator for the year containing the current selection.
  @Deprecated('Will be removed in 3.0.0.')
  Widget getYear() => _legacyNavigator(DateType.year);

  /// The navigator for the half-year containing the current selection.
  @Deprecated('Will be removed in 3.0.0.')
  Widget getHalf() => _legacyNavigator(DateType.half);

  /// The navigator for the quarter containing the current selection.
  @Deprecated('Will be removed in 3.0.0.')
  Widget getQuarter() => _legacyNavigator(DateType.quarter);

  /// The navigator for the month containing the current selection.
  @Deprecated('Will be removed in 3.0.0.')
  Widget getMonth() => _legacyNavigator(DateType.month);

  /// A tab button for [dateType].
  @Deprecated('Will be removed in 3.0.0.')
  Widget getRoundButton(DateType dateType, bool isSelected) =>
      _buildTab(_ResolvedColors.of(context, widget), dateType, isSelected);

  Widget _legacyNavigator(DateType type) {
    final period = Period.containing(_anchor, type);
    final span = monthSpanOf(type);
    return _buildNavigator(
      _ResolvedColors.of(context, widget),
      period,
      _bounds.overlaps(period.shift(-1)),
      _bounds.overlaps(period.shift(1)),
      (direction) => _moveMonths(direction * span),
    );
  }
}

/// Widget colors with theme defaults applied.
class _ResolvedColors {
  _ResolvedColors.of(BuildContext context, DateStripReport widget)
      : this._(Theme.of(context).colorScheme, widget);

  _ResolvedColors._(ColorScheme scheme, DateStripReport widget)
      : selected = widget.selectedColor ?? scheme.primary,
        unselected = widget.unSelectedColor ?? scheme.surface,
        text = widget.textColor ?? scheme.onSurface,
        navigation = widget.navigationColor ?? scheme.onSurface,
        // 0x61 = 38% opacity, Material's disabled emphasis.
        navigationDisabled =
            widget.navigationDisableColor ?? scheme.onSurface.withAlpha(0x61);

  final Color selected;
  final Color unselected;
  final Color text;
  final Color navigation;
  final Color navigationDisabled;
}
