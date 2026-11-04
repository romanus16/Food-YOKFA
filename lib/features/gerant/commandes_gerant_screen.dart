import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../data/models/commande.dart';
import '../../data/repositories/commande_repository.dart';
import 'detail_commande_screen.dart';

/// Liste des commandes pour le gérant, filtrable par statut et triée par
/// heure de livraison souhaitée.
class CommandesGerantScreen extends StatefulWidget {
  const CommandesGerantScreen({super.key});

  @override
  State<CommandesGerantScreen> createState() => _CommandesGerantScreenState();
}

class _CommandesGerantScreenState extends State<CommandesGerantScreen> {
  StatutCommande? _filtre = StatutCommande.enAttentePaiement;

  static const _filtres = <(String, StatutCommande?)>[
    ('À valider', StatutCommande.enAttentePaiement),
    ('À livrer', StatutCommande.payee),
    ('Livrées', StatutCommande.livree),
    ('Toutes', null),
  ];

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CommandeRepository>();
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              for (final (libelle, statut) in _filtres)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(libelle),
                    selected: _filtre == statut,
                    onSelected: (_) => setState(() => _filtre = statut),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Commande>>(
            key: ValueKey(_filtre),
            stream: repo.toutes(statut: _filtre),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(
                  child: Text('Impossible de charger les commandes.'),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final liste = snap.data!;
              if (liste.isEmpty) {
                return const Center(child: Text('Aucune commande.'));
              }
              return ListView.separated(
                itemCount: liste.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => LigneCommandeGerant(commande: liste[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LigneCommandeGerant extends StatelessWidget {
  const LigneCommandeGerant({super.key, required this.commande});

  final Commande commande;

  @override
  Widget build(BuildContext context) {
    final c = commande;
    final heure = DateFormat('EEE d MMM HH:mm', 'fr').format(c.heureSouhaitee);
    return ListTile(
      title: Text(
        c.lignes.map((l) => '${l.quantite} × ${l.nom}').join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('$heure · ${c.batiment.libelle} · ${c.statut.libelle}'),
      trailing: Text(formatFcfa(c.total)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DetailCommandeScreen(commandeId: c.id),
        ),
      ),
    );
  }
}
