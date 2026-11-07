import 'package:flutter/material.dart';

/// Couleur principale : l'orange du logo YF.
const Color yokfaSeed = Color(0xFFEE6A06);

/// Palette de l'appli, tirée du logo YF : noir profond, orange, jaune doré
/// et blanc.
abstract final class YokfaCouleurs {
  static const orange = Color(0xFFEE6A06);
  static const orangeFonce = Color(0xFFC2510A);
  static const dore = Color(0xFFFFB21A);
  static const noir = Color(0xFF0B0B0B);
  static const charbon = Color(0xFF1C1C1E);
  static const creme = Color(0xFFFAF8F5);
  static const sable = Color(0xFFFFF0DB);
  static const encre = Color(0xFF141414);
  static const gris = Color(0xFF6E6A66);
  static const vert = Color(0xFF2F9E44);
}

/// Dégradé orange du « F » du logo.
const LinearGradient yokfaDegrade = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFF9500), YokfaCouleurs.orange, Color(0xFFE2480A)],
  stops: [0, 0.5, 1],
);

/// Logo de l'appli (carré noir).
const String yokfaLogo = 'assets/logo/logo.png';

/// Rayon des cartes et des boutons.
const double yokfaRayon = 20;

ThemeData buildTheme() {
  final schema = ColorScheme.fromSeed(
    seedColor: yokfaSeed,
    primary: YokfaCouleurs.orange,
    onPrimary: Colors.white,
    secondary: YokfaCouleurs.vert,
    surface: YokfaCouleurs.creme,
    onSurface: YokfaCouleurs.encre,
    tertiary: YokfaCouleurs.encre,
    onTertiary: Colors.white,
  );
  final base = ThemeData(
    colorScheme: schema,
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: YokfaCouleurs.creme,
  );
  final texte = base.textTheme.apply(
    bodyColor: YokfaCouleurs.encre,
    displayColor: YokfaCouleurs.encre,
  );
  final arrondi = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  return base.copyWith(
    textTheme: texte.copyWith(
      headlineMedium: texte.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: texte.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: texte.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: texte.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: texte.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: YokfaCouleurs.creme,
      foregroundColor: YokfaCouleurs.encre,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: YokfaCouleurs.encre,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(yokfaRayon),
        side: const BorderSide(color: Color(0x14000000)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: arrondi,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: arrondi,
        side: BorderSide(color: schema.outlineVariant),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1F000000)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1F000000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: YokfaCouleurs.orange, width: 2),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: Color(0x1F000000)),
      backgroundColor: Colors.white,
      selectedColor: YokfaCouleurs.sable,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: YokfaCouleurs.encre,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        selectedBackgroundColor: YokfaCouleurs.sable,
        selectedForegroundColor: YokfaCouleurs.orangeFonce,
        side: const BorderSide(color: Color(0x1F000000)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: YokfaCouleurs.noir,
      surfaceTintColor: Colors.transparent,
      indicatorColor: YokfaCouleurs.orange,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: s.contains(WidgetState.selected)
              ? YokfaCouleurs.dore
              : Colors.white.withValues(alpha: 0.7),
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white.withValues(alpha: 0.7),
        ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: YokfaCouleurs.orange,
      unselectedLabelColor: YokfaCouleurs.gris,
      indicatorColor: YokfaCouleurs.orange,
      labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: YokfaCouleurs.orange,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: YokfaCouleurs.encre,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: YokfaCouleurs.gris,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: YokfaCouleurs.dore,
      textColor: YokfaCouleurs.noir,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: YokfaCouleurs.noir,
      actionTextColor: YokfaCouleurs.dore,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0x14000000)),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: YokfaCouleurs.orange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
