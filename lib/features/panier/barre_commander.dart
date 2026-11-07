import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'panier.dart';
import 'panier_screen.dart';

/// Bouton « Commander » en bas de l'écran, visible dès qu'un produit
/// a une quantité supérieure à 0. Il ouvre le panier (code promo, total).
class BarreCommander extends StatelessWidget {
  const BarreCommander({super.key, this.onPressed});

  /// Action du bouton. Par défaut, ouvre la page Panier.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final panier = context.watch<Panier>();
    if (panier.estVide) return const SizedBox.shrink();
    final n = panier.nombreArticles;
    final theme = Theme.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: yokfaDegrade,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: YokfaCouleurs.orange.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(60),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed:
              onPressed ??
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PanierScreen()),
              ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: YokfaCouleurs.noir.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$n',
                  style: const TextStyle(
                    color: YokfaCouleurs.dore,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Commander',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$n article${n > 1 ? 's' : ''} · ${formatFcfa(panier.total)}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
