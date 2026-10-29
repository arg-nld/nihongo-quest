import 'package:flutter/material.dart';

/// Shared visual system for Nihongo Quest: clean, bright, and playful without
/// relying on emoji or decorative noise. Japanese-inspired scenery lives in
/// the map and boss arena; the app chrome stays consistent and readable.
class AppTheme {
  AppTheme._();

  // Base surfaces.
  static const Color paper = Color(0xFFF6F8F2);
  static const Color paperAlt = Color(0xFFEAF0E4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFFCFDF9);

  // Brand palette: forest ink with a lively learning green.
  static const Color indigoInk = Color(0xFF244337);
  static const Color indigoSoft = Color(0xFF638071);
  static const Color matcha = Color(0xFF8BD65D);
  static const Color matchaDark = Color(0xFF4F963C);
  static const Color matchaDeep = Color(0xFF326B31);
  static const Color sakura = Color(0xFFFFD4DC);
  static const Color sakuraDeep = Color(0xFFE7839D);
  static const Color shu = Color(0xFFE85C50);
  static const Color shuSoft = Color(0xFFFCE6E1);

  // Text and state.
  static const Color ink = Color(0xFF252E28);
  static const Color inkMuted = Color(0xFF68766D);
  static const Color locked = Color(0xFFACB8AF);
  static const Color outline = Color(0xFFDCE5D9);
  static const Color shadow = Color(0x142E4B37);

  // Hand-painted map colors.
  static const Color terrainWater = Color(0xFFA1DDE7);
  static const Color terrainWaterDeep = Color(0xFF6BBFCE);
  static const Color terrainMountain = Color(0xFF9FBCCC);
  static const Color terrainSnow = Color(0xFFF9FCFA);
  static const Color terrainForest = Color(0xFF7FB86B);
  static const Color terrainForestDeep = Color(0xFF4F8B55);
  static const Color terrainField = Color(0xFFDCE9A9);
  static const Color terrainPath = Color(0xFFE2C49A);
  static const Color terrainRoof = Color(0xFF667C87);
  static const Color terrainWood = Color(0xFF9D7154);
  static const Color terrainBamboo = Color(0xFF76B96F);

  static Color masteryColor(int tier) => switch (tier) {
        0 => locked,
        1 => shu,
        2 => sakuraDeep,
        3 => matchaDark,
        _ => matchaDark,
      };

  static const Color success = matchaDark;
  static const Color danger = shu;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double radiusCard = 20;
  static const double radiusChip = 14;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: matchaDark,
      brightness: Brightness.light,
      primary: matchaDark,
      onPrimary: Colors.white,
      secondary: indigoInk,
      onSecondary: Colors.white,
      tertiary: sakuraDeep,
      surface: surface,
      onSurface: ink,
      error: shu,
      onError: Colors.white,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SoftPageTransitionsBuilder(),
          TargetPlatform.iOS: _SoftPageTransitionsBuilder(),
          TargetPlatform.macOS: _SoftPageTransitionsBuilder(),
          TargetPlatform.windows: _SoftPageTransitionsBuilder(),
          TargetPlatform.linux: _SoftPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: indigoInk,
        fontFamilyFallback: const [],
      ).copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          color: indigoInk,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: indigoInk,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: indigoInk,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.35,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: indigoInk,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: indigoInk,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.35),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.35),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: outline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: matchaDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: paperAlt,
          disabledForegroundColor: inkMuted,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: matchaDeep, width: 0.8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          foregroundColor: indigoInk,
          side: const BorderSide(color: outline, width: 1.3),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(52, 44),
          foregroundColor: matchaDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: indigoInk,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: indigoInk,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Color(0xFFDDF2CE),
        elevation: 8,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(size: 22)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: paperAlt,
        side: const BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: indigoInk),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: const TextStyle(color: inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: matchaDark, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: shu),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: matchaDark,
        linearTrackColor: paperAlt,
        circularTrackColor: paperAlt,
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: indigoInk,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        minVerticalPadding: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: indigoInk,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static TextStyle caption(BuildContext context) => const TextStyle(
        fontSize: 12,
        color: inkMuted,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle sectionHeader(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w800,
            color: indigoInk,
          );

  static TextStyle japanese(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
            color: ink,
            fontWeight: FontWeight.w700,
          );
}


/// A lightweight fade-and-slide used consistently for pushed routes.
class _SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.025, 0.012),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
