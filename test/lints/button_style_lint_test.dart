// Guardrail test: enforces the Kolabing button unification rules.
//
// Fails CI if any of these violations are introduced:
//   1. Raw integer radius literal on a button shape: param
//   2. Hardcoded Color (Colors.black / raw hex) on button foreground/background
//   3. Anton/display font inside a button label
//
// Whitelisted files (intentional design exceptions): glass_button.dart, kolabing_fab.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const whitelist = {'glass_button.dart', 'kolabing_fab.dart'};

  List<File> dartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !whitelist.any((w) => f.path.endsWith(w)))
      .toList();

  // ---------------------------------------------------------------------------
  // Rule 1: No raw integer radius literal on a button shape: param
  // ---------------------------------------------------------------------------
  test('no raw integer radius literals in button shape: params', () {
    final violations = <String>[];

    // Matches: shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(<digit>
    final shapeWithLiteral = RegExp(
      r'shape:\s*(?:const\s*)?RoundedRectangleBorder\(\s*borderRadius:\s*BorderRadius\.circular\(\d',
    );
    // Context words that indicate a non-button (SnackBar, Dialog, BottomSheet)
    final nonButtonContext = RegExp(
      r'SnackBar\b|AlertDialog\b|showDialog\b|showModalBottomSheet\b|BottomSheet\b|Dialog\(',
    );
    // Context words that confirm a button widget
    final buttonContext = RegExp(
      r'ElevatedButton\b|FilledButton\b|OutlinedButton\b|TextButton\b|styleFrom\b|ButtonStyle\b',
    );

    for (final file in dartFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!shapeWithLiteral.hasMatch(lines[i])) continue;

        // Check up to 8 lines above for widget context
        final window = lines
            .sublist((i - 8).clamp(0, lines.length), i + 1)
            .join(' ');

        // Skip if clearly a non-button widget
        if (nonButtonContext.hasMatch(window)) continue;

        // Only flag if clearly a button widget (avoids false positives on
        // unrelated custom widgets)
        if (buttonContext.hasMatch(window)) {
          violations.add('${file.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Button shape overrides with raw integer literals found.\n'
          'Fix: delete the shape: param — ElevatedButton/FilledButton/OutlinedButton/TextButton\n'
          'inherit StadiumBorder from the theme. Do not add shape: overrides.\n\n'
          'Violations:\n${violations.join('\n')}',
    );
  });

  // ---------------------------------------------------------------------------
  // Rule 2: No hardcoded colors on button foreground/background
  // ---------------------------------------------------------------------------
  test('no hardcoded colors on button foregroundColor or backgroundColor', () {
    final violations = <String>[];

    // Matches: foregroundColor: Colors.black / Colors.brown / Color(0xFF...)
    final hardcodedFg = RegExp(
      r'foregroundColor:\s*(?:Colors\.(?:black|brown)\b|Color\(0x[0-9A-Fa-f]{8}\))',
    );
    final hardcodedBg = RegExp(
      r'backgroundColor:\s*(?:Colors\.(?:black|brown)\b|Color\(0x[0-9A-Fa-f]{8}\))',
    );
    final buttonContext = RegExp(
      r'ElevatedButton\b|FilledButton\b|OutlinedButton\b|TextButton\b|styleFrom\b|ButtonStyle\b',
    );

    for (final file in dartFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!hardcodedFg.hasMatch(line) && !hardcodedBg.hasMatch(line)) {
          continue;
        }
        final window = lines
            .sublist((i - 8).clamp(0, lines.length), i + 1)
            .join(' ');
        if (buttonContext.hasMatch(window)) {
          violations.add('${file.path}:${i + 1}  ${line.trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Hardcoded colors on button foreground/background found.\n'
          'Fix: use KolabingColors tokens (e.g. KolabingColors.primary, KolabingColors.onPrimary).\n\n'
          'Violations:\n${violations.join('\n')}',
    );
  });

  // ---------------------------------------------------------------------------
  // Rule 3: No Anton/display font on button label Text widgets
  // ---------------------------------------------------------------------------
  test('no Anton/display font inside button label Text widgets', () {
    final violations = <String>[];

    final antonPattern = RegExp(
      r'\bantonFont\b|\bfontDisplay\b|\bfontPageTitle\b|Anton',
    );
    final buttonContext = RegExp(
      r'ElevatedButton\b|FilledButton\b|OutlinedButton\b|TextButton\b',
    );
    // Restrict to lines inside a Text() style (not display headlines)
    final textStyle = RegExp(r'TextStyle|\.copyWith|fontFamily');

    for (final file in dartFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!antonPattern.hasMatch(line)) continue;
        if (!textStyle.hasMatch(line)) continue;

        // Check 15 lines above for button context (button child: Text() can be
        // several lines away from the button widget name)
        final window = lines
            .sublist((i - 15).clamp(0, lines.length), i + 1)
            .join(' ');
        if (buttonContext.hasMatch(window)) {
          violations.add('${file.path}:${i + 1}  ${line.trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Anton/display font found inside a button label.\n'
          'Fix: button labels must use KolabingTextStyles.button (Hanken Grotesk w700).\n\n'
          'Violations:\n${violations.join('\n')}',
    );
  });

  // ---------------------------------------------------------------------------
  // Rule 4: A theme-sized button must not sit directly inside a Row
  //
  // ElevatedButton/FilledButton/OutlinedButton themes all set
  // minimumSize.width = double.infinity so form buttons stretch. A Row measures
  // its non-flex children with an UNBOUNDED width, so that infinity claims the
  // entire row: every sibling Expanded collapses to 0px and its text wraps one
  // letter per line (the community Rewards tile shipped like that).
  //
  // Fix: either wrap the button in Expanded/Flexible/SizedBox, or pass an
  // explicit bounded minimumSize (e.g. `Size(0, KolabingLayout
  // .buttonHeightSecondary)`) in styleFrom.
  // ---------------------------------------------------------------------------
  test('no theme-sized button placed directly inside a Row', () {
    final violations = <String>[];

    final buttonOpen = RegExp(
      r'\b(ElevatedButton|FilledButton|OutlinedButton)(\.icon)?\s*\(',
    );
    // Ancestors that give the button a bounded/flex width of its own.
    final boundedParent = RegExp(
      r'\b(Expanded|Flexible|SizedBox|ConstrainedBox|IntrinsicWidth|Container)\s*\(',
    );
    final layoutParent = RegExp(
      r'\b(Row|Column|Wrap|Stack|Flex|ListView)\s*\(',
    );

    for (final file in dartFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!buttonOpen.hasMatch(line)) continue;
        // Style declarations and theme definitions are not widget instances.
        if (line.contains('styleFrom') ||
            line.contains('ButtonTheme') ||
            line.contains('ButtonStyle')) {
          continue;
        }

        final indent = line.length - line.trimLeft().length;

        // Walk up through strictly-outdented lines: those are the ancestors.
        var current = indent;
        var parentIsRow = false;
        for (var j = i - 1; j >= 0; j--) {
          final candidate = lines[j];
          if (candidate.trim().isEmpty) continue;
          final candidateIndent =
              candidate.length - candidate.trimLeft().length;
          if (candidateIndent >= current) continue;
          current = candidateIndent;
          if (boundedParent.hasMatch(candidate)) break;
          final layout = layoutParent.firstMatch(candidate);
          if (layout != null) {
            parentIsRow = layout.group(1) == 'Row';
            break;
          }
          if (current == 0) break;
        }
        if (!parentIsRow) continue;

        // A bounded minimumSize inside the button's own style clears it.
        final body = lines
            .sublist(i, (i + 30).clamp(0, lines.length))
            .join(' ');
        if (body.contains('minimumSize')) continue;

        violations.add('${file.path}:${i + 1}  ${line.trim()}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'A full-width-themed button sits directly in a Row; it will squeeze '
          'its siblings to 0px.\n'
          'Fix: wrap it in Expanded/SizedBox, or pass a bounded minimumSize in '
          'styleFrom.\n\n'
          'Violations:\n${violations.join('\n')}',
    );
  });
}
