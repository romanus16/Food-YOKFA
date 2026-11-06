import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
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
  int _filtre = 0;

  /// Les commandes en espèces n'ont pas de paiement à valider : elles vont
  /// directement dans « À livrer ».
  static final _filtres = <(String, bool Function(Commande))>[
    (
      'À valider',
      (c) =>
          c.statut == StatutCommande.enAttentePaiement &&
          c.moyenPaiement.estMobileMoney,
    ),
    ('À livrer', (c) => c.aLivrer),
    ('Livrées', (c) => c.statut == StatutCommande.livree),
    ('Toutes', (_) => true),
  ];

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CommandeRepository>();
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              for (final (i, (libelle, _)) in _filtres.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(libelle),
                    selected: _filtre == i,
                    onSelected: (_) => setState(() => _filtre = i),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Commande>>(
            key: ValueKey(_filtre),
            stream: repo.toutes(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(
                  child: Text('Impossible de charger les commandes.'),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final garder = _filtres[_filtre].$2;
              final liste = snap.data!.where(garder).toList();
              if (liste.isEmpty) {
                return const EtatVide(
                  icone: Icons.inbox_rounded,
                  texte: 'Aucune commande.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: liste.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    final (icone, couleur) = switch (c.statut) {
      StatutCommande.enAttentePaiement when c.aEncaisser => (
        Icons.payments_rounded,
        YokfaCouleurs.vert,
      ),
      StatutCommande.enAttentePaiement => (
        Icons.hourglass_top_rounded,
        YokfaCouleurs.orange,
      ),
      StatutCommande.payee => (
        Icons.delivery_dining_rounded,
        const Color(0xFF1971C2),
      ),
      StatutCommande.livree => (Icons.check_circle_rounded, YokfaCouleurs.vert),
      StatutCommande.annulee => (Icons.cancel_rounded, const Color(0xFFC92A2A)),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: PastilleIcone(icone: icone, couleur: couleur),
        title: Text(
          c.lignes.map((l) => '${l.quantite} × ${l.nom}').join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            heure,
            c.batiment.libelle,
            c.aEncaisser ? 'Espèces à encaisser' : c.statut.libelle,
            if (c.aLivrer)
              c.livreurNom == null
                  ? 'Aucun livreur'
                  : 'Livreur : ${c.livreurNom}',
          ].join(' · '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatFcfa(c.total),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: YokfaCouleurs.orange,
              ),
            ),
            if (c.lieu?.aPosition == true)
              const Tooltip(
                message: 'Lieu précis sur la carte',
                child: Icon(Icons.location_on_rounded, size: 18),
              ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DetailCommandeScreen(commandeId: c.id),
          ),
        ),
      ),
    );
  }
}
