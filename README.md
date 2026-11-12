# ציונים · flatter_exam_1

A student grades app for Android & iPhone, built with Flutter — in Hebrew, right-to-left, with an Apple-style design.

![CI](https://img.shields.io/badge/CI-flutter-blue) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

## Features

| Feature | Details |
|---|---|
| 📊 Class average | Glass tile at the top; the number counts smoothly to its new value. |
| 🟢 Pass ring | Shows how many students passed, e.g. 2 / 4 (passing grade: 55). |
| 👤 Student rows | Name, ✓ pass / ✗ fail status, a grade bar, and the grade. |
| ➕ Grade stepper | iOS-style − \| + changes a grade by 1, always kept between 0 and 100. |
| ↕️ Sort by grade | Rows slide to their new place; tap again to reverse the order. |
| 📳 Haptics | A light tick on every change, a stronger one when a student crosses the pass line. |
| 🌗 Light & dark mode | Follows the phone's setting automatically. |
| ♿ Accessibility | Screen-reader labels, Reduce Motion and Increase Contrast are respected. |

## Design

The UI follows Apple's design principles, built only with Flutter's own widgets — no extra packages.

- **Materials** — frosted "glass" cards (`BackdropFilter` blur + translucent fill + a bright hairline edge). They turn solid when Increase Contrast is on.
- **Typography** — a large title with tight tracking; tabular figures so numbers don't shift while they change.
- **Color** — Apple system colors (green / red / blue) with separate light and dark values.
- **Motion** — non-bouncy easing; rows animate from where they are when the list is sorted.
- **Touch targets** — stepper halves are 44pt tall, Apple's minimum comfortable size.
- **RTL** — the whole app is right-to-left; fractions like `2 / 4` stay left-to-right.

## Getting started

Requirements: Flutter 3.27 (stable) or newer. For iPhone builds: macOS with Xcode.

This bundle ships the app's source only (`lib/`, `test/`, project config). It doesn't include the generated `android/`, `ios/`, `macos/`, `linux/`, `windows/` or `web/` platform folders — generate those once, locally, with:

```
git clone https://github.com/<your-username>/flatter_exam_1.git
cd flatter_exam_1
flutter create --platforms=android,ios .
flutter pub get
flutter run            # pick an Android emulator, iPhone simulator, or device
```

## Testing

```
flutter analyze        # static analysis
flutter test            # unit + widget tests
```

The tests cover the grade logic (limits 0–100, pass/fail line, average, sorting) and the screen (average and pass count, +/- buttons, the 0 limit, and sorting). They also run automatically on GitHub for every push (CI workflow).

## Project structure

```
lib/
└── main.dart              # The whole app, with a comment on every class and function:
                           #   constants → app & theme → colors (Palette) → Student model
                           #   → GradesScreen → glass card / pressable → header, cards, rows
test/
└── widget_test.dart       # Unit and widget tests
.github/workflows/ci.yml   # Format, analyze and test on every push
```

## Code decisions

- **Immutable data** — `Student` never changes; `changeGrade()` returns a new student, and the list entry is replaced, not edited.
- **Simple state** — one `StatefulWidget` with `setState`, no state-management package.
- **Pure helpers** — `averageGrade()`, `passedCount()` and `sortByGrade()` are plain functions, easy to test on their own.

## בעברית

אפליקציית ציונים ב-Flutter לאנדרואיד ולאייפון, בעברית ומימין לשמאל, בעיצוב בסגנון אפל. האפליקציה מציגה את ממוצע הכיתה, כמה תלמידים עברו (ציון עובר: 55), ואת הציון של כל תלמיד. אפשר לשנות ציון עם כפתורי − / +, ולמיין את התלמידים לפי ציון. הקוד כולו נמצא בקובץ `lib/main.dart`, עם הערה שמסבירה כל חלק.

## License

MIT
