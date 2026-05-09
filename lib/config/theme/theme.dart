import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/radius.dart';
import 'colors.dart';
import 'typography.dart';

/// Kolabing theme configuration
///
/// Provides complete ThemeData for the app including light and dark themes.
abstract final class KolabingTheme {
  // ---------------------------------------------------------------------------
  // Light Theme (Main App)
  // ---------------------------------------------------------------------------

  /// Light theme for the main application screens
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Color scheme
        colorScheme: const ColorScheme.light(
          primary: KolabingColors.primary,
          onPrimary: KolabingColors.onPrimary,
          primaryContainer: KolabingColors.softYellow,
          onPrimaryContainer: KolabingColors.textPrimary,
          secondary: KolabingColors.accent,
          onSecondary: KolabingColors.textOnDark,
          surface: KolabingColors.surface,
          onSurface: KolabingColors.textPrimary,
          surfaceContainerHighest: KolabingColors.surfaceVariant,
          error: KolabingColors.error,
          onError: KolabingColors.textOnDark,
          outline: KolabingColors.border,
          outlineVariant: KolabingColors.border,
        ),

        // Scaffold — warm beige
        scaffoldBackgroundColor: KolabingColors.background,

        // AppBar — beige, no elevation, no divider
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: KolabingColors.background,
          foregroundColor: KolabingColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          titleTextStyle: KolabingTextStyles.titleLarge,
          iconTheme: const IconThemeData(
            color: KolabingColors.textPrimary,
            size: 24,
          ),
        ),

        // Bottom Navigation — card surface, yellow active
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: KolabingColors.surface,
          selectedItemColor: KolabingColors.textPrimary,
          unselectedItemColor: KolabingColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: KolabingTextStyles.labelSmall,
          unselectedLabelStyle: KolabingTextStyles.labelSmall,
        ),

        // Card — white, no elevation, warm-grey border only
        cardTheme: CardThemeData(
          color: KolabingColors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusLg,
            side: const BorderSide(color: KolabingColors.border),
          ),
          margin: EdgeInsets.zero,
        ),

        // Elevated Button (Primary) — no glow, no shadow, no uppercase
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Outlined Button (Secondary) — subtle border, no shadow
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: KolabingColors.textPrimary,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            side: const BorderSide(color: KolabingColors.border, width: 1),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Text Button — purple for links
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: KolabingColors.accent,
            textStyle: KolabingTextStyles.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        // Input Decoration — pure white fill, subtle border, black on focus
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: KolabingColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(color: KolabingColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(color: KolabingColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(
              color: KolabingColors.borderFocus,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(color: KolabingColors.borderError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(
              color: KolabingColors.borderError,
              width: 1.5,
            ),
          ),
          hintStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textTertiary,
          ),
          labelStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textSecondary,
          ),
          floatingLabelStyle: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.textSecondary,
          ),
          errorStyle: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.error,
          ),
        ),

        // Chip — warm surface, no shadow
        chipTheme: ChipThemeData(
          backgroundColor: KolabingColors.surfaceVariant,
          labelStyle: KolabingTextStyles.labelSmall,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            side: const BorderSide(color: KolabingColors.border),
          ),
          elevation: 0,
          pressElevation: 0,
        ),

        // Divider — warm grey
        dividerTheme: const DividerThemeData(
          color: KolabingColors.border,
          thickness: 1,
          space: 1,
        ),

        // Dialog — white surface
        dialogTheme: DialogThemeData(
          backgroundColor: KolabingColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusLg,
            side: const BorderSide(color: KolabingColors.border),
          ),
          titleTextStyle: KolabingTextStyles.headlineMedium.copyWith(
            color: KolabingColors.textPrimary,
          ),
          contentTextStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textSecondary,
          ),
        ),

        // Bottom Sheet — white, no heavy shadow
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: KolabingColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(KolabingRadius.xl),
            ),
          ),
          showDragHandle: true,
          dragHandleColor: KolabingColors.border,
        ),

        // Snackbar — near-black (the one place we use dark fill)
        snackBarTheme: SnackBarThemeData(
          backgroundColor: KolabingColors.textPrimary,
          contentTextStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textOnDark,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
        ),

        // Icon
        iconTheme: const IconThemeData(
          color: KolabingColors.textPrimary,
          size: 24,
        ),

        // Text Theme
        textTheme: _buildTextTheme(KolabingColors.textPrimary),

        // Font — Inter everywhere
        fontFamily: KolabingTypography.fontBody,
      );

  // ---------------------------------------------------------------------------
  // Auth Theme (same as light — warm beige, no black backgrounds)
  // ---------------------------------------------------------------------------

  /// Auth screens share the same warm palette as the main app.
  /// This getter is kept for API compatibility; routes that previously used
  /// a "dark" theme now render in the unified beige theme.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Color scheme — identical to light theme
        colorScheme: const ColorScheme.light(
          primary: KolabingColors.primary,
          onPrimary: KolabingColors.onPrimary,
          primaryContainer: KolabingColors.softYellow,
          onPrimaryContainer: KolabingColors.textPrimary,
          secondary: KolabingColors.accent,
          onSecondary: KolabingColors.textOnDark,
          surface: KolabingColors.surface,
          onSurface: KolabingColors.textPrimary,
          surfaceContainerHighest: KolabingColors.surfaceVariant,
          error: KolabingColors.error,
          onError: KolabingColors.textOnDark,
          outline: KolabingColors.border,
          outlineVariant: KolabingColors.border,
        ),

        // Scaffold — warm beige
        scaffoldBackgroundColor: KolabingColors.background,

        // AppBar — beige, transparent
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: KolabingColors.background,
          foregroundColor: KolabingColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          titleTextStyle: KolabingTextStyles.titleLarge,
          iconTheme: const IconThemeData(
            color: KolabingColors.textPrimary,
            size: 24,
          ),
        ),

        // Elevated Button — no glow, no shadow
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Outlined Button — subtle warm-grey border
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: KolabingColors.textPrimary,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            side: const BorderSide(color: KolabingColors.border, width: 1),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Text Button — purple for links
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: KolabingColors.accent,
            textStyle: KolabingTextStyles.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        // Input Decoration — white fill, warm-grey border, black focus
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: KolabingColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(color: KolabingColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(color: KolabingColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(
              color: KolabingColors.borderFocus,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(color: KolabingColors.borderError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(
              color: KolabingColors.borderError,
              width: 1.5,
            ),
          ),
          hintStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textTertiary,
          ),
          labelStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textSecondary,
          ),
          floatingLabelStyle: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.textSecondary,
          ),
          errorStyle: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.error,
          ),
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: KolabingColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusLg,
          ),
          titleTextStyle: KolabingTextStyles.headlineMedium.copyWith(
            color: KolabingColors.textPrimary,
          ),
          contentTextStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textSecondary,
          ),
        ),

        // Bottom Sheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: KolabingColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(KolabingRadius.xl),
            ),
          ),
          showDragHandle: true,
          dragHandleColor: KolabingColors.border,
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: KolabingColors.textPrimary,
          contentTextStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textOnDark,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
        ),

        // Icon
        iconTheme: const IconThemeData(
          color: KolabingColors.textPrimary,
          size: 24,
        ),

        // Text Theme
        textTheme: _buildTextTheme(KolabingColors.textPrimary),

        // Font
        fontFamily: KolabingTypography.fontBody,
      );

  // ---------------------------------------------------------------------------
  // Helper Methods
  // ---------------------------------------------------------------------------

  /// Build text theme with appropriate text color
  static TextTheme _buildTextTheme(Color textColor) => TextTheme(
        displayLarge: KolabingTextStyles.displayLarge.copyWith(color: textColor),
        displayMedium:
            KolabingTextStyles.displayMedium.copyWith(color: textColor),
        displaySmall: KolabingTextStyles.displaySmall.copyWith(color: textColor),
        headlineLarge:
            KolabingTextStyles.headlineLarge.copyWith(color: textColor),
        headlineMedium:
            KolabingTextStyles.headlineMedium.copyWith(color: textColor),
        headlineSmall:
            KolabingTextStyles.headlineSmall.copyWith(color: textColor),
        titleLarge: KolabingTextStyles.titleLarge.copyWith(color: textColor),
        titleMedium: KolabingTextStyles.titleMedium.copyWith(color: textColor),
        titleSmall: KolabingTextStyles.titleSmall.copyWith(color: textColor),
        bodyLarge: KolabingTextStyles.bodyLarge.copyWith(color: textColor),
        bodyMedium: KolabingTextStyles.bodyMedium.copyWith(color: textColor),
        bodySmall: KolabingTextStyles.bodySmall.copyWith(color: textColor),
        labelLarge: KolabingTextStyles.labelLarge.copyWith(color: textColor),
        labelMedium: KolabingTextStyles.labelMedium.copyWith(color: textColor),
        labelSmall: KolabingTextStyles.labelSmall.copyWith(color: textColor),
      );
}
