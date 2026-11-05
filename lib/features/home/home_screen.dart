import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/categorie.dart';
import '../../data/repositories/menu_repository.dart';
import '../commande/mes_commandes_screen.dart';
import '../menu/produits_screen.dart';
import '../panier/barre_commander.dart';

/// Accueil : les catégories du menu sous forme de boutons.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = context.read<MenuRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food YOKFA'),
        actions: [
          IconButton(
            tooltip: 'Mes commandes',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MesCommandesScreen(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BarreCommander(),
      body: StreamBuilder<List<Categorie>>(
        stream: menu.categories(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const _Message(
              icone: Icons.wifi_off,
              texte: 'Impossible de charger le menu. Vérifiez votre connexion.',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snap.data!;
          if (categories.isEmpty) {
            return const _Message(
              icone: Icons.restaurant_menu,
              texte: 'Le menu n\'est pas encore disponible.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Que voulez-vous commander ?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final c in categories) _CategorieTuile(categorie: c),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategorieTuile extends StatelessWidget {
  const _CategorieTuile({required this.categorie});

  final Categorie categorie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProduitsScreen(categorie: categorie),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(categorie.icone, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              categorie.nom,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48),
            const SizedBox(height: 12),
            Text(texte, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
