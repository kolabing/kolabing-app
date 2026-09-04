import 'package:flutter/material.dart';

// Re-export the runtime token extension so every file that imports colors.dart
// (i.e. every former KolabingColors consumer) can resolve `context.colors.xxx`
// without an extra import after the night-mode migration.
export 'color_tokens.dart';

/// Kolabing design system colors — Atmospheric Editorial
///
/// Palette: warm parchment surfaces, muted yellow CTA, ink-black text,
/// lavender secondary, sage tertiary. M3-aligned token names.
abstract final class KolabingColors {
  // ---------------------------------------------------------------------------
  // Primary Brand Colors
  // ---------------------------------------------------------------------------

  /// Primary CTA — warm soft yellow
  static const Color primary = Color(0xFFFFE28C);

  /// Darker yellow for pressed states
  static const Color primaryDark = Color(0xFFF5D070);

  /// On-primary-container — deep ink (text/icons on yellow)
  static const Color onPrimary = Color(0xFF19150F);

  /// Primary tint — yellow tint for selected chips
  static const Color primaryTint = Color(0xFFFFF1C6);

  /// Yellow tint alias — same as primaryTint
  static const Color yellowTint = Color(0xFFFFF1C6);

  /// Amber text on yellow backgrounds
  static const Color amber = Color(0xFF9A7C28);

  /// Orange — status/role/accent only
  static const Color orange = Color(0xFFFF6114);

  /// Orange tint background
  static const Color orangeTint = Color(0xFFFFE7D6);

  /// Darkest text (ink black)
  static const Color ink = Color(0xFF19150F);

  /// Near-black from the Kolabing web design system (`--kb-dark`): its body
  /// ink, footer ground and primary-CTA fill.
  ///
  /// Cooler and slightly darker than [ink] (`#19150F`), the warm parchment-era
  /// black. Both ship on purpose — this one is for surfaces ported verbatim
  /// from the web design system, starting with the redesigned sign-in screen
  /// (kolabing-app#193). Everything else in that design already matched the
  /// app: its yellow is [primary], its page is [background], its muted brown is
  /// [inkBody] and its placeholder grey is [muted], all exact.
  static const Color brandDark = Color(0xFF0D1114);

  /// Body text
  static const Color inkBody = Color(0xFF3F3A32);

  /// Placeholder / inactive text
  static const Color muted = Color(0xFF8C8474);

  /// Secondary button fill — Warm Mist
  static const Color buttonSecondary = Color(0xFFF0EBE1);

  /// Text/icons on secondary buttons
  static const Color onButtonSecondary = Color(0xFF1C1C16);

  // ---------------------------------------------------------------------------
  // Surface Hierarchy (M3-aligned)
  // ---------------------------------------------------------------------------

  /// Main background — warm cream
  static const Color background = Color(0xFFFAF5EA);

  /// App background alias — warm cream page background
  static const Color appBackground = Color(0xFFFAF5EA);

  /// Surface bright — white card surface
  static const Color surface = Color(0xFFFFFFFF);

  /// Cards, modals
  static const Color surfaceContainer = Color(0xFFF1EEE5);

  /// Subtle fills
  static const Color surfaceContainerLow = Color(0xFFF7F3EA);

  /// Elevated surfaces
  static const Color surfaceContainerHigh = Color(0xFFECE8DF);

  /// Input fills — soft cream
  static const Color surfaceVariant = Color(0xFFF5EFE3);

  /// Primary text — ink black
  static const Color onSurface = Color(0xFF19150F);

  /// Secondary/muted text
  static const Color onSurfaceVariant = Color(0xFF3F3A32);

  // ---------------------------------------------------------------------------
  // Border / Outline
  // ---------------------------------------------------------------------------

  /// Default border
  static const Color outline = Color(0xFF7D7667);

  /// Subtle borders
  static const Color outlineVariant = Color(0xFFE4DBCB);

  // ---------------------------------------------------------------------------
  // Inverse (dark cards / dark mode surfaces)
  // ---------------------------------------------------------------------------

  /// Dark cards / dark mode surface
  static const Color inverseSurface = Color(0xFF31302B);

  /// Text on dark surfaces
  static const Color inverseOnSurface = Color(0xFFF4F0E7);

