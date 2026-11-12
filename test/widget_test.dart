// Unit tests for the grade logic (limits 0-100, pass/fail line, average,
// sorting) and widget tests for the screen (average and pass count,
// +/- buttons, the 0 limit, and sorting).

import 'package:flutter_test/flutter_test.dart';
import 'package:flatter_exam_1/main.dart';

void main() {
  group('grade logic', () {
    const students = [
      Student(id: 'a', name: 'A', grade: 90),
      Student(id: 'b', name: 'B', grade: 40),
      Student(id: 'c', name: 'C', grade: 55),
    ];

    test('changeGrade clamps to 0-100', () {
      const low = Student(id: 'x', name: 'X', grade: 2);
      expect(low.changeGrade(-5).grade, 0);

      const high = Student(id: 'y', name: 'Y', grade: 99);
      expect(high.changeGrade(5).grade, 100);
    });

    test('changeGrade never mutates the original student', () {
      const original = Student(id: 'z', name: 'Z', grade: 50);
      final changed = original.changeGrade(10);
      expect(original.grade, 50);
      expect(changed.grade, 60);
    });

    test('passed is true at and above the pass grade', () {
      expect(const Student(id: 'p', name: 'P', grade: kPassGrade).passed, isTrue);
      expect(const Student(id: 'q', name: 'Q', grade: kPassGrade - 1).passed, isFalse);
    });

    test('averageGrade computes the mean, and 0 for an empty list', () {
      expect(averageGrade(students), closeTo((90 + 40 + 55) / 3, 0.001));
      expect(averageGrade(const []), 0);
    });

    test('passedCount counts students at or above the pass grade', () {
      expect(passedCount(students), 2); // 90 and 55 pass, 40 fails
    });

    test('sortByGrade returns a new sorted list without mutating the input', () {
      final asc = sortByGrade(students, ascending: true);
      expect(asc.map((s) => s.grade), [40, 55, 90]);

      final desc = sortByGrade(students, ascending: false);
      expect(desc.map((s) => s.grade), [90, 55, 40]);

      // the original list keeps its own order
      expect(students.map((s) => s.grade), [90, 40, 55]);
    });
  });

  group('GradesScreen', () {
    testWidgets('shows the class average and the pass count', (tester) async {
      await tester.pumpWidget(const GradesApp());
      await tester.pumpAndSettle();

      // Average of 92, 71, 54, 48 is 66.25 -> displayed as 66.3
      expect(find.text('66.3'), findsOneWidget);
      // 92 and 71 pass (>= 55); 54 and 48 fail
      expect(find.text('2 / 4'), findsOneWidget);
    });

    testWidgets('tapping + raises a grade and updates the average', (tester) async {
      await tester.pumpWidget(const GradesApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('+').first);
      await tester.pumpAndSettle();

      expect(find.text('93'), findsOneWidget);
    });

    testWidgets('a grade never drops below 0', (tester) async {
      await tester.pumpWidget(const GradesApp());
      await tester.pumpAndSettle();

      // עומר starts at 48 and is the last row in the unsorted list.
      final minusButtons = find.text('−');
      for (var i = 0; i < 60; i++) {
        await tester.tap(minusButtons.last);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('sorting toggles ascending and descending order', (tester) async {
      await tester.pumpWidget(const GradesApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('מיון לפי ציון'));
      await tester.pumpAndSettle();
      expect(find.text('מהגבוה לנמוך'), findsOneWidget);

      await tester.tap(find.text('מהגבוה לנמוך'));
      await tester.pumpAndSettle();
      expect(find.text('מהנמוך לגבוה'), findsOneWidget);
    });
  });
}
