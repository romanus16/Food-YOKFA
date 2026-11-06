import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repositories/promo_repository.dart';
import '../commande/formulaire_commande_screen.dart';
import '../menu/produits_screen.dart';
import 'panier.dart';

/// Panier : produits choisis, code promo et total, puis « Commander ».
class PanierScreen extends StatelessWidget {
  const PanierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final panier = context.watch<Panier>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mon panier')),
      bottomNavigationBar: panier.estVide ? null : const _BoutonCommander(),
      body: panier.estVide
          ? const EtatVide(
              icone: Icons.shopping_basket_outlined,
              texte: 'Votre panier est vide.\nChoisissez des plats sur l\'accueil.',
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final (p, _) in panier.contenu)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProduitTuile(produit: p),
                      ),
                    const SizedBox(height: 4),
                    const CodePromoCarte(),
                    const SizedBox(height: 16),
                    const RecapTotal(),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Champ « Code promo » : saisie et vérification, ou code appliqué.
class CodePromoCarte extends StatefulWidget {
  const CodePromoCarte({super.key});

  @override
  State<CodePromoCarte> createState() => _CodePromoCarteState();
}

class _CodePromoCarteState extends State<CodePromoCarte> {
  final _code = TextEditingController();
  bool _verif = false;
  String? _erreur;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _appliquer() async {
    final panier = context.read<Panier>();
    final promos = context.read<PromoRepository>();
    FocusScope.of(context).unfocus();
    setState(() {
      _verif = true;
      _erreur = null;
    });
    try {
      final promo = await promos.verifier(_code.text, panier.sousTotal);
      panier.appliquerPromo(promo);
      _code.clear();
    } catch (e) {
      _erreur = e is PromoException
          ? e.message
          : 'Impossible de vérifier le code. Vérifiez votre connexion.';
    }
    if (mounted) setState(() => _verif = false);
  }

  @override
  Widget build(BuildContext context) {
    final panier = context.watch<Panier>();
    final promo = panier.promo;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  size: 20,
                  color: YokfaCouleurs.orange,
                ),
                const SizedBox(width: 8),
                Text('Code promo', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (promo != null)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                decoration: BoxDecoration(
                  color: YokfaCouleurs.vert.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: YokfaCouleurs.vert),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${promo.code} · ${promo.description}',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            panier.remise > 0
                                ? 'Vous économisez ${formatFcfa(panier.remise)}'
                                : 'Minimum ${formatFcfa(promo.minimum)} '
                                      'pour ce code',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: panier.retirerPromo,
                      child: const Text('Retirer'),
                    ),
                  ],
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Saisissez votre code',
                        errorText: _erreur,
                        errorMaxLines: 2,
                      ),
                      onSubmitted: (_) => _appliquer(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonal(
                    onPressed: _verif ? null : _appliquer,
                    child: _verif
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Appliquer'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Sous-total, réduction du code promo et total à payer.
class RecapTotal extends StatelessWidget {
  const RecapTotal({super.key});

  @override
  Widget build(BuildContext context) {
    final panier = context.watch<Panier>();
    final theme = Theme.of(context);
    Widget ligne(String libelle, String valeur, {TextStyle? style, Key? key}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(libelle, style: style)),
              Text(valeur, key: key, style: style),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ligne('Sous-total', formatFcfa(panier.sousTotal)),
            if (panier.remise > 0)
              ligne(
                'Code promo ${panier.promo!.code}',
                '- ${formatFcfa(panier.remise)}',
                key: const Key('remise'),
                style: const TextStyle(color: YokfaCouleurs.vert),
              ),
            const Divider(height: 20),
            ligne(
              'Total',
              formatFcfa(panier.total),
              key: const Key('total-panier'),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BoutonCommander extends StatelessWidget {
  const _BoutonCommander();

  @override
  Widget build(BuildContext context) {
    final panier = context.watch<Panier>();
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FormulaireCommandeScreen(),
          ),
        ),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text('Commander · ${formatFcfa(panier.total)}'),
      ),
    );
  }
}
