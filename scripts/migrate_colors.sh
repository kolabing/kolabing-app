#!/usr/bin/env bash
# Night-mode codemod: rewrite KolabingColors.<token> -> context.colors.<token>
# in all widget Dart files under lib/, so colors resolve at runtime via the
# KolabingColorTokens ThemeExtension.
#
# Excludes lib/config/theme/ (colors.dart defines the source values; theme.dart
# and color_tokens.dart build the ThemeData and have no BuildContext).
#
# After running: `dart analyze lib/` will flag (a) const expressions that now
# use a runtime color -> remove `const`; (b) any usage outside a BuildContext
# scope -> thread context in or keep KolabingColors there. Review the diff.
set -euo pipefail

TOKENS=(accentOrange accentOrangeText activeBg activeText amberChipContainer amberChipText background borderError borderFocus categoryBlueBg categoryBlueText categoryLavenderBg categoryLavenderText categoryLocationBg categoryLocationText categoryMintBg categoryMintText categoryOrangeBg categoryOrangeText categoryRedBg categoryRedText categorySageBg categorySageText charcoal completedBg completedText darkBorder darkSurface error errorBg errorText glassDestructiveInk glassInk glassWhite14 hairline info inverseOnSurface inverseSurface navBarBackground navInactive navInactiveSubtle onAccent onPrimary onSecondary onSurface onSurfaceVariant outline outlineVariant overlayDark30 overlayDark50 overlayDark60 pendingBg pendingText primary primaryDark primaryGradient secondary secondaryContainer softAccent softYellow softYellowBorder success surface surfaceContainer surfaceContainerHigh surfaceContainerLow surfaceVariant tertiary tertiaryContainer textOnDark textTertiary titleInk warning xpGreen xpGreenContainer xpGreenOnContainer )

find lib -name '*.dart' -not -path 'lib/config/theme/*' | while read -r f; do
  for token in "${TOKENS[@]}"; do
    sed -i '' "s/KolabingColors\.${token}/context.colors.${token}/g" "$f"
  done
done

echo "Codemod complete. Run: dart analyze lib/"
