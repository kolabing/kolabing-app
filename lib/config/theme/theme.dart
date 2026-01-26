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
          secondary: KolabingColors.textSecondary,
          onSecondary: KolabingColors.textOnDark,
          surface: KolabingColors.surface,
          onSurface: KolabingColors.textPrimary,
          surfaceContainerHighest: KolabingColors.surfaceVariant,
          error: KolabingColors.error,
          onError: KolabingColors.textOnDark,
          outline: KolabingColors.border,
          outlineVariant: KolabingColors.borderFocus,
        ),

        // Scaffold
        scaffoldBackgroundColor: KolabingColors.background,

        // AppBar
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: KolabingColors.surface,
          foregroundColor: KolabingColors.textPrimary,
          surfaceTintColor: Colors.transparent,
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

        // Bottom Navigation
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: KolabingColors.surface,
          selectedItemColor: KolabingColors.primary,
          unselectedItemColor: KolabingColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: KolabingTextStyles.labelSmall,
          unselectedLabelStyle: KolabingTextStyles.labelSmall,
        ),

        // Card
        cardTheme: CardThemeData(
          color: KolabingColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusLg,
            side: const BorderSide(color: KolabingColors.border),
          ),
          margin: EdgeInsets.zero,
        ),

        // Elevated Button (Primary)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Outlined Button (Secondary)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: KolabingColors.textPrimary,
            elevation: 0,
            minimumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            side: const BorderSide(color: KolabingColors.border, width: 1.5),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Text Button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: KolabingColors.primary,
            textStyle: KolabingTextStyles.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        // Input Decoration (Light theme)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: KolabingColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
            borderSide: const BorderSide(color: KolabingColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
            borderSide: const BorderSide(
              color: KolabingColors.borderFocus,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
            borderSide: const BorderSide(color: KolabingColors.borderError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
            borderSide: const BorderSide(
              color: KolabingColors.borderError,
              width: 2,
            ),
          ),
          hintStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textTertiary,
          ),
          labelStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textSecondary,
          ),
          errorStyle: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.error,
          ),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: KolabingColors.surfaceVariant,
          labelStyle: KolabingTextStyles.labelSmall,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: KolabingColors.border,
          thickness: 1,
          space: 1,
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
  // Dark Theme (Auth Screens)
  // ---------------------------------------------------------------------------

  /// Dark theme for authentication screens
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // Color scheme
        colorScheme: const ColorScheme.dark(
          primary: KolabingColors.primary,
          onPrimary: KolabingColors.onPrimary,
          primaryContainer: KolabingColors.primaryDark,
          onPrimaryContainer: KolabingColors.onPrimary,
          secondary: KolabingColors.textSecondary,
          onSecondary: KolabingColors.textOnDark,
          surface: KolabingColors.darkSurface,
          onSurface: KolabingColors.textOnDark,
          surfaceContainerHighest: KolabingColors.darkSurface,
          error: KolabingColors.error,
          onError: KolabingColors.textOnDark,
          outline: KolabingColors.darkBorder,
        ),

        // Scaffold
        scaffoldBackgroundColor: KolabingColors.darkBackground,

        // AppBar
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: KolabingColors.textOnDark,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          titleTextStyle: KolabingTextStyles.titleLarge,
          iconTheme: const IconThemeData(
            color: KolabingColors.textOnDark,
            size: 24,
          ),
        ),

        // Elevated Button (Primary - Yellow on dark)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Outlined Button (Secondary on dark)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: KolabingColors.textOnDark,
            elevation: 0,
            minimumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            side: const BorderSide(
              color: KolabingColors.darkBorder,
              width: 1.5,
            ),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Text Button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: KolabingColors.primary,
            textStyle: KolabingTextStyles.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        // Input Decoration (Dark theme)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: KolabingColors.darkSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(color: KolabingColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(color: KolabingColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
            borderSide: const BorderSide(
              color: KolabingColors.borderFocus,
              width: 2,
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
              width: 2,
            ),
          ),
          hintStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textTertiary,
          ),
          labelStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textOnDark,
          ),
          errorStyle: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.error,
          ),
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: KolabingColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusLg,
          ),
          titleTextStyle: KolabingTextStyles.headlineMedium.copyWith(
            color: KolabingColors.textOnDark,
          ),
          contentTextStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textTertiary,
          ),
        ),

        // Bottom Sheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: KolabingColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(KolabingRadius.xl),
            ),
          ),
          showDragHandle: true,
          dragHandleColor: KolabingColors.darkBorder,
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: KolabingColors.surface,
          contentTextStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textPrimary,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
        ),

        // Icon
        iconTheme: const IconThemeData(
          color: KolabingColors.textOnDark,
          size: 24,
        ),

        // Text Theme
        textTheme: _buildTextTheme(KolabingColors.textOnDark),

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
