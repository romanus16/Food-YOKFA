import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../data/models/commande.dart';
import '../../data/repositories/commande_repository.dart';

class DetailCommandeScreen extends StatelessWidget {
  const DetailCommandeScreen({super.key, required this.commandeId});

  final String commandeId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CommandeRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la commande')),
      body: StreamBuilder<Commande?>(
        stream: repo.suivre(commandeId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Commande inaccessible. Connectez-vous à l\'espace gérant.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = snap.data;
          if (c == null) {
            return const Center(child: Text('Commande introuvable.'));
          }
          final f = DateFormat('EEEE d MMMM à HH:mm', 'fr');
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(c.statut.libelle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final l in c.lignes)
                Row(
                  children: [
                    Expanded(child: Text('${l.quantite} × ${l.nom}')),
                    Text(formatFcfa(l.sousTotal)),
                  ],
                ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text('Total', style: theme.textTheme.titleMedium),
                  ),
                  Text(formatFcfa(c.total), style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              _Info('Pour le', f.format(c.heureSouhaitee)),
              _Info('Filière', c.filiere),
              _Info('Bâtiment', c.batiment.libelle),
              _Info(
                'Paiement',
                '${c.moyenPaiement.libelle} (${c.moyenPaiement.operateur})',
              ),
              if (c.moyenPaiement.estMobileMoney)
                _Info('Référence', c.referencePaiement ?? 'Pas encore saisie'),
              _Info('Commandée le', f.format(c.creeLe)),
              if (c.payeeLe != null) _Info('Payée le', f.format(c.payeeLe!)),
              if (c.livreeLe != null) _Info('Livrée le', f.format(c.livreeLe!)),
              const SizedBox(height: 24),
              if (c.aEncaisser)
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: Text('Espèces : ${formatFcfa(c.total)} à encaisser'),
                    subtitle: const Text(
                      'Le livreur encaisse au moment du scan du QR code.',
                    ),
                  ),
                ),
              if (c.statut == StatutCommande.enAttentePaiement &&
                  c.moyenPaiement.estMobileMoney) ...[
                Text(
                  'Vérifiez sur votre compte ${c.moyenPaiement.libelle} que '
                  '${formatFcfa(c.total)} ont bien été reçus avant de valider.',
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _action(
                    context,
                    () => repo.validerPaiement(c.id),
                    'Paiement validé',
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Valider le paiement'),
                ),
              ],
              if (c.statut == StatutCommande.enAttentePaiement ||
                  c.statut == StatutCommande.payee) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _annuler(context, repo, c),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Annuler la commande'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _annuler(
    BuildContext context,
    CommandeRepository repo,
    Commande c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: Text(
          c.statut == StatutCommande.payee
              ? 'Le client a payé : pensez à le rembourser.'
              : c.aEncaisser
              ? 'La commande ne sera pas livrée.'
              : 'Le client ne pourra plus payer cette commande.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await _action(context, () => repo.annuler(c.id), 'Commande annulée');
    }
  }

  Future<void> _action(
    BuildContext context,
    Future<void> Function() action,
    String succes,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(succes)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _Info extends StatelessWidget {
  const _Info(this.libelle, this.valeur);

  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              libelle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(valeur)),
        ],
      ),
    );
  }
}
