import 'package:flutter/material.dart';

/// Couleur principale de l'application (à ajuster avec l'identité visuelle).
const Color yokfaSeed = Color(0xFFE65100);

ThemeData buildTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: yokfaSeed),
    useMaterial3: true,
  );
}
