import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/models/categorie.dart';
import 'theme.dart';

/// Photos livrées avec l'appli (dossier assets/photos).
abstract final class Photos {
  static const accueil = 'assets/photos/accueil.jpg';

  /// Photo par défaut des catégories du menu d'exemple.
  static const _categories = {
    'nourriture': 'assets/photos/cat_nourriture.jpg',
    'boissons': 'assets/photos/cat_boissons.jpg',
    'friandises': 'assets/photos/cat_friandises.jpg',
    'desserts': 'assets/photos/cat_desserts.jpg',
  };

  /// Photo à afficher pour une catégorie : celle choisie par le gérant,
  /// sinon celle du menu d'exemple, sinon aucune.
  static String? categorie(Categorie c) {
    final choisie = c.photoUrl?.trim();
    if (choisie != null && choisie.isNotEmpty) return choisie;
    return _categories[c.id];
  }
}

/// Photos choisies dans la galerie : elles sont enregistrées dans le menu
/// sous forme de texte `data:image/...;base64,...`. On garde les dernières
/// décodées pour ne pas les décoder à chaque affichage.
final Map<String, Uint8List> _photosDecodees = {};

Uint8List? _decoder(String u) {
  final deja = _photosDecodees.remove(u);
  if (deja != null) return _photosDecodees[u] = deja;
  try {
    final octets = UriData.parse(u).contentAsBytes();
    if (_photosDecodees.length >= 60) {
      _photosDecodees.remove(_photosDecodees.keys.first);
    }
    return _photosDecodees[u] = octets;
  } on FormatException {
    return null;
  }
}

/// Affiche une photo de plat : fichier livré avec l'appli (`assets/...`),
/// photo de la galerie (`data:image/...`) ou adresse web (`https://...`).
/// Sans photo, ou si elle ne charge pas, un fond dégradé avec l'emoji de la
/// catégorie.
class PhotoPlat extends StatelessWidget {
  const PhotoPlat({
    super.key,
    required this.url,
    this.emoji = '🍽️',
    this.tailleEmoji = 32,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final String emoji;
  final double tailleEmoji;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final repli = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3CC), Color(0xFFFFC9A3)],
        ),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: tailleEmoji)),
      ),
    );
    final u = url?.trim() ?? '';
    if (u.isEmpty) return repli;
    Widget erreur(BuildContext _, Object _, StackTrace? _) => repli;
    if (u.startsWith('assets/')) {
      return Image.asset(u, fit: fit, errorBuilder: erreur);
    }
    if (u.startsWith('data:')) {
      final octets = _decoder(u);
      if (octets == null) return repli;
      return Image.memory(
        octets,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: erreur,
      );
    }
    return Image.network(
      u,
      fit: fit,
      errorBuilder: erreur,
      loadingBuilder: (context, child, progression) => progression == null
          ? child
          : const ColoredBox(color: YokfaCouleurs.sable),
    );
  }
}
