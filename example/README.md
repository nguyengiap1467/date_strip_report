# date_strip_report example

A demo of every `DateStripReport` feature:

- month / quarter / half-year / year tabs, each of which can be hidden;
- an optional date range, showing how partially overlapping periods are
  clamped (`ResultDate.isPartial`);
- built-in languages (English, Vietnamese, Chinese, Japanese, Korean) and the
  English fallback for other locales;
- custom labels with `DateStripLabels` (a French example);
- theme-derived colors in light and dark mode, or the explicit 1.x colors;
- the `ResultDate` reported through `onDateSelected`.

## Run

```sh
cd example
flutter pub get
flutter run            # pick an Android/iOS device or simulator
flutter run -d chrome  # web
```

## Test

```sh
flutter test
```
