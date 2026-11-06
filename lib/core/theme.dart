import 'package:flutter/material.dart';

/// Couleur principale : orange piment.
const Color yokfaSeed = Color(0xFFE8590C);

/// Palette de l'appli.
abstract final class YokfaCouleurs {
  static const orange = Color(0xFFE8590C);
  static const orangeFonce = Color(0xFFC2410C);
  static const creme = Color(0xFFFFF8F2);
  static const sable = Color(0xFFFCEBDC);
  static const encre = Color(0xFF2B1D16);
  static const gris = Color(0xFF7C6A60);
  static const vert = Color(0xFF2F9E44);
}

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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: YokfaCouleurs.sable,
      elevation: 3,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? YokfaCouleurs.orangeFonce
              : YokfaCouleurs.gris,
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
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: YokfaCouleurs.encre,
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
