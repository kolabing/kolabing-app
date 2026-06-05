import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/layout.dart';
import '../constants/radius.dart';
import 'color_tokens.dart';
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

        // Runtime color tokens (light set) — resolved via context.colors.xxx
        extensions: const [KolabingColorTokens.light],
      );

  // ---------------------------------------------------------------------------
  // Night Theme (dark mode — primary/default theme)
  // ---------------------------------------------------------------------------

  /// Night (dark) theme. Surfaces are near-black, brand yellow stays #FFE28C,
  /// cards are flat with a 1px hairline, and all buttons are pills.
  static ThemeData get darkTheme {
    const n = KolabingColorTokens.night;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme — night palette
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFE28C),
        onPrimary: Color(0xFF5C4A12),
        primaryContainer: Color(0xFF2C2710),
        onPrimaryContainer: Color(0xFFF5F5F7),
        secondary: Color(0xFFD4C6FF),
        onSecondary: Color(0xFF2B2550),
        surface: Color(0xFF0C0C0E),
        onSurface: Color(0xFFF5F5F7),
        surfaceContainerHighest: Color(0xFF222226),
        error: Color(0xFFE14D3D),
        onError: Color(0xFF0C0C0E),
        outline: Color(0xFF2E2E34),
        outlineVariant: Color(0xFF2A2A2F),
      ),

      // Scaffold — near-black
      scaffoldBackgroundColor: n.background,

      // AppBar — elevated surface, light status-bar icons
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: n.surfaceContainer,
        foregroundColor: n.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: KolabingTextStyles.titleLarge.copyWith(color: n.onSurface),
        iconTheme: IconThemeData(color: n.onSurface, size: 24),
      ),

      // Bottom Navigation — dark bar, light active, muted inactive
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: n.surfaceContainer,
        selectedItemColor: n.onSurface,
        unselectedItemColor: n.navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: KolabingTextStyles.labelSmall,
        unselectedLabelStyle: KolabingTextStyles.labelSmall,
      ),

      // Card — flat, elevated surface, 1px hairline border, radius 16
      cardTheme: CardThemeData(
        color: n.surfaceContainer,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: KolabingRadius.borderRadiusXl,
          side: BorderSide(color: n.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button — pill, yellow, dark amber text
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: n.primary,
          foregroundColor: n.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, KolabingLayout.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: KolabingTextStyles.button,
        ),
      ),

      // Outlined Button — pill, hairline border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: n.onSurface,
          elevation: 0,
          minimumSize: const Size(double.infinity, KolabingLayout.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const StadiumBorder(),
          side: BorderSide(color: n.outlineVariant, width: 1),
          textStyle: KolabingTextStyles.button,
        ),
      ),

      // Text Button — lavender for links
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: n.secondary,
          textStyle: KolabingTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input Decoration — variant fill, outline border, yellow focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: n.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: BorderSide(color: n.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: BorderSide(color: n.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: BorderSide(color: n.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: BorderSide(color: n.borderError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: BorderSide(color: n.borderError, width: 1.5),
        ),
        hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: n.textTertiary),
        labelStyle: KolabingTextStyles.bodyMedium.copyWith(color: n.onSurfaceVariant),
        floatingLabelStyle: KolabingTextStyles.bodySmall.copyWith(color: n.onSurfaceVariant),
        errorStyle: KolabingTextStyles.bodySmall.copyWith(color: n.error),
      ),

      // Chip — sage fill, pill shape
      chipTheme: ChipThemeData(
        backgroundColor: n.tertiaryContainer,
        labelStyle: KolabingTextStyles.labelMedium.copyWith(color: n.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: const StadiumBorder(side: BorderSide.none),
        elevation: 0,
        pressElevation: 0,
      ),

      // Divider — hairline
      dividerTheme: DividerThemeData(color: n.hairline, thickness: 1, space: 1),

      // Dialog — elevated surface
      dialogTheme: DialogThemeData(
        backgroundColor: n.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: KolabingRadius.borderRadiusLg,
          side: BorderSide(color: n.outlineVariant),
        ),
        titleTextStyle: KolabingTextStyles.headlineMedium.copyWith(color: n.onSurface),
        contentTextStyle: KolabingTextStyles.bodyMedium.copyWith(color: n.onSurfaceVariant),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: n.surfaceContainer,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(KolabingRadius.xl)),
        ),
        showDragHandle: true,
        dragHandleColor: n.outlineVariant,
      ),

      // Snackbar — inverse surface
      snackBarTheme: SnackBarThemeData(
        backgroundColor: n.inverseSurface,
        contentTextStyle: KolabingTextStyles.bodyMedium.copyWith(color: n.inverseOnSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: KolabingRadius.borderRadiusSm),
      ),

      // Icon
      iconTheme: IconThemeData(color: n.onSurface, size: 24),

      // Text Theme
      textTheme: _buildTextTheme(n.onSurface),

      // Font
      fontFamily: KolabingTypography.fontBody,

      // Runtime color tokens (night set)
      extensions: const [KolabingColorTokens.night],
    );
  }

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
