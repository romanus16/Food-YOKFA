import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../data/models/categorie.dart';
import '../../data/models/produit.dart';
import '../../data/repositories/menu_repository.dart';
import '../panier/barre_commander.dart';
import '../panier/panier.dart';

/// Produits d'une catégorie, avec un sélecteur de quantité − / +.
class ProduitsScreen extends StatelessWidget {
  const ProduitsScreen({super.key, required this.categorie});

  final Categorie categorie;

  @override
  Widget build(BuildContext context) {
    final menu = context.read<MenuRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(categorie.nom)),
      bottomNavigationBar: const BarreCommander(),
      body: StreamBuilder<List<Produit>>(
        stream: menu.produits(categorie.id),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('Impossible de charger les produits.'),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final produits = snap.data!;
          if (produits.isEmpty) {
            return const Center(
              child: Text('Aucun produit dans cette catégorie pour le moment.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: produits.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) =>
                ProduitTuile(produit: produits[i], icone: categorie.icone),
          );
        },
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _Vignette(url: produit.photoUrl, icone: icone),
      title: Text(produit.nom),
      subtitle: Text(
        produit.disponible ? formatFcfa(produit.prix) : 'Indisponible',
        style: produit.disponible
            ? theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              )
            : theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
      ),
      trailing: produit.disponible
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.outlined(
                  tooltip: 'Retirer un ${produit.nom}',
                  onPressed: q > 0 ? () => panier.retirer(produit) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$q',
                    key: Key('quantite-${produit.id}'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Ajouter un ${produit.nom}',
                  onPressed: () => panier.ajouter(produit),
                  icon: const Icon(Icons.add),
                ),
              ],
            )
          : null,
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette({required this.url, required this.icone});

  final String? url;
  final String icone;

  @override
  Widget build(BuildContext context) {
    final fond = Theme.of(context).colorScheme.surfaceContainerHighest;
    final repli = Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      color: fond,
      child: Text(icone, style: const TextStyle(fontSize: 28)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null || url!.isEmpty
          ? repli
          : Image.network(
              url!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => repli,
            ),
    );
  }
}
