import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models/commande.dart';
import '../../data/models/livreur.dart';
import '../../data/repositories/commande_repository.dart';
import '../../data/repositories/livreur_repository.dart';
import '../lieu/carte.dart';

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
              if (c.remise > 0) ...[
                Row(
                  children: [
                    const Expanded(child: Text('Sous-total')),
                    Text(formatFcfa(c.sousTotal)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Code promo ${c.codePromo ?? ''}',
                        style: const TextStyle(color: YokfaCouleurs.vert),
                      ),
                    ),
                    Text(
                      '- ${formatFcfa(c.remise)}',
                      style: const TextStyle(color: YokfaCouleurs.vert),
                    ),
                  ],
                ),
              ],
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
              if (c.lieu != null) ...[
                CarteLieu(lieu: c.lieu!),
                const SizedBox(height: 8),
              ],
              _Info(
                'Paiement',
                c.moyenPaiement.estMobileMoney
                    ? '${c.moyenPaiement.libelle} (${c.moyenPaiement.operateur})'
                    : c.moyenPaiement.libelle,
              ),
              if (c.moyenPaiement.estMobileMoney)
                _Info('Référence', c.referencePaiement ?? 'Pas encore saisie'),
              _Info('Commandée le', f.format(c.creeLe)),
              if (c.payeeLe != null) _Info('Payée le', f.format(c.payeeLe!)),
              if (c.livreeLe != null) _Info('Livrée le', f.format(c.livreeLe!)),
              if (c.livreurNom != null) _Info('Livreur', c.livreurNom!),
              const SizedBox(height: 16),
              if (c.aLivrer) ...[
                _CarteLivreur(commande: c),
                const SizedBox(height: 12),
              ],
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

/// Livreur à qui la commande est confiée, avec le bouton pour la confier.
class _CarteLivreur extends StatelessWidget {
  const _CarteLivreur({required this.commande});

  final Commande commande;

  Future<void> _choisir(BuildContext context) async {
    final livreurs = context.read<LivreurRepository>();
    final repo = context.read<CommandeRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final choix = await showModalBottomSheet<(Livreur?,)>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StreamBuilder<List<Livreur>>(
        stream: livreurs.tous(),
        builder: (ctx, snap) {
          final actifs = (snap.data ?? const <Livreur>[])
              .where((l) => l.actif)
              .toList();
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    'Confier la commande à',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (snap.hasData && actifs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucun livreur pour le moment. Ajoutez-en dans '
                      'l\'onglet « Livreurs ».',
                    ),
                  ),
                for (final l in actifs)
                  ListTile(
                    leading: const Icon(Icons.delivery_dining_rounded),
                    title: Text(l.nom),
                    subtitle: l.telephone.isEmpty ? null : Text(l.telephone),
                    trailing: l.uid == commande.livreurId
                        ? const Icon(Icons.check, color: YokfaCouleurs.vert)
                        : null,
                    onTap: () => Navigator.pop(ctx, (l,)),
                  ),
                if (commande.livreurId != null)
                  ListTile(
                    leading: const Icon(Icons.undo_rounded),
                    title: const Text('Ne plus la confier'),
                    onTap: () => Navigator.pop(ctx, (null,)),
                  ),
              ],
            ),
          );
        },
      ),
    );
    if (choix == null) return;
    try {
      await repo.confier(commande.id, choix.$1);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            choix.$1 == null
                ? 'La commande n\'est plus confiée.'
                : 'Commande confiée à ${choix.$1!.nom}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nom = commande.livreurNom;
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.delivery_dining_rounded,
          color: nom == null ? YokfaCouleurs.gris : YokfaCouleurs.orange,
          size: 30,
        ),
        title: Text(nom == null ? 'Aucun livreur' : 'Confiée à $nom'),
        subtitle: Text(
          nom == null
              ? 'Confiez-la à un livreur pour qu\'il la voie dans son espace.'
              : 'Le livreur la voit dans son espace et scanne le QR code.',
        ),
        trailing: FilledButton.tonal(
          onPressed: () => _choisir(context),
          child: Text(nom == null ? 'Confier' : 'Changer'),
        ),
      ),
    );
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
