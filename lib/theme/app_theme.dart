import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF0F8B8D);
  static const Color secondary = Color(0xFF2563EB);
  static const Color accent = Color(0xFFF97316);

  static const Color backgroundTop = Color(0xFFF4FCFF);
  static const Color backgroundBottom = Color(0xFFF7F2FF);

  static ThemeData lightTheme() => _buildTheme(Brightness.light);

  static ThemeData darkTheme() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );

    final scheme = baseScheme.copyWith(
      primary: isDark ? const Color(0xFF6EE7E8) : primary,
      secondary: isDark ? const Color(0xFF8DB8FF) : secondary,
      tertiary: isDark ? const Color(0xFFFFB27C) : accent,
      surface: isDark ? const Color(0xFF0C1727) : Colors.white,
      surfaceContainerLow:
          isDark ? const Color(0xFF101F33) : const Color(0xFFF8FBFF),
      surfaceContainerHighest:
          isDark ? const Color(0xFF182739) : const Color(0xFFEAF2FB),
      outline: isDark ? const Color(0xFF385067) : const Color(0xFFC4D3E0),
      outlineVariant:
          isDark ? const Color(0xFF2B4054) : const Color(0xFFDCE5EF),
      onPrimary: isDark ? const Color(0xFF082627) : Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: isDark ? const Color(0xFFF7FAFC) : const Color(0xFF081120),
      onSurfaceVariant:
          isDark ? const Color(0xFFA9B8CA) : const Color(0xFF5A6C81),
      shadow: Colors.black,
    );

    final textTheme = _buildTextTheme(brightness).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final surfaceBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.76);
    final fieldFill = isDark
        ? const Color(0xFF111F31).withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.72);
    final shellShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF040A14) : backgroundTop,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark
            ? scheme.surface.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.82),
        shape: shellShape,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF0D1728) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          backgroundColor: WidgetStatePropertyAll(
            isDark
                ? scheme.surfaceContainerLow.withValues(alpha: 0.74)
                : Colors.white.withValues(alpha: 0.66),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(14)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: surfaceBorderColor),
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: isDark
            ? scheme.surfaceContainerLow.withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.8),
        selectedColor: scheme.primary.withValues(alpha: isDark ? 0.26 : 0.15),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFFE2EDF8) : const Color(0xFF081120),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? const Color(0xFF081120) : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        shape: controlShape,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return isDark ? const Color(0xFF8EA3B8) : const Color(0xFFF8FAFC);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.28);
          }
          return scheme.outlineVariant.withValues(alpha: 0.6);
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStatePropertyAll(scheme.primary),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        fillColor: WidgetStatePropertyAll(scheme.primary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.primary.withValues(alpha: 0.14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelSmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF0D1728) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = GoogleFonts.manropeTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    );

    TextStyle headline(TextStyle? style, double size, FontWeight weight) {
      return GoogleFonts.outfit(
        textStyle: style,
        fontSize: size,
        fontWeight: weight,
        height: 1.06,
        letterSpacing: -0.7,
      );
    }

    TextStyle title(TextStyle? style, double size, FontWeight weight) {
      return GoogleFonts.outfit(
        textStyle: style,
        fontSize: size,
        fontWeight: weight,
        height: 1.12,
        letterSpacing: -0.45,
      );
    }

    return base.copyWith(
      displayLarge: headline(base.displayLarge, 56, FontWeight.w800),
      displayMedium: headline(base.displayMedium, 46, FontWeight.w800),
      displaySmall: headline(base.displaySmall, 38, FontWeight.w700),
      headlineLarge: title(base.headlineLarge, 34, FontWeight.w800),
      headlineMedium: title(base.headlineMedium, 30, FontWeight.w700),
      headlineSmall: title(base.headlineSmall, 26, FontWeight.w700),
      titleLarge: title(base.titleLarge, 22, FontWeight.w700),
      titleMedium: title(base.titleMedium, 18, FontWeight.w700),
      titleSmall: title(base.titleSmall, 15, FontWeight.w700),
      bodyLarge: GoogleFonts.manrope(
        textStyle: base.bodyLarge,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: GoogleFonts.manrope(
        textStyle: base.bodyMedium,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: GoogleFonts.manrope(
        textStyle: base.bodySmall,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: GoogleFonts.manrope(
        textStyle: base.labelLarge,
        fontSize: 15,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.08,
      ),
      labelMedium: GoogleFonts.manrope(
        textStyle: base.labelMedium,
        fontSize: 13,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.06,
      ),
      labelSmall: GoogleFonts.manrope(
        textStyle: base.labelSmall,
        fontSize: 11,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.08,
      ),
    );
  }
}
