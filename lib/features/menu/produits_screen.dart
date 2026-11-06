import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/photo.dart';
import '../../core/theme.dart';
import '../../data/models/categorie.dart';
import '../../data/models/produit.dart';
import '../../data/repositories/menu_repository.dart';
import '../panier/barre_commander.dart';
import '../panier/panier.dart';

/// Produits d'une catégorie, en cartes photo avec un sélecteur − / +.
class ProduitsScreen extends StatelessWidget {
  const ProduitsScreen({super.key, required this.categorie});

  final Categorie categorie;

  @override
  Widget build(BuildContext context) {
    final menu = context.read<MenuRepository>();
    return Scaffold(
      bottomNavigationBar: const BarreCommander(),
      body: StreamBuilder<List<Produit>>(
        stream: menu.produits(categorie.id),
        builder: (context, snap) {
          final Widget corps;
          if (snap.hasError) {
            corps = const _Vide(texte: 'Impossible de charger les produits.');
          } else if (!snap.hasData) {
            corps = const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snap.data!.isEmpty) {
            corps = const _Vide(
              texte: 'Aucun produit dans cette catégorie pour le moment.',
            );
          } else {
            final produits = snap.data!;
            corps = SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              // Peu de produits par catégorie : tout est construit d'un coup.
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    for (final p in produits)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProduitTuile(produit: p, icone: categorie.icone),
                      ),
                  ],
                ),
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                backgroundColor: YokfaCouleurs.encre,
                foregroundColor: Colors.white,
                leading: const Padding(
                  padding: EdgeInsets.all(6),
                  child: _FondBouton(child: BackButton(color: Colors.white)),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 64,
                    bottom: 16,
                  ),
                  title: Text(
                    categorie.nom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PhotoPlat(
                        url: Photos.categorie(categorie),
                        emoji: categorie.icone,
                        tailleEmoji: 72,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x88000000),
                              Color(0x00000000),
                              Color(0xCC000000),
                            ],
                            stops: [0, 0.4, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              corps,
            ],
          );
        },
      ),
    );
  }
}

class _FondBouton extends StatelessWidget {
  const _FondBouton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

class _Vide extends StatelessWidget {
  const _Vide({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(texte, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class ProduitTuile extends StatelessWidget {
  const ProduitTuile({super.key, required this.produit, this.icone = '🍽️'});

  final Produit produit;
  final String icone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panier = context.watch<Panier>();
    final q = panier.quantite(produit.id);
    final choisi = q > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(yokfaRayon),
        border: Border.all(
          color: choisi ? YokfaCouleurs.orange : const Color(0x12000000),
          width: choisi ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 84,
              height: 84,
              child: Opacity(
                opacity: produit.disponible ? 1 : 0.45,
                child: PhotoPlat(url: produit.photoUrl, emoji: icone),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                if (produit.disponible)
                  Text(
                    formatFcfa(produit.prix),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: YokfaCouleurs.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Indisponible',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (produit.disponible) ...[
            const SizedBox(width: 8),
            _Selecteur(produit: produit, quantite: q),
          ],
        ],
      ),
    );
  }
}

/// Pilule − quantité + ; seulement + tant que rien n'est choisi.
class _Selecteur extends StatelessWidget {
  const _Selecteur({required this.produit, required this.quantite});

  final Produit produit;
  final int quantite;

  @override
  Widget build(BuildContext context) {
    final panier = context.read<Panier>();
    final plus = IconButton.filled(
      tooltip: 'Ajouter un ${produit.nom}',
      onPressed: () => panier.ajouter(produit),
      icon: const Icon(Icons.add_rounded),
      style: IconButton.styleFrom(
        backgroundColor: YokfaCouleurs.orange,
        minimumSize: const Size(38, 38),
        fixedSize: const Size(38, 38),
      ),
    );
    if (quantite == 0) return plus;
    return Container(
      decoration: BoxDecoration(
        color: YokfaCouleurs.sable,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Retirer un ${produit.nom}',
            onPressed: () => panier.retirer(produit),
            icon: const Icon(Icons.remove_rounded),
            color: YokfaCouleurs.orangeFonce,
            style: IconButton.styleFrom(fixedSize: const Size(38, 38)),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantite',
              key: Key('quantite-${produit.id}'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          plus,
        ],
      ),
    );
  }
}
