// Renders README screenshots of the demo app with real fonts.
//
// Not part of the regular test run (it lives outside test/). Regenerate with:
//
//   cd example
//   flutter test screenshots/screenshots_test.dart --update-goldens
//
// The images are written to ../images/. They show the current date, and
// font rasterization differs slightly between machines, so do not use them
// as golden tests.

import 'dart:io';

import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flutter SDK root, derived from the flutter_tester executable path
/// (`<sdk>/bin/cache/artifacts/engine/<platform>/flutter_tester`).
String get _flutterRoot =>
    Platform.environment['FLUTTER_ROOT'] ??
    File(Platform.resolvedExecutable)
        .parent
        .parent
        .parent
        .parent
        .parent
        .parent
        .path;

Future<void> _loadFonts() async {
  final fonts = '$_flutterRoot/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('$fonts/$name').readAsBytes());

  final roboto = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    roboto.addFont(read('Roboto-$weight.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')
        ..addFont(read('MaterialIcons-Regular.otf')))
      .load();
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(DemoApp),
    matchesGoldenFile('../../images/$name.png'),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Pumps the demo and waits for the first onDateSelected, which fills the
/// result card and changes the page height.
Future<void> _pumpDemo(WidgetTester tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.pumpAndSettle();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(Card).first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first
      ..physicalSize = const Size(390 * 2, 760 * 2)
      ..devicePixelRatio = 2;
  });

  testWidgets('monthly, light theme', (tester) async {
    await _pumpDemo(tester);
    await _capture(tester, 'v2_monthly_light');
  });

  testWidgets('quarter clamped to a date range', (tester) async {
    await _pumpDemo(tester);
    await _tapVisible(tester, find.text('Limit to a date range'));
    await _scrollToTop(tester);
    await tester.tap(find.text('Quarterly'));
    await _capture(tester, 'v2_quarter_range');
  });

  testWidgets('Vietnamese, dark theme', (tester) async {
    await _pumpDemo(tester);
    await tester.tap(find.byTooltip('Dark theme'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('English'));
    await tester.tap(find.text('Tiếng Việt').last);
    await tester.pumpAndSettle();
    await _scrollToTop(tester);
    await tester.tap(find.text('Nửa năm'));
    await _capture(tester, 'v2_half_vi_dark');
  });

  testWidgets('classic 1.x colors', (tester) async {
    await _pumpDemo(tester);
    await _tapVisible(tester, find.text('Classic 1.x colors'));
    final tile = find.widgetWithText(SwitchListTile, 'Classic 1.x colors');
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    await _scrollToTop(tester);
    await tester.tap(find.text('Yearly').first);
    await _capture(tester, 'v2_year_classic');
  });
}