  // ---------------------------------------------------------------------------
  // Secondary — Lavender
  // Active nav, links, selected states.
  // ---------------------------------------------------------------------------

  /// Lavender — active nav, badges, chips
  static const Color secondary = Color(0xFF615B71);

  /// Text/icons on secondary fills
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// Lavender fills — selected chips, subtle tints
  static const Color secondaryContainer = Color(0xFFE5DCF6);

  // ---------------------------------------------------------------------------
  // Tertiary — Sage
  // ---------------------------------------------------------------------------

  /// Sage — category tags, nature/wellness tones
  static const Color tertiary = Color(0xFF56624D);

  /// Sage fills — chips, category cards
  static const Color tertiaryContainer = Color(0xFFDBE8CD);

  // ---------------------------------------------------------------------------
  // Semantic Colors
  // ---------------------------------------------------------------------------

  /// Error/destructive
  static const Color error = Color(0xFFBA1A1A);

  /// Info blue
  static const Color info = Color(0xFF2196F3);

  // ---------------------------------------------------------------------------
  // Auth context aliases (kept for API compatibility)
  // ---------------------------------------------------------------------------

  /// Auth input surface
  static const Color darkSurface = Color(0xFFFFFFFF);

  /// Auth border
  static const Color darkBorder = Color(0x0F1C1C16);

  // ---------------------------------------------------------------------------
  // Legacy text aliases — kept until widget files are migrated
  // ---------------------------------------------------------------------------

  /// @deprecated Use [onSurface]
  static const Color textPrimary = Color(0xFF1C1C16);

  /// @deprecated Use [onSurfaceVariant]
  static const Color textSecondary = Color(0xFF4C4638);

  /// @deprecated Use [onSurfaceVariant] with reduced opacity
  static const Color textTertiary = Color(0xFF8C8A82);

  /// White text on dark surfaces
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Legacy border aliases — kept until widget files are migrated
  // ---------------------------------------------------------------------------

  /// @deprecated Use [outlineVariant]
  static const Color border = Color(0x0F1C1C16);

  /// Focus border — ink black
  static const Color borderFocus = Color(0xFF1C1C16);

  /// @deprecated Use [error]
  static const Color borderError = Color(0xFFBA1A1A);

  // ---------------------------------------------------------------------------
  // Accent / Badge backgrounds
  // ---------------------------------------------------------------------------

  /// Peach/apricot chip background — category / offer type
  static const Color accentOrange = Color(0xFFF6DDCF);

  /// Peach chip text
  static const Color accentOrangeText = Color(0xFF9A4A20);

  /// Soft yellow — selected card fills, soft chips
  static const Color softYellow = Color(0xFFFFF4C2);

  /// Soft yellow border
  static const Color softYellowBorder = Color(0xFFFFE28C);

  /// Pastel yellow background — referral card alternative styling
  static const Color pastelYellowBg = Color(0xFFFDF6DC);

  /// Pastel yellow border — referral card alternative styling
  static const Color pastelYellowBorder = Color(0xFFF0E4A0);

  // ---------------------------------------------------------------------------
  // Status Badge Colors
  // ---------------------------------------------------------------------------

  static const Color pendingBg = Color(0xFFFFDDAC);
  static const Color pendingText = Color(0xFFD8910B);

  static const Color activeBg = Color(0xFFD4EDDA);
  static const Color activeText = Color(0xFF155724);

  static const Color completedBg = Color(0xFFEDEAE0);
  static const Color completedText = Color(0xFF4C4638);

  static const Color errorBg = Color(0xFFF8D7DA);
  static const Color errorText = Color(0xFF721C24);

  // ---------------------------------------------------------------------------
  // Overlay Colors
  // ---------------------------------------------------------------------------

  /// 30% black overlay — light image scrim
  static const Color overlayDark30 = Color(0x4D000000);

  /// 50% black overlay — standard image scrim
  static const Color overlayDark50 = Color(0x80000000);

  /// 60% black overlay — heavy image scrim
  static const Color overlayDark60 = Color(0x99000000);

  /// 14% white — glass/frosted effect on dark surfaces
  static const Color glassWhite14 = Color(0x24FFFFFF);

