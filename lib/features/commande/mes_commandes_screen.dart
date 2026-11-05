import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/identite.dart';
import '../../data/models/commande.dart';
import '../../data/repositories/commande_repository.dart';
import '../paiement/paiement_screen.dart';

/// Commandes du client sur ce téléphone, pour retrouver son QR code.
class MesCommandesScreen extends StatelessWidget {
  const MesCommandesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CommandeRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: FutureBuilder<String>(
        future: context.read<Identite>().clientId(),
        builder: (context, id) {
          if (id.hasError) {
            return const Center(child: Text('Connexion impossible.'));
          }
          if (!id.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<Commande>>(
            stream: repo.duClient(id.data!),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final liste = snap.data!;
              if (liste.isEmpty) {
                return const Center(
                  child: Text('Aucune commande pour le moment.'),
                );
              }
              final f = DateFormat('d MMM à HH:mm', 'fr');
              return ListView.separated(
                itemCount: liste.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = liste[i];
                  return ListTile(
                    leading: Icon(_icone(c.statut)),
                    title: Text(
                      c.lignes
                          .map((l) => '${l.quantite} × ${l.nom}')
                          .join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${c.statut.libelle} · pour le ${f.format(c.heureSouhaitee)}',
                    ),
                    trailing: Text(formatFcfa(c.total)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PaiementScreen(commandeId: c.id),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static IconData _icone(StatutCommande s) => switch (s) {
    StatutCommande.enAttentePaiement => Icons.hourglass_top,
    StatutCommande.payee => Icons.qr_code_2,
    StatutCommande.livree => Icons.check_circle,
    StatutCommande.annulee => Icons.cancel,
  };
}
