# Changelog

All notable changes to this package are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package uses
[Semantic Versioning](https://semver.org/).

## 2.0.0 — unreleased

A modernization release: Dart 3, no third-party dependencies, crash fixes,
a defined date-range contract, theming and accessibility. See
[Migrating from 1.x](README.md#migrating-from-1x) for upgrade steps.

### Breaking changes

- Requires Dart 3.4 / Flutter 3.22 or newer.
- `onDateSelected` is typed `ValueChanged<ResultDate>?` (was `Function?`).
- `ResultDate` is immutable: fields are `final` and non-null, and the
  constructor takes named, required arguments.
- The first `onDateSelected` call happens after the first frame (it used to
  run synchronously inside `initState`).
- Reported dates are clamped to `startDate`/`endDate`; a range that excludes
  today no longer throws, the initial selection is moved into the range.
- Invalid configuration (empty/inverted range, every tab hidden) throws
  `ArgumentError` from `build`.
- Default colors follow the app's `ColorScheme`; the five color properties
  are typed `Color?`.
- Tabs are at least 48 dp tall; the navigation arrows are 48×48 `IconButton`s.
- English labels changed from "Quarter 1st" / "Half year 1st" to
  "Quarter 1" / "First half"; Chinese, Japanese and Korean labels were
  replaced (see Fixed).

### Fixed

- Crash when `startDate`/`endDate` were omitted.
- Crash when `onDateSelected` was omitted.
- Crash when today was outside the range (the 1.x example app's own setup).
- 27 of 29 locales showed "null" tab titles and crashed on the quarter and
  half-year tabs; missing labels now fall back to English.
- Chinese and Korean tab titles all read "日"/"일" ("day"); years read
  "年 2026" instead of "2026年".
- Calling `setState` in a parent from `onDateSelected` caused a framework
  assertion.
- `leftIcon` and `rightIcon` were ignored.
- Navigation could move outside the range and report out-of-range dates.
- `isShowMonth: false` still opened the hidden month view.
- Tab titles could break inside a word ("Quarterl/y") on narrow layouts.
- `jiffy` was imported by the library but declared only as a dev
  dependency.
- `SlideFadeTransition` could call `forward()` on a disposed controller.
- Month ends no longer use `Duration` arithmetic, which was wrong in time
  zones where daylight saving changes at midnight.

### Added

- `DateStripLabels`: custom labels for any language, with
  `DateStripLabels.forLocale` and `copyWith`.
- `initialDate`, `initialDateType`, `labels` and `key` parameters.
- `ResultDate.dateType`, `ResultDate.isPartial`, `ResultDate.toDateExclusive`,
  value equality and `toString`.
- `DateStripReportState.selectedResult`.
- Either range bound may be omitted.
- Range, locale, labels and tab visibility can change at runtime.
- Screen-reader semantics, tooltips, live-region announcements, keyboard
  navigation (Tab, Enter/Space, Left/Right arrows, RTL-aware).
- Translations of period labels for Chinese, Japanese and Korean, and of the
  navigation tooltips for English, Vietnamese, Chinese, Japanese and Korean.
- Unit and widget tests, GitHub Actions CI, and a rebuilt example app for
  Android, iOS and web.
- `THIRD_PARTY_NOTICES.md` with the licenses of code derived from
  `calendar_strip` (BSD-3-Clause) and `flutter_datetime_picker` (MIT).

### Deprecated

- `SlideFadeTransition`, `DateUtils` (`date-utils.dart`) and the public
  helper methods on `DateStripReportState` (`getNextMonth`, `isDateBefore`,
  `enbaleNext`, …). They still work and will be removed in 3.0.0.

### Removed

- The `jiffy` dependency.

## 1.2.0 — 2022-12-22 (not published to pub.dev)

- Null-safety migration, available in the repository only.

## 1.0.1 — 2020-05-07

- No release notes were recorded.

## 1.0.0 — 2020-05-07

- Initial release.
