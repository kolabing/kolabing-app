import 'package:flutter/material.dart';
import '../../config/theme/typography.dart';
import 'package:flutter/services.dart';

import '../constants/layout.dart';
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
          onPrimaryContainer: KolabingColors.onSurface,
          secondary: KolabingColors.secondary,
          onSecondary: KolabingColors.textOnDark,
          surface: KolabingColors.surface,
          onSurface: KolabingColors.onSurface,
          surfaceContainerHighest: KolabingColors.surfaceVariant,
          error: KolabingColors.error,
          onError: KolabingColors.textOnDark,
          outline: KolabingColors.darkBorder,
          outlineVariant: KolabingColors.darkBorder,
        ),

        // Scaffold — warm beige
        scaffoldBackgroundColor: KolabingColors.background,

        // AppBar — yellow, no elevation
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: KolabingColors.navBarBackground,
          foregroundColor: KolabingColors.charcoal,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          titleTextStyle: KolabingTextStyles.labelLarge.copyWith(color: KolabingColors.charcoal, letterSpacing: 1.5),
          iconTheme: const IconThemeData(
            color: KolabingColors.charcoal,
            size: 24,
          ),
        ),

        // Bottom Navigation — yellow bar, charcoal active, muted inactive
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: KolabingColors.navBarBackground,
          selectedItemColor: KolabingColors.charcoal,
          unselectedItemColor: KolabingColors.navInactive,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: KolabingTextStyles.labelSmall,
          unselectedLabelStyle: KolabingTextStyles.labelSmall,
        ),

        // Card — contrasting surface, no elevation, no border
        cardTheme: CardThemeData(
          color: KolabingColors.surfaceContainer,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusXl,
            side: BorderSide.none,
          ),
          margin: EdgeInsets.zero,
        ),

        // Elevated Button (Primary) — pill shape, yellow, charcoal text
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.navBarBackground,
            foregroundColor: KolabingColors.charcoal,
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, KolabingLayout.buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: const StadiumBorder(),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Outlined Button (Secondary) — pill shape, charcoal border
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: KolabingColors.charcoal,
            elevation: 0,
            minimumSize: const Size(double.infinity, KolabingLayout.buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: const StadiumBorder(),
            side: const BorderSide(color: KolabingColors.charcoal, width: 1),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Text Button — purple for links
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: KolabingColors.secondary,
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
            color: KolabingColors.onSurfaceVariant,
          ),
          floatingLabelStyle: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.onSurfaceVariant,
          ),
          errorStyle: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.error,
          ),
        ),

        // Chip — sage fill, pill shape, no border
        chipTheme: ChipThemeData(
          backgroundColor: KolabingColors.tertiaryContainer,
          labelStyle: KolabingTextStyles.labelMedium.copyWith(
            color: KolabingColors.onSurface,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: const StadiumBorder(side: BorderSide.none),
          elevation: 0,
          pressElevation: 0,
        ),

        // Divider — warm grey
        dividerTheme: const DividerThemeData(
          color: KolabingColors.darkBorder,
          thickness: 1,
          space: 1,
        ),

        // Dialog — white surface
        dialogTheme: DialogThemeData(
          backgroundColor: KolabingColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusLg,
            side: const BorderSide(color: KolabingColors.darkBorder),
          ),
          titleTextStyle: KolabingTextStyles.headlineMedium.copyWith(
            color: KolabingColors.onSurface,
          ),
          contentTextStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.onSurfaceVariant,
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
          dragHandleColor: KolabingColors.darkBorder,
        ),

        // Snackbar — near-black (the one place we use dark fill)
        snackBarTheme: SnackBarThemeData(
          backgroundColor: KolabingColors.onSurface,
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
          color: KolabingColors.onSurface,
          size: 24,
        ),

        // Text Theme
        textTheme: _buildTextTheme(KolabingColors.onSurface),

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
          onPrimaryContainer: KolabingColors.onSurface,
          secondary: KolabingColors.secondary,
          onSecondary: KolabingColors.textOnDark,
          surface: KolabingColors.surface,
          onSurface: KolabingColors.onSurface,
          surfaceContainerHighest: KolabingColors.surfaceVariant,
          error: KolabingColors.error,
          onError: KolabingColors.textOnDark,
          outline: KolabingColors.darkBorder,
          outlineVariant: KolabingColors.darkBorder,
        ),

        // Scaffold — warm beige
        scaffoldBackgroundColor: KolabingColors.background,

        // AppBar — beige, transparent
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: KolabingColors.background,
          foregroundColor: KolabingColors.onSurface,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          titleTextStyle: KolabingTextStyles.titleLarge,
          iconTheme: const IconThemeData(
            color: KolabingColors.onSurface,
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
            foregroundColor: KolabingColors.onSurface,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            side: const BorderSide(color: KolabingColors.darkBorder, width: 1),
            textStyle: KolabingTextStyles.button,
          ),
        ),

        // Text Button — purple for links
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: KolabingColors.secondary,
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
            color: KolabingColors.onSurfaceVariant,
          ),
          floatingLabelStyle: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.onSurfaceVariant,
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
            color: KolabingColors.onSurface,
          ),
          contentTextStyle: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.onSurfaceVariant,
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
          dragHandleColor: KolabingColors.darkBorder,
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: KolabingColors.onSurface,
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
          color: KolabingColors.onSurface,
          size: 24,
        ),

        // Text Theme
        textTheme: _buildTextTheme(KolabingColors.onSurface),

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
