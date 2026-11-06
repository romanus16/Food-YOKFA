import 'package:flutter/material.dart';

import 'theme.dart';

/// Message centré avec une icône dans une pastille (liste vide, erreur...).
class EtatVide extends StatelessWidget {
  const EtatVide({super.key, required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: YokfaCouleurs.sable,
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 40, color: YokfaCouleurs.orange),
            ),
            const SizedBox(height: 16),
            Text(
              texte,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: YokfaCouleurs.gris),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte blanche arrondie qui regroupe des options (boutons radio...).
class CarteOptions extends StatelessWidget {
  const CarteOptions({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
    );
  }
}

/// Pastille ronde colorée avec une icône (statut d'une commande...).
class PastilleIcone extends StatelessWidget {
  const PastilleIcone({
    super.key,
    required this.icone,
    this.couleur = YokfaCouleurs.orange,
  });

  final IconData icone;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icone, color: couleur),
    );
  }
}
