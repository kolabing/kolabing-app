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

    final antonPattern = RegExp(r'\bantonFont\b|\bfontDisplay\b|\bfontPageTitle\b|Anton');
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
}
