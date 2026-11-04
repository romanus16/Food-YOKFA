import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../commande/formulaire_commande_screen.dart';
import 'panier.dart';

/// Bouton « Commander » en bas de l'écran, visible dès qu'un produit
/// a une quantité supérieure à 0.
class BarreCommander extends StatelessWidget {
  const BarreCommander({super.key});

  @override
  Widget build(BuildContext context) {
    final panier = context.watch<Panier>();
    if (panier.estVide) return const SizedBox.shrink();
    final n = panier.nombreArticles;
    return SafeArea(
      minimum: const EdgeInsets.all(12),
      child: FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FormulaireCommandeScreen(),
          ),
        ),
        child: Row(
          children: [
            Text(
              'Commander',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            ),
            const Spacer(),
            Text('$n article${n > 1 ? 's' : ''} · ${formatFcfa(panier.total)}'),
          ],
        ),
      ),
    );
  }
}
