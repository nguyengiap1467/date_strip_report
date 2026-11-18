import 'package:date_strip_report/date_strip_report.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DemoApp());

/// Demo application for `date_strip_report`.
class DemoApp extends StatefulWidget {
  /// Creates the demo app.
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    const seed = Colors.indigo;
    return MaterialApp(
      title: 'date_strip_report demo',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: DemoPage(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: () => setState(() {
          _themeMode =
              _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        }),
      ),
    );
  }
}

/// The single demo screen: the widget, its current result and options.
class DemoPage extends StatefulWidget {
  /// Creates the demo screen.
  const DemoPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  /// Whether the dark theme is active.
  final bool isDark;

  /// Switches between light and dark theme.
  final VoidCallback onToggleTheme;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  static const _locales = {
    LocaleType.en: 'English',
    LocaleType.vi: 'Tiếng Việt',
    LocaleType.zh: '中文',
    LocaleType.jp: '日本語',
    LocaleType.ko: '한국어',
    LocaleType.de: 'Deutsch',
  };

  /// Inclusive start and exclusive end of the optional demo range.
  static final _rangeStart = DateTime(2024, 3, 15);
  static final _rangeEnd = DateTime(2026, 10, 20);

  static final _frenchLabels =
      DateStripLabels.forLocale(LocaleType.fr).copyWith(
    monthly: 'Mensuel',
    quarterly: 'Trimestriel',
    halfYearly: 'Semestriel',
    yearly: 'Annuel',
    quarters: ['1er trimestre', '2e trimestre', '3e trimestre', '4e trimestre'],
    halves: ['1er semestre', '2nd semestre'],
    previousPeriod: 'Période précédente',
    nextPeriod: 'Période suivante',
  );

  final Set<DateType> _visible = DateType.values.toSet();
  LocaleType _locale = LocaleType.en;
  bool _limitRange = false;
  bool _classicColors = false;
  bool _customLabels = false;
  ResultDate? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('date_strip_report'),
        actions: [
          IconButton(
            tooltip: widget.isDark ? 'Light theme' : 'Dark theme',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          // Not a ListView: lazy building would dispose the strip (and its
          // selection) when it scrolls out of view.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildStrip(),
                  ),
                ),
                const SizedBox(height: 12),
                _ResultCard(result: _result),
                const SizedBox(height: 12),
                _buildOptions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrip() {
    return DateStripReport(
      isShowMonth: _visible.contains(DateType.month),
      isShowQuarter: _visible.contains(DateType.quarter),
      isShowHalfYear: _visible.contains(DateType.half),
      isShowYear: _visible.contains(DateType.year),
      startDate: _limitRange ? _rangeStart : null,
      endDate: _limitRange ? _rangeEnd : null,
      locale: _locale,
      labels: _customLabels ? _frenchLabels : null,
      // The look of version 1.x; leave these out to follow the app theme.
      selectedColor: _classicColors ? Colors.green : null,
      unSelectedColor: _classicColors ? Colors.white : null,
      textColor: _classicColors ? Colors.green : null,
      navigationColor: _classicColors ? Colors.black : null,
      navigationDisableColor: _classicColors ? Colors.black12 : null,
      onDateSelected: (result) => setState(() => _result = result),
    );
  }

  Widget _buildOptions(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const tabNames = {
      DateType.month: 'Month',
      DateType.quarter: 'Quarter',
      DateType.half: 'Half-year',
      DateType.year: 'Year',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Visible tabs', style: textTheme.titleSmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final type in DateType.values)
                    FilterChip(
                      label: Text(tabNames[type]!),
                      selected: _visible.contains(type),
                      // At least one tab must stay visible.
                      onSelected: _visible.length == 1 &&
                              _visible.contains(type)
                          ? null
                          : (on) => setState(() {
                                on ? _visible.add(type) : _visible.remove(type);
                              }),
                    ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Language'),
              subtitle: const Text(
                'German has month names only; its period labels '
                'fall back to English.',
              ),
              trailing: DropdownButton<LocaleType>(
                value: _locale,
                onChanged: _customLabels
                    ? null
                    : (value) => setState(() => _locale = value!),
                items: [
                  for (final entry in _locales.entries)
                    DropdownMenuItem(
                        value: entry.key, child: Text(entry.value)),
                ],
              ),
            ),
            SwitchListTile(
              title: const Text('Custom labels'),
              subtitle: const Text('French strings via DateStripLabels'),
              value: _customLabels,
              onChanged: (on) => setState(() => _customLabels = on),
            ),
            SwitchListTile(
              title: const Text('Limit to a date range'),
              subtitle: Text(
                '${_formatDate(_rangeStart)} (inclusive) to '
                '${_formatDate(_rangeEnd)} (exclusive)',
              ),
              value: _limitRange,
              onChanged: (on) => setState(() => _limitRange = on),
            ),
            SwitchListTile(
              title: const Text('Classic 1.x colors'),
              subtitle: const Text('Explicit colors instead of the theme'),
              value: _classicColors,
              onChanged: (on) => setState(() => _classicColors = on),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ResultDate? result;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: result == null
            ? const Text('Waiting for the first selection…')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'onDateSelected',
                          style: textTheme.titleSmall,
                        ),
                      ),
                      if (result.isPartial)
                        const Chip(
                          label: Text('partial'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _row(context, 'info', result.info),
                  _row(context, 'dateType', result.dateType.name),
                  _row(context, 'fromDate', _formatDate(result.fromDate)),
                  _row(context, 'toDate', _formatDate(result.toDate)),
                  _row(
                    context,
                    'toDateExclusive',
                    _formatDate(result.toDateExclusive),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _row(BuildContext context, String name, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(
                name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

String _formatDate(DateTime d) => '${d.year}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