  // ---------------------------------------------------------------------------
  // Glass button ink
  // ---------------------------------------------------------------------------

  /// Warm dark ink used on all glass button intents
  static const Color glassInk = Color(0xFF57534B);

  /// Destructive ink for glass buttons
  static const Color glassDestructiveInk = Color(0xFF9B3B3B);

  // ---------------------------------------------------------------------------
  // Navigation Bar
  // ---------------------------------------------------------------------------

  /// Nav bar background — warm yellow (both top and bottom bars)
  static const Color navBarBackground = Color(0xFFFFFFFF);

  /// Ink black — text and icons on yellow bars
  static const Color charcoal = Color(0xFF1C1C16);

  // ---------------------------------------------------------------------------
  // Navigation State Colors
  // ---------------------------------------------------------------------------

  /// Inactive nav icon
  static const Color navInactive = Color(0xFFA99E8B);

  /// Inactive nav label — outline-variant color
  static const Color navInactiveSubtle = Color(0xFFCFC6B3);

  // ---------------------------------------------------------------------------
  // Hairline / UI chrome
  // ---------------------------------------------------------------------------

  /// Hairline border — very subtle card/input borders
  static const Color hairline = Color(0xFFEDE5D5);

  /// Divider
  static const Color divider = Color(0xFFECE4D4);

  /// Text/icon on yellow button surface
  static const Color onYellowButton = Color(0xFF19150F);

  // ---------------------------------------------------------------------------
  // Amber chip palette
  // ---------------------------------------------------------------------------

  /// Amber chip container fill — warm sand (location / venue)
  static const Color amberChipContainer = Color(0xFFF5E8B8);

  /// Amber chip text/icon
  static const Color amberChipText = Color(0xFF7A5C1A);

  // ---------------------------------------------------------------------------
  // Deprecated tokens — kept until widget files are migrated
  // ---------------------------------------------------------------------------

  /// @deprecated Use [secondary]
  static const Color accent = Color(0xFF615B71);

  /// @deprecated Use [secondaryContainer]
  static const Color softAccent = Color(0xFFE5DCF6);

  /// @deprecated Use [surface] or [surfaceContainer]
  static const Color darkBackground = Color(0xFFFDF9F0);

  /// Warm soft orange background — category/offer chips, role badges
  static const Color categoryOrangeBg = Color(0xFFFFF0E8);

  /// Dark orange text — on [categoryOrangeBg] chips
  static const Color categoryOrangeText = Color(0xFFC54000);

  /// Vibrant Kolabing orange — XP rewards, secondary accent, action pills
  /// Matches the orange used in earn_xp_action_card and community_xp_summary_card.
  static const Color orangeVibrant = Color(0xFFFF6114);

  /// Soft orange tint — background fill for orange XP/reward chips
  static const Color softOrangeTint = Color(0xFFFFE7D6);

  /// @deprecated No direct replacement — use [activeBg]/[activeText] or [tertiary]
  static const Color success = Color(0xFF56624D);

  /// @deprecated Use semantic status colors
  static const Color warning = Color(0xFFFBC02D);

  /// @deprecated Use [secondary]
  static const Color onAccent = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // XP / Gamification — mint green sub-identity (community rewards layer only)
  // ---------------------------------------------------------------------------

  /// Mint green — XP progress bar fill, gamification accent
  static const Color xpGreen = Color(0xFF7AE7A3);

  /// Soft mint fill — XP card background
  static const Color xpGreenContainer = Color(0xFFE8F9F1);

  /// Text/icon on mint fill
  static const Color xpGreenOnContainer = Color(0xFF1A6644);

  // ---------------------------------------------------------------------------
  // Category chip palette — Explore card semantic chip colors
  // ---------------------------------------------------------------------------

  /// Soft sky blue fill — Music / Art / Culture / Film / Photo chips; selected states
  static const Color categoryBlueGrey = Color(0xFFDCEBFA);

  /// Text on sky-blue chip fill
  static const Color categoryBlueGreyText = Color(0xFF1A5EA8);

  // ---------------------------------------------------------------------------
  // Gradient
  // ---------------------------------------------------------------------------

  /// Primary gradient — promotional banners and highlight elements only
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE28C), Color(0xFFFFF4C2)],
  );
}
