import 'package:flutter/material.dart';

/// Runtime-resolved color tokens for Kolabing's light + night themes.
///
/// Registered as a [ThemeExtension] on both [ThemeData] light and dark. Widgets
/// read colors via `context.colors.xxx` so the correct value resolves at runtime
/// without `if (isDark)` branching. The `.light` set mirrors the legacy
/// `KolabingColors` values byte-for-byte; the `.night` set is the dark palette.
@immutable
class KolabingColorTokens extends ThemeExtension<KolabingColorTokens> {
  const KolabingColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.hairline,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.softYellow,
    required this.softYellowBorder,
    required this.pastelYellowBg,
    required this.pastelYellowBorder,
    required this.navBarBackground,
    required this.charcoal,
    required this.titleInk,
    required this.error,
    required this.errorBg,
    required this.errorText,
    required this.pendingBg,
    required this.pendingText,
    required this.activeBg,
    required this.activeText,
    required this.completedBg,
    required this.completedText,
    required this.success,
    required this.warning,
    required this.info,
    required this.navInactive,
    required this.navInactiveSubtle,
    required this.xpGreen,
    required this.xpGreenContainer,
    required this.xpGreenOnContainer,
    required this.categoryLavenderBg,
    required this.categoryLavenderText,
    required this.categorySageBg,
    required this.categorySageText,
    required this.categoryMintBg,
    required this.categoryMintText,
    required this.categoryOrangeBg,
    required this.categoryOrangeText,
    required this.categoryRedBg,
    required this.categoryRedText,
    required this.categoryBlueBg,
    required this.categoryBlueText,
    required this.categoryLocationBg,
    required this.categoryLocationText,
    required this.overlayDark30,
    required this.overlayDark50,
    required this.overlayDark60,
    required this.glassWhite14,
    required this.glassInk,
    required this.glassDestructiveInk,
    required this.amberChipContainer,
    required this.amberChipText,
    required this.accentOrange,
    required this.accentOrangeText,
    required this.darkSurface,
    required this.darkBorder,
    required this.borderFocus,
    required this.borderError,
    required this.textTertiary,
    required this.textOnDark,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.onAccent,
    required this.softAccent,
    required this.primaryGradient,
  });

  // --- surfaces & text ---
  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color hairline;

  // --- brand yellow ---
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color softYellow;
  final Color softYellowBorder;
  final Color pastelYellowBg;
  final Color pastelYellowBorder;
  final Color navBarBackground;
  final Color charcoal;
  final Color titleInk; // large Anton display titles only

  // --- semantic ---
  final Color error;
  final Color errorBg;
  final Color errorText;
  final Color pendingBg;
  final Color pendingText;
  final Color activeBg;
  final Color activeText;
  final Color completedBg;
  final Color completedText;
  final Color success;
  final Color warning;
  final Color info;

  // --- navigation ---
  final Color navInactive;
  final Color navInactiveSubtle;

  // --- xp / gamification ---
  final Color xpGreen;
  final Color xpGreenContainer;
  final Color xpGreenOnContainer;

  // --- category chip pairs ---
  final Color categoryLavenderBg;
  final Color categoryLavenderText;
  final Color categorySageBg;
  final Color categorySageText;
  final Color categoryMintBg;
  final Color categoryMintText;
  final Color categoryOrangeBg;
  final Color categoryOrangeText;
  final Color categoryRedBg;
  final Color categoryRedText;
  final Color categoryBlueBg;
  final Color categoryBlueText;
  final Color categoryLocationBg;
  final Color categoryLocationText;

  // --- overlay / glass ---
  final Color overlayDark30;
  final Color overlayDark50;
  final Color overlayDark60;
  final Color glassWhite14;
  final Color glassInk;
  final Color glassDestructiveInk;

  // --- amber chips ---
  final Color amberChipContainer;
  final Color amberChipText;
  final Color accentOrange;
  final Color accentOrangeText;

  // --- auth / borders ---
  final Color darkSurface;
  final Color darkBorder;
  final Color borderFocus;
  final Color borderError;
  final Color textTertiary;
  final Color textOnDark;

  // --- secondary / tertiary / legacy ---
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color onAccent;
  final Color softAccent;

  // --- gradient ---
  final LinearGradient primaryGradient;

  // ---------------------------------------------------------------------------
  // Light set (maps 1:1 to the legacy KolabingColors values)
  // ---------------------------------------------------------------------------
  static const KolabingColorTokens light = KolabingColorTokens(
    background: Color(0xFFFDF9F0),
    surface: Color(0xFFFDF9F0),
    surfaceContainer: Color(0xFFF1EEE5),
    surfaceContainerLow: Color(0xFFF7F3EA),
    surfaceContainerHigh: Color(0xFFECE8DF),
    surfaceVariant: Color(0xFFE6E2D9),
    onSurface: Color(0xFF1C1C16),
    onSurfaceVariant: Color(0xFF4C4638),
    outline: Color(0xFF7D7667),
    outlineVariant: Color(0xFFCFC6B3),
    inverseSurface: Color(0xFF31302B),
    inverseOnSurface: Color(0xFFF4F0E7),
    hairline: Color(0xFFE8E2D6),
    primary: Color(0xFFFFE28C),
    primaryDark: Color(0xFFF5D070),
    onPrimary: Color(0xFF78631A),
    softYellow: Color(0xFFFFF4C2),
    softYellowBorder: Color(0xFFFFE28C),
    pastelYellowBg: Color(0xFFFDF6DC),
    pastelYellowBorder: Color(0xFFF0E4A0),
    navBarBackground: Color(0xFFFFFFFF),
    charcoal: Color(0xFF1C1C16),
    titleInk: Color(0xFF1C1C16),
    error: Color(0xFFBA1A1A),
    errorBg: Color(0xFFF8D7DA),
    errorText: Color(0xFF721C24),
    pendingBg: Color(0xFFFFDDAC),
    pendingText: Color(0xFFD8910B),
    activeBg: Color(0xFFD4EDDA),
    activeText: Color(0xFF155724),
    completedBg: Color(0xFFEDEAE0),
    completedText: Color(0xFF4C4638),
    success: Color(0xFF56624D),
    warning: Color(0xFFFBC02D),
    info: Color(0xFF2196F3),
    navInactive: Color(0xFF7D7667),
    navInactiveSubtle: Color(0xFFCFC6B3),
    xpGreen: Color(0xFF7AE7A3),
    xpGreenContainer: Color(0xFFE8F9F1),
    xpGreenOnContainer: Color(0xFF1A6644),
    categoryLavenderBg: Color(0xFFE5DCF6),
    categoryLavenderText: Color(0xFF615B71),
    categorySageBg: Color(0xFFDBE8CD),
    categorySageText: Color(0xFF56624D),
    categoryMintBg: Color(0xFFE8F9F1),
    categoryMintText: Color(0xFF1A6644),
    categoryOrangeBg: Color(0xFFFFDDAC),
    categoryOrangeText: Color(0xFFD8910B),
    categoryRedBg: Color(0xFFF8D7DA),
    categoryRedText: Color(0xFF721C24),
    categoryBlueBg: Color(0xFFDDE3EC),
    categoryBlueText: Color(0xFF3D4A5C),
    categoryLocationBg: Color(0xFFFFF4C2),
    categoryLocationText: Color(0xFFA07010),
    overlayDark30: Color(0x4D000000),
    overlayDark50: Color(0x80000000),
    overlayDark60: Color(0x99000000),
    glassWhite14: Color(0x24FFFFFF),
    glassInk: Color(0xFF57534B),
    glassDestructiveInk: Color(0xFF9B3B3B),
    amberChipContainer: Color(0xFFFFF0C2),
    amberChipText: Color(0xFFA07010),
    accentOrange: Color(0xFFFFDDAC),
    accentOrangeText: Color(0xFFD8910B),
    darkSurface: Color(0xFFFFFFFF),
    darkBorder: Color(0x0F1C1C16),
    borderFocus: Color(0xFF1C1C16),
    borderError: Color(0xFFBA1A1A),
    textTertiary: Color(0xFF8C8A82),
    textOnDark: Color(0xFFFFFFFF),
    secondary: Color(0xFF615B71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE5DCF6),
    tertiary: Color(0xFF56624D),
    tertiaryContainer: Color(0xFFDBE8CD),
    onAccent: Color(0xFFFFFFFF),
    softAccent: Color(0xFFE5DCF6),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFE28C), Color(0xFFFFF4C2)],
    ),
  );

  // ---------------------------------------------------------------------------
  // Night set
  // ---------------------------------------------------------------------------
  static const KolabingColorTokens night = KolabingColorTokens(
    background: Color(0xFF0C0C0E),
    surface: Color(0xFF0C0C0E),
    surfaceContainer: Color(0xFF19191C),
    surfaceContainerLow: Color(0xFF141416),
    surfaceContainerHigh: Color(0xFF222226),
    surfaceVariant: Color(0xFF161618),
    onSurface: Color(0xFFF5F5F7),
    onSurfaceVariant: Color(0xFFA2A2A9),
    outline: Color(0xFF2E2E34),
    outlineVariant: Color(0xFF2A2A2F),
    inverseSurface: Color(0xFFF5F5F7),
    inverseOnSurface: Color(0xFF0C0C0E),
    hairline: Color(0xFF26262B),
    primary: Color(0xFFFFE28C),
    primaryDark: Color(0xFFE7CE84),
    onPrimary: Color(0xFF5C4A12),
    softYellow: Color(0xFF2C2710),
    softYellowBorder: Color(0xFFFFE28C),
    pastelYellowBg: Color(0xFF2C2710),
    pastelYellowBorder: Color(0xFF514A36),
    navBarBackground: Color(0xFF19191C),
    charcoal: Color(0xFFF5F5F7),
    titleInk: Color(0xCCF5F5F7), // 80% opacity white
    error: Color(0xFFE14D3D),
    errorBg: Color(0xFF371F1B),
    errorText: Color(0xFFFBA797),
    pendingBg: Color(0xFF36280F),
    pendingText: Color(0xFFFBC56F),
    activeBg: Color(0xFF0E3326),
    activeText: Color(0xFF6CF2BC),
    completedBg: Color(0xFF2B2550),
    completedText: Color(0xFFD4C6FF),
    success: Color(0xFF6CF2BC),
    warning: Color(0xFFFBC56F),
    info: Color(0xFF94CBF7),
    navInactive: Color(0xFF6C6C74),
    navInactiveSubtle: Color(0xFF6C6C74),
    xpGreen: Color(0xFF6CF2BC),
    xpGreenContainer: Color(0xFF0E3326),
    xpGreenOnContainer: Color(0xFF8CE7C2),
    categoryLavenderBg: Color(0xFF2B2550),
    categoryLavenderText: Color(0xFFD4C6FF),
    categorySageBg: Color(0xFF28361B),
    categorySageText: Color(0xFFCCEC9C),
    categoryMintBg: Color(0xFF0E3326),
    categoryMintText: Color(0xFF6CF2BC),
    categoryOrangeBg: Color(0xFF36280F),
    categoryOrangeText: Color(0xFFFBC56F),
    categoryRedBg: Color(0xFF371F1B),
    categoryRedText: Color(0xFFFBA797),
    categoryBlueBg: Color(0xFF13293F),
    categoryBlueText: Color(0xFF94CBF7),
    categoryLocationBg: Color(0xFF2E2A14),
    categoryLocationText: Color(0xFFFFE28C),
    overlayDark30: Color(0x4D000000),
    overlayDark50: Color(0x80000000),
    overlayDark60: Color(0x9E000000),
    glassWhite14: Color(0x24FFFFFF),
    glassInk: Color(0xFFA2A2A9),
    glassDestructiveInk: Color(0xFFFBA797),
    amberChipContainer: Color(0xFF2C2710),
    amberChipText: Color(0xFFFFE28C),
    accentOrange: Color(0xFF36280F),
    accentOrangeText: Color(0xFFFBC56F),
    darkSurface: Color(0xFF19191C),
    darkBorder: Color(0xFF2A2A2F),
    borderFocus: Color(0xFFFFE28C),
    borderError: Color(0xFFE14D3D),
    textTertiary: Color(0xFF6C6C74),
    textOnDark: Color(0xFFF5F5F7),
    secondary: Color(0xFFD4C6FF),
    onSecondary: Color(0xFF2B2550),
    secondaryContainer: Color(0xFF2B2550),
    tertiary: Color(0xFFCCEC9C),
    tertiaryContainer: Color(0xFF28361B),
    onAccent: Color(0xFF2B2550),
    softAccent: Color(0xFF2B2550),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFE28C), Color(0xFFE7CE84)],
    ),
  );

  @override
  KolabingColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceContainer,
    Color? surfaceContainerLow,
    Color? surfaceContainerHigh,
    Color? surfaceVariant,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? inverseSurface,
    Color? inverseOnSurface,
    Color? hairline,
    Color? primary,
    Color? primaryDark,
    Color? onPrimary,
    Color? softYellow,
    Color? softYellowBorder,
    Color? pastelYellowBg,
    Color? pastelYellowBorder,
    Color? navBarBackground,
    Color? charcoal,
    Color? titleInk,
    Color? error,
    Color? errorBg,
    Color? errorText,
    Color? pendingBg,
    Color? pendingText,
    Color? activeBg,
    Color? activeText,
    Color? completedBg,
    Color? completedText,
    Color? success,
    Color? warning,
    Color? info,
    Color? navInactive,
    Color? navInactiveSubtle,
    Color? xpGreen,
    Color? xpGreenContainer,
    Color? xpGreenOnContainer,
    Color? categoryLavenderBg,
    Color? categoryLavenderText,
    Color? categorySageBg,
    Color? categorySageText,
    Color? categoryMintBg,
    Color? categoryMintText,
    Color? categoryOrangeBg,
    Color? categoryOrangeText,
    Color? categoryRedBg,
    Color? categoryRedText,
    Color? categoryBlueBg,
    Color? categoryBlueText,
    Color? categoryLocationBg,
    Color? categoryLocationText,
    Color? overlayDark30,
    Color? overlayDark50,
    Color? overlayDark60,
    Color? glassWhite14,
    Color? glassInk,
    Color? glassDestructiveInk,
    Color? amberChipContainer,
    Color? amberChipText,
    Color? accentOrange,
    Color? accentOrangeText,
    Color? darkSurface,
    Color? darkBorder,
    Color? borderFocus,
    Color? borderError,
    Color? textTertiary,
    Color? textOnDark,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? tertiary,
    Color? tertiaryContainer,
    Color? onAccent,
    Color? softAccent,
    LinearGradient? primaryGradient,
  }) {
    return KolabingColorTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      inverseOnSurface: inverseOnSurface ?? this.inverseOnSurface,
      hairline: hairline ?? this.hairline,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      onPrimary: onPrimary ?? this.onPrimary,
      softYellow: softYellow ?? this.softYellow,
      softYellowBorder: softYellowBorder ?? this.softYellowBorder,
      pastelYellowBg: pastelYellowBg ?? this.pastelYellowBg,
      pastelYellowBorder: pastelYellowBorder ?? this.pastelYellowBorder,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      charcoal: charcoal ?? this.charcoal,
      titleInk: titleInk ?? this.titleInk,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      errorText: errorText ?? this.errorText,
      pendingBg: pendingBg ?? this.pendingBg,
      pendingText: pendingText ?? this.pendingText,
      activeBg: activeBg ?? this.activeBg,
      activeText: activeText ?? this.activeText,
      completedBg: completedBg ?? this.completedBg,
      completedText: completedText ?? this.completedText,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      navInactive: navInactive ?? this.navInactive,
      navInactiveSubtle: navInactiveSubtle ?? this.navInactiveSubtle,
      xpGreen: xpGreen ?? this.xpGreen,
      xpGreenContainer: xpGreenContainer ?? this.xpGreenContainer,
      xpGreenOnContainer: xpGreenOnContainer ?? this.xpGreenOnContainer,
      categoryLavenderBg: categoryLavenderBg ?? this.categoryLavenderBg,
      categoryLavenderText: categoryLavenderText ?? this.categoryLavenderText,
      categorySageBg: categorySageBg ?? this.categorySageBg,
      categorySageText: categorySageText ?? this.categorySageText,
      categoryMintBg: categoryMintBg ?? this.categoryMintBg,
      categoryMintText: categoryMintText ?? this.categoryMintText,
      categoryOrangeBg: categoryOrangeBg ?? this.categoryOrangeBg,
      categoryOrangeText: categoryOrangeText ?? this.categoryOrangeText,
      categoryRedBg: categoryRedBg ?? this.categoryRedBg,
      categoryRedText: categoryRedText ?? this.categoryRedText,
      categoryBlueBg: categoryBlueBg ?? this.categoryBlueBg,
      categoryBlueText: categoryBlueText ?? this.categoryBlueText,
      categoryLocationBg: categoryLocationBg ?? this.categoryLocationBg,
      categoryLocationText: categoryLocationText ?? this.categoryLocationText,
      overlayDark30: overlayDark30 ?? this.overlayDark30,
      overlayDark50: overlayDark50 ?? this.overlayDark50,
      overlayDark60: overlayDark60 ?? this.overlayDark60,
      glassWhite14: glassWhite14 ?? this.glassWhite14,
      glassInk: glassInk ?? this.glassInk,
      glassDestructiveInk: glassDestructiveInk ?? this.glassDestructiveInk,
      amberChipContainer: amberChipContainer ?? this.amberChipContainer,
      amberChipText: amberChipText ?? this.amberChipText,
      accentOrange: accentOrange ?? this.accentOrange,
      accentOrangeText: accentOrangeText ?? this.accentOrangeText,
      darkSurface: darkSurface ?? this.darkSurface,
      darkBorder: darkBorder ?? this.darkBorder,
      borderFocus: borderFocus ?? this.borderFocus,
      borderError: borderError ?? this.borderError,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnDark: textOnDark ?? this.textOnDark,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onAccent: onAccent ?? this.onAccent,
      softAccent: softAccent ?? this.softAccent,
      primaryGradient: primaryGradient ?? this.primaryGradient,
    );
  }

  @override
  KolabingColorTokens lerp(KolabingColorTokens? other, double t) {
    if (other is! KolabingColorTokens) return this;
    return KolabingColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      inverseOnSurface: Color.lerp(inverseOnSurface, other.inverseOnSurface, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      softYellow: Color.lerp(softYellow, other.softYellow, t)!,
      softYellowBorder: Color.lerp(softYellowBorder, other.softYellowBorder, t)!,
      pastelYellowBg: Color.lerp(pastelYellowBg, other.pastelYellowBg, t)!,
      pastelYellowBorder: Color.lerp(pastelYellowBorder, other.pastelYellowBorder, t)!,
      navBarBackground: Color.lerp(navBarBackground, other.navBarBackground, t)!,
      charcoal: Color.lerp(charcoal, other.charcoal, t)!,
      titleInk: Color.lerp(titleInk, other.titleInk, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      pendingBg: Color.lerp(pendingBg, other.pendingBg, t)!,
      pendingText: Color.lerp(pendingText, other.pendingText, t)!,
      activeBg: Color.lerp(activeBg, other.activeBg, t)!,
      activeText: Color.lerp(activeText, other.activeText, t)!,
      completedBg: Color.lerp(completedBg, other.completedBg, t)!,
      completedText: Color.lerp(completedText, other.completedText, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      navInactiveSubtle: Color.lerp(navInactiveSubtle, other.navInactiveSubtle, t)!,
      xpGreen: Color.lerp(xpGreen, other.xpGreen, t)!,
      xpGreenContainer: Color.lerp(xpGreenContainer, other.xpGreenContainer, t)!,
      xpGreenOnContainer: Color.lerp(xpGreenOnContainer, other.xpGreenOnContainer, t)!,
      categoryLavenderBg: Color.lerp(categoryLavenderBg, other.categoryLavenderBg, t)!,
      categoryLavenderText: Color.lerp(categoryLavenderText, other.categoryLavenderText, t)!,
      categorySageBg: Color.lerp(categorySageBg, other.categorySageBg, t)!,
      categorySageText: Color.lerp(categorySageText, other.categorySageText, t)!,
      categoryMintBg: Color.lerp(categoryMintBg, other.categoryMintBg, t)!,
      categoryMintText: Color.lerp(categoryMintText, other.categoryMintText, t)!,
      categoryOrangeBg: Color.lerp(categoryOrangeBg, other.categoryOrangeBg, t)!,
      categoryOrangeText: Color.lerp(categoryOrangeText, other.categoryOrangeText, t)!,
      categoryRedBg: Color.lerp(categoryRedBg, other.categoryRedBg, t)!,
      categoryRedText: Color.lerp(categoryRedText, other.categoryRedText, t)!,
      categoryBlueBg: Color.lerp(categoryBlueBg, other.categoryBlueBg, t)!,
      categoryBlueText: Color.lerp(categoryBlueText, other.categoryBlueText, t)!,
      categoryLocationBg: Color.lerp(categoryLocationBg, other.categoryLocationBg, t)!,
      categoryLocationText: Color.lerp(categoryLocationText, other.categoryLocationText, t)!,
      overlayDark30: Color.lerp(overlayDark30, other.overlayDark30, t)!,
      overlayDark50: Color.lerp(overlayDark50, other.overlayDark50, t)!,
      overlayDark60: Color.lerp(overlayDark60, other.overlayDark60, t)!,
      glassWhite14: Color.lerp(glassWhite14, other.glassWhite14, t)!,
      glassInk: Color.lerp(glassInk, other.glassInk, t)!,
      glassDestructiveInk: Color.lerp(glassDestructiveInk, other.glassDestructiveInk, t)!,
      amberChipContainer: Color.lerp(amberChipContainer, other.amberChipContainer, t)!,
      amberChipText: Color.lerp(amberChipText, other.amberChipText, t)!,
      accentOrange: Color.lerp(accentOrange, other.accentOrange, t)!,
      accentOrangeText: Color.lerp(accentOrangeText, other.accentOrangeText, t)!,
      darkSurface: Color.lerp(darkSurface, other.darkSurface, t)!,
      darkBorder: Color.lerp(darkBorder, other.darkBorder, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      borderError: Color.lerp(borderError, other.borderError, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textOnDark: Color.lerp(textOnDark, other.textOnDark, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiaryContainer: Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      softAccent: Color.lerp(softAccent, other.softAccent, t)!,
      primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
    );
  }
}

/// Ergonomic access: `context.colors.onSurface`.
///
/// Falls back to the light token set when no [KolabingColorTokens] extension is
/// registered on the ambient theme (e.g. a widget pumped in a bare test harness
/// or rendered outside the app's themed tree), so it never null-crashes.
extension KolabingColorsX on BuildContext {
  KolabingColorTokens get colors =>
      Theme.of(this).extension<KolabingColorTokens>() ??
      KolabingColorTokens.light;
}
