import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/format.dart';
import '../../data/models/commande.dart';
import '../../data/models/config_paiement.dart';
import '../../data/repositories/commande_repository.dart';
import '../../data/repositories/config_repository.dart';

/// Paiement mobile money d'une commande, puis suivi de son statut.
///
/// V1 sans API opérateur : le client paie sur le compte marchand affiché,
/// saisit la référence de sa transaction, et le gérant valide à la main.
class PaiementScreen extends StatelessWidget {
  const PaiementScreen({super.key, required this.commandeId});

  final String commandeId;

  @override
  Widget build(BuildContext context) {
    final commandes = context.read<CommandeRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ma commande')),
      body: StreamBuilder<Commande?>(
        stream: commandes.suivre(commandeId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('Impossible de charger la commande.'),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = snap.data;
          if (c == null) {
            return const Center(child: Text('Commande introuvable.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _EnTete(commande: c),
              const SizedBox(height: 16),
              switch (c.statut) {
                StatutCommande.enAttentePaiement when c.aEncaisser =>
                  SuiviPayee(commande: c),
                StatutCommande.enAttentePaiement => _APayer(commande: c),
                StatutCommande.payee => SuiviPayee(commande: c),
                StatutCommande.livree => const _Info(
                  icone: Icons.check_circle,
                  texte: 'Commande livrée. Bon appétit !',
                ),
                StatutCommande.annulee => const _Info(
                  icone: Icons.cancel,
                  texte: 'Cette commande a été annulée.',
                ),
              },
            ],
          );
        },
      ),
    );
  }
}

/// Une fois le paiement validé (ou tout de suite pour une commande en
/// espèces) : le QR code à présenter au livreur.
class SuiviPayee extends StatelessWidget {
  const SuiviPayee({super.key, required this.commande});

  final Commande commande;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          commande.aEncaisser
              ? 'Paiement en espèces à la livraison'
              : 'Paiement confirmé',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (commande.aEncaisser)
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Préparez ${formatFcfa(commande.total)} pour le livreur.',
                key: const Key('montant-especes'),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Montrez ce QR code au livreur à la livraison.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            // Fond blanc obligatoire pour que le code reste lisible
            // même en thème sombre.
            color: Colors.white,
            child: QrImageView(
              data: commande.codeQr,
              size: 240,
              backgroundColor: Colors.white,
              semanticsLabel: 'QR code de la commande',
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Secours si la caméra du livreur ne fonctionne pas.
        SelectableText(
          'Code : ${commande.codeQr}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Livraison : ${commande.batiment.libelle}',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.commande});

  final Commande commande;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              commande.statut.libelle,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            for (final l in commande.lignes) Text('${l.quantite} × ${l.nom}'),
            const SizedBox(height: 8),
            Text(
              'Total : ${formatFcfa(commande.total)}',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _APayer extends StatefulWidget {
  const _APayer({required this.commande});

  final Commande commande;

  @override
  State<_APayer> createState() => _APayerState();
}

class _APayerState extends State<_APayer> {
  final _reference = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await context.read<CommandeRepository>().enregistrerReferencePaiement(
        widget.commande.id,
        _reference.text,
      );
    } catch (e) {
      _erreur = e.toString();
    }
    if (mounted) setState(() => _envoi = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    final theme = Theme.of(context);
    if (c.referencePaiement != null) {
      return _Info(
        icone: Icons.hourglass_top,
        texte:
            'Paiement en cours de vérification.\n'
            'Référence : ${c.referencePaiement}\n'
            'Vous serez prévenu ici dès sa validation.',
      );
    }
    return StreamBuilder<ConfigPaiement>(
      stream: context.read<ConfigRepository>().paiement(),
      builder: (context, snap) {
        final numero = snap.data?.numeroPour(c.moyenPaiement) ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Payer par ${c.moyenPaiement.libelle}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '1. Envoyez ${formatFcfa(c.total)} au compte marchand '
              '${c.moyenPaiement.libelle} (${c.moyenPaiement.operateur}) :',
            ),
            const SizedBox(height: 8),
            if (!snap.hasData)
              const LinearProgressIndicator()
            else if (numero.isEmpty)
              Text(
                'Le numéro marchand n\'est pas encore configuré. '
                'Contactez le gérant.',
                style: TextStyle(color: theme.colorScheme.error),
              )
            else
              Card(
                color: theme.colorScheme.primaryContainer,
                child: ListTile(
                  title: Text(
                    numero,
                    key: const Key('numero-marchand'),
                    style: theme.textTheme.headlineSmall,
                  ),
                  trailing: IconButton(
                    tooltip: 'Copier le numéro',
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: numero));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Numéro copié')),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              '2. Saisissez la référence de la transaction reçue par SMS :',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reference,
              decoration: InputDecoration(
                labelText: 'Référence de paiement',
                border: const OutlineInputBorder(),
                errorText: _erreur,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _envoi ? null : _envoyer,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('J\'ai payé'),
            ),
          ],
        );
      },
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icone, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(texte, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
