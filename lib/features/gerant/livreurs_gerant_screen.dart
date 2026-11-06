import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models/livreur.dart';
import '../../data/repositories/livreur_repository.dart';

/// Onglet « Livreurs » du gérant : demandes à accepter et équipe.
class LivreursGerantScreen extends StatelessWidget {
  const LivreursGerantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<LivreurRepository>();
    return StreamBuilder<List<Livreur>>(
      stream: repo.tous(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final demandes = snap.data!.where((l) => !l.actif).toList();
        final equipe = snap.data!.where((l) => l.actif).toList();
        final theme = Theme.of(context);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            const Card(
              color: YokfaCouleurs.sable,
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Ajouter un livreur'),
                subtitle: Text(
                  'Le livreur ouvre l\'appli → Plus → Espace livreur, crée '
                  'son compte et envoie sa demande. Elle apparaît ici.',
                ),
              ),
            ),
            if (demandes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Demandes à accepter', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final l in demandes)
                Card(
                  child: ListTile(
                    leading: const PastilleIcone(
                      icone: Icons.person_add_alt_1_rounded,
                    ),
                    title: Text(l.nom),
                    subtitle: Text(
                      [
                        l.telephone,
                        l.email,
                      ].where((t) => t.isNotEmpty).join('\n'),
                    ),
                    isThreeLine: l.telephone.isNotEmpty && l.email.isNotEmpty,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Refuser',
                          onPressed: () => repo.retirer(l.uid),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        IconButton.filled(
                          tooltip: 'Accepter ${l.nom}',
                          onPressed: () => repo.activer(l.uid, true),
                          icon: const Icon(Icons.check_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Text('Équipe de livraison', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (equipe.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucun livreur pour le moment.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final l in equipe)
              Card(
                child: ListTile(
                  leading: const PastilleIcone(
                    icone: Icons.delivery_dining_rounded,
                    couleur: YokfaCouleurs.vert,
                  ),
                  title: Text(l.nom),
                  subtitle: l.telephone.isEmpty ? null : Text(l.telephone),
                  trailing: PopupMenuButton<void>(
                    tooltip: 'Options',
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        onTap: () => repo.activer(l.uid, false),
                        child: const Text('Mettre en pause'),
                      ),
                      PopupMenuItem(
                        onTap: () => repo.retirer(l.uid),
                        child: const Text('Retirer de l\'équipe'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
