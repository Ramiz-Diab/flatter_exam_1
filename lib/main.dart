// ציונים · flatter_exam_1
//
// A student grades app, in Hebrew, right-to-left, Apple-style design.
// The whole app lives in this one file:
//   constants → app & theme → colors (Palette) → Student model
//   → GradesScreen → glass card / animated row slot → header tiles
//   → student row → stepper → sort button → background blobs
//
// Built only with Flutter's own widgets — no extra runtime packages.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// The minimum grade a student needs to pass.
const int kPassGrade = 55;

/// Fixed row height and gap, used to lay out the student list on a [Stack]
/// so rows can slide to a new position when the list is sorted.
const double kRowHeight = 86;
const double kRowGap = 10;

void main() {
  runApp(const GradesApp());
}

// ---------------------------------------------------------------------------
// App & theme
// ---------------------------------------------------------------------------

/// Root widget: sets up the Hebrew locale, right-to-left layout, and a
/// theme that follows the system's light/dark setting.
class GradesApp extends StatelessWidget {
  const GradesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ציונים',
      debugShowCheckedModeBanner: false,
      locale: const Locale('he'),
      supportedLocales: const [Locale('he'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: Palette.theme(Brightness.light),
      darkTheme: Palette.theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: GradesScreen(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Colors (Apple system colors — separate light and dark values)
// ---------------------------------------------------------------------------

/// Apple-style system colors and surfaces, with light and dark variants.
/// Kept as static helpers (rather than a ThemeExtension) so every widget
/// below can reach a color with `Palette.green(context)`.
class Palette {
  const Palette._();

  static ThemeData theme(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor:
          brightness == Brightness.dark ? Colors.black : const Color(0xFFF2F2F7),
      useMaterial3: true,
    );
  }

  static bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

  static Color green(BuildContext c) =>
      _dark(c) ? const Color(0xFF30D158) : const Color(0xFF248A3D);
  static Color red(BuildContext c) =>
      _dark(c) ? const Color(0xFFFF453A) : const Color(0xFFD70015);
  static Color blue(BuildContext c) =>
      _dark(c) ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
  static Color label(BuildContext c) => _dark(c) ? Colors.white : const Color(0xFF1C1C1E);
  static Color secondaryLabel(BuildContext c) =>
      (_dark(c) ? Colors.white : const Color(0xFF3C3C43)).withOpacity(0.6);
  static Color track(BuildContext c) =>
      (_dark(c) ? Colors.white : const Color(0xFF3C3C43)).withOpacity(0.16);
  static Color cardFill(BuildContext c) =>
      _dark(c) ? const Color(0xFF1C1C1E).withOpacity(0.68) : Colors.white.withOpacity(0.72);
  static Color cardSolid(BuildContext c) => _dark(c) ? const Color(0xFF1C1C1E) : Colors.white;
  static Color hairline(BuildContext c) =>
      _dark(c) ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.9);
}

// ---------------------------------------------------------------------------
// Student model & pure helpers (easy to unit-test on their own)
// ---------------------------------------------------------------------------

/// An immutable student record. [changeGrade] never mutates the instance —
/// it returns a new [Student] with the grade moved by [delta] and clamped
/// to the 0-100 range.
@immutable
class Student {
  final String id;
  final String name;
  final int grade;

  const Student({required this.id, required this.name, required this.grade});

  /// Whether this student's grade meets [kPassGrade].
  bool get passed => grade >= kPassGrade;

  /// Returns a new [Student] with the grade changed by [delta], clamped to
  /// 0-100. The receiver is never modified.
  Student changeGrade(int delta) =>
      Student(id: id, name: name, grade: (grade + delta).clamp(0, 100).toInt());
}

/// The class average, or 0 for an empty list.
double averageGrade(List<Student> students) {
  if (students.isEmpty) return 0;
  final sum = students.fold<int>(0, (a, s) => a + s.grade);
  return sum / students.length;
}

/// How many students meet [kPassGrade].
int passedCount(List<Student> students) => students.where((s) => s.passed).length;

/// A new, sorted copy of [students] by grade. The input list is never
/// mutated.
List<Student> sortByGrade(List<Student> students, {required bool ascending}) {
  final copy = List<Student>.from(students);
  copy.sort((a, b) => ascending ? a.grade - b.grade : b.grade - a.grade);
  return copy;
}

// ---------------------------------------------------------------------------
// GradesScreen — the whole app's single screen
// ---------------------------------------------------------------------------

enum SortDirection { none, ascending, descending }

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final List<Student> _students = [
    const Student(id: 's1', name: 'נועה', grade: 92),
    const Student(id: 's2', name: 'דנה', grade: 71),
    const Student(id: 's3', name: 'יוסף', grade: 54),
    const Student(id: 's4', name: 'עומר', grade: 48),
  ];

  SortDirection _sortDirection = SortDirection.none;

  /// The order rows should appear in, given the current sort direction.
  /// Returns [_students] itself (its insertion order) when unsorted.
  List<Student> get _displayOrder {
    switch (_sortDirection) {
      case SortDirection.ascending:
        return sortByGrade(_students, ascending: true);
      case SortDirection.descending:
        return sortByGrade(_students, ascending: false);
      case SortDirection.none:
        return _students;
    }
  }

  void _changeGrade(String id, int delta) {
    final index = _students.indexWhere((s) => s.id == id);
    final before = _students[index];
    final wasPass = before.passed;
    final after = before.changeGrade(delta);
    setState(() => _students[index] = after);

    if (!MediaQuery.of(context).disableAnimations) {
      HapticFeedback.selectionClick();
      if (after.passed != wasPass) HapticFeedback.mediumImpact();
    }
  }

  void _toggleSort() {
    setState(() {
      _sortDirection = _sortDirection == SortDirection.descending
          ? SortDirection.ascending
          : SortDirection.descending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = _displayOrder;
    final total = _students.length;
    final listHeight = total == 0 ? 0.0 : total * kRowHeight + (total - 1) * kRowGap;

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundBlobs(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(
                  'ציונים',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Palette.label(context),
                  ),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _AverageTile(average: averageGrade(_students))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PassRingTile(passed: passedCount(_students), total: total),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'תלמידים',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Palette.label(context),
                      ),
                    ),
                    _SortButton(direction: _sortDirection, onTap: _toggleSort),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: listHeight,
                  child: Stack(
                    children: [
                      for (final s in _students)
                        _AnimatedRowSlot(
                          key: ValueKey(s.id),
                          index: order.indexWhere((o) => o.id == s.id),
                          child: StudentRow(
                            student: s,
                            onMinus: () => _changeGrade(s.id, -1),
                            onPlus: () => _changeGrade(s.id, 1),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass card / pressable
// ---------------------------------------------------------------------------

/// A frosted "glass" card: blurred backdrop, translucent fill and a bright
/// hairline edge. Turns into a solid, opaque surface when the system's
/// Increase Contrast setting is on.
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.of(context).highContrast;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highContrast ? Palette.cardSolid(context) : Palette.cardFill(context),
        border: Border.all(color: Palette.hairline(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );

    if (highContrast) {
      return ClipRRect(borderRadius: BorderRadius.circular(18), child: card);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: card,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header tiles: class average, pass ring
// ---------------------------------------------------------------------------

/// The big glass tile showing the class average; counts smoothly to its
/// new value whenever a grade changes.
class _AverageTile extends StatelessWidget {
  final double average;

  const _AverageTile({required this.average});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Semantics(
              liveRegion: true,
              label: 'ממוצע כיתתי ${average.toStringAsFixed(1)}',
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: average),
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: Palette.label(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ממוצע כיתתי',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Palette.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// The glass tile showing how many students passed, as a ring that fills
/// to the passed/total fraction, with the fraction as text in its center.
class _PassRingTile extends StatelessWidget {
  final int passed;
  final int total;

  const _PassRingTile({required this.passed, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : passed / total;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CustomPaint(
                    size: const Size(76, 76),
                    painter: _RingPainter(
                      fraction: value,
                      trackColor: Palette.track(context),
                      fillColor: Palette.green(context),
                    ),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Semantics(
                    liveRegion: true,
                    label: '$passed מתוך $total עברו',
                    child: Text(
                      '$passed / $total',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: Palette.label(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'עברו',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Palette.secondaryLabel(context),
            ),
          ),
          const SizedBox(height: 2),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              'ציון עובר: $kPassGrade',
              style: TextStyle(fontSize: 11, color: Palette.secondaryLabel(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the pass ring: a neutral track circle plus a colored arc for the
/// passed fraction, starting at the top and sweeping clockwise.
class _RingPainter extends CustomPainter {
  final double fraction;
  final Color trackColor;
  final Color fillColor;

  const _RingPainter({
    required this.fraction,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * fraction;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, fill);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.fillColor != fillColor;
}

// ---------------------------------------------------------------------------
// Student row
// ---------------------------------------------------------------------------

/// Slides its child to a new vertical slot (given by [index]) inside an
/// ancestor [Stack], used to animate rows into place when the list sorts.
class _AnimatedRowSlot extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedRowSlot({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnimatedPositioned(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      top: index * (kRowHeight + kRowGap),
      left: 0,
      right: 0,
      height: kRowHeight,
      child: child,
    );
  }
}

/// One student's row: pass/fail badge, name, grade bar and grade, and the
/// −/+ stepper.
class StudentRow extends StatelessWidget {
  final Student student;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const StudentRow({
    super.key,
    required this.student,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final pass = student.passed;
    final statusColor = pass ? Palette.green(context) : Palette.red(context);

    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.18), shape: BoxShape.circle),
            child: Semantics(
              label: pass ? 'עבר' : 'נכשל',
              child: ExcludeSemantics(
                child: Text(
                  pass ? '✓' : '✗',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        student.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          color: Palette.label(context),
                        ),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${student.grade}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: Palette.label(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final reduceMotion = MediaQuery.of(context).disableAnimations;
                    return Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Palette.track(context),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        AnimatedContainer(
                          duration:
                              reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          height: 6,
                          width: constraints.maxWidth * (student.grade / 100),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Stepper(onMinus: onMinus, onPlus: onPlus, name: student.name),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stepper
// ---------------------------------------------------------------------------

/// An iOS-style −/+ split button. Kept left-to-right regardless of the
/// page's direction, the way a numeric control conventionally reads.
class _Stepper extends StatelessWidget {
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final String name;

  const _Stepper({required this.onMinus, required this.onPlus, required this.name});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Palette.hairline(context))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(symbol: '−', onTap: onMinus, semanticLabel: 'הפחתת ציון ל$name'),
              Container(width: 1, height: 44, color: Palette.hairline(context)),
              _StepButton(symbol: '+', onTap: onPlus, semanticLabel: 'הוספת ציון ל$name'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Half of the stepper. 44x44 — Apple's minimum comfortable touch target.
class _StepButton extends StatelessWidget {
  final String symbol;
  final VoidCallback onTap;
  final String semanticLabel;

  const _StepButton({required this.symbol, required this.onTap, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 44,
          alignment: Alignment.center,
          color: Palette.track(context),
          child: ExcludeSemantics(
            child: Text(symbol, style: TextStyle(fontSize: 18, color: Palette.label(context))),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort button
// ---------------------------------------------------------------------------

/// Toggles the list between sorted-by-grade (descending, then ascending)
/// and reflects the current direction in both its label and its arrow.
class _SortButton extends StatelessWidget {
  final SortDirection direction;
  final VoidCallback onTap;

  const _SortButton({required this.direction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = switch (direction) {
      SortDirection.descending => 'מהגבוה לנמוך',
      SortDirection.ascending => 'מהנמוך לגבוה',
      SortDirection.none => 'מיון לפי ציון',
    };

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Palette.blue(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: direction == SortDirection.ascending ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(Icons.arrow_upward_rounded, size: 16, color: Palette.blue(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background
// ---------------------------------------------------------------------------

/// Soft, blurred colour shapes behind the glass cards — purely decorative.
class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  Widget _blob(Color color, Alignment alignment, double size, double opacity) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          _blob(const Color(0xFF34C759), Alignment.topLeft, 260, 0.28),
          _blob(const Color(0xFF007AFF), Alignment.bottomRight, 260, 0.28),
          _blob(const Color(0xFFFF375F), Alignment.center, 220, 0.14),
        ],
      ),
    );
  }
}
