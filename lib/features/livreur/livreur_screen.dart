import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth_gerant.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models/commande.dart';
import '../../data/models/livreur.dart';
import '../../data/repositories/commande_repository.dart';
import '../../data/repositories/livreur_repository.dart';
import '../gerant/connexion_gerant_screen.dart';
import 'lecture_qr_screen.dart';

/// Entrée de l'espace livreur : connexion, demande d'accès au gérant,
/// puis liste des livraisons confiées.
class LivreurScreen extends StatelessWidget {
  const LivreurScreen({super.key, this.avecCamera = true});

  /// `false` dans les tests (pas de caméra).
  final bool avecCamera;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthGerant>();
    final livreurs = context.read<LivreurRepository>();
    return StreamBuilder<CompteGerant?>(
      stream: auth.compte(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final compte = snap.data;
        if (compte == null) {
          return const ConnexionGerantScreen(
            titre: 'Espace livreur',
            accroche:
                'Retrouvez les commandes à livrer et scannez les QR codes.',
            photo: 'assets/photos/accueil.jpg',
            role: 'livreur',
          );
        }
        return StreamBuilder<Livreur?>(
          stream: livreurs.suivre(compte.uid),
          builder: (context, fiche) {
            if (fiche.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final l = fiche.data;
            if (l == null) return _Demande(compte: compte);
            if (!l.actif) return _EnAttente(livreur: l);
            return EspaceLivreur(livreur: l, avecCamera: avecCamera);
          },
        );
      },
    );
  }
}

class _BoutonQuitter extends StatelessWidget {
  const _BoutonQuitter();

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Se déconnecter',
    icon: const Icon(Icons.logout),
    onPressed: () => context.read<AuthGerant>().deconnexion(),
  );
}

/// Première connexion : le livreur se présente et envoie sa demande.
class _Demande extends StatefulWidget {
  const _Demande({required this.compte});

  final CompteGerant compte;

  @override
  State<_Demande> createState() => _DemandeState();
}

class _DemandeState extends State<_Demande> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _tel = TextEditingController();
  bool _envoi = false;

  @override
  void dispose() {
    _nom.dispose();
    _tel.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _envoi = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<LivreurRepository>().demander(
        uid: widget.compte.uid,
        nom: _nom.text,
        telephone: _tel.text,
        email: widget.compte.email,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('La demande n\'a pas pu être envoyée : $e')),
      );
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devenir livreur'),
        actions: const [_BoutonQuitter()],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const PastilleIcone(icone: Icons.delivery_dining_rounded),
            const SizedBox(height: 16),
            Text(
              'Présentez-vous au gérant',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Le gérant reçoit votre demande et l\'accepte. Vous verrez '
              'ensuite ici les commandes qu\'il vous confie.',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nom,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom et prénom'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Indiquez votre nom.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tel,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Indiquez votre numéro.' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _envoi ? null : _envoyer,
              child: const Text('Envoyer ma demande'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnAttente extends StatelessWidget {
  const _EnAttente({required this.livreur});

  final Livreur livreur;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace livreur'),
        actions: const [_BoutonQuitter()],
      ),
      body: EtatVide(
        icone: Icons.hourglass_top_rounded,
        texte:
            'Merci ${livreur.nom} !\nVotre demande est envoyée. '
            'Le gérant doit l\'accepter avant que vous puissiez livrer.',
      ),
    );
  }
}

/// Commandes confiées au livreur, à livrer.
class EspaceLivreur extends StatelessWidget {
  const EspaceLivreur({
    super.key,
    required this.livreur,
    this.avecCamera = true,
  });

  final Livreur livreur;
  final bool avecCamera;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CommandeRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes livraisons'),
        actions: const [_BoutonQuitter()],
      ),
      body: StreamBuilder<List<Commande>>(
        stream: repo.duLivreur(livreur.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return const EtatVide(
              icone: Icons.wifi_off,
              texte: 'Impossible de charger vos livraisons.',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cmds = snap.data!;
          if (cmds.isEmpty) {
            return EtatVide(
              icone: Icons.delivery_dining_rounded,
              texte:
                  'Bonjour ${livreur.nom}.\nAucune livraison pour le moment : '
                  'le gérant vous confiera les prochaines commandes.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                '${cmds.length} livraison${cmds.length > 1 ? 's' : ''} à faire',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final c in cmds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CarteLivraison(
                    commande: c,
                    livreur: livreur,
                    avecCamera: avecCamera,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CarteLivraison extends StatelessWidget {
  const _CarteLivraison({
    required this.commande,
    required this.livreur,
    required this.avecCamera,
  });

  final Commande commande;
  final Livreur livreur;
  final bool avecCamera;

  Future<void> _livrer(BuildContext context) async {
    final c = commande;
    final repo = context.read<CommandeRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            LectureQrScreen(avecCamera: avecCamera, codeDemo: c.codeQr),
      ),
    );
    if (code == null || !context.mounted) return;
    var encaissees = false;
    if (c.aEncaisser) {
      encaissees =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.payments_outlined, size: 48),
              title: Text('Encaisser ${formatFcfa(c.total)}'),
              content: const Text('Paiement en espèces à la livraison.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Pas encore'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('J\'ai reçu l\'argent'),
                ),
              ],
            ),
          ) ??
          false;
      if (!encaissees) return;
    }
    try {
      await repo.livrerParLivreur(
        c.id,
        code,
        livreurId: livreur.uid,
        especesEncaissees: encaissees,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Commande livrée. Merci !')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = commande;
    final theme = Theme.of(context);
    final heure = DateFormat('HH:mm', 'fr').format(c.heureSouhaitee);
    final itineraire = c.lieu?.itineraire;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const PastilleIcone(icone: Icons.schedule_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pour $heure', style: theme.textTheme.titleMedium),
                      Text('${c.batiment.libelle} · ${c.filiere}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.aEncaisser
                        ? YokfaCouleurs.sable
                        : YokfaCouleurs.vert.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c.aEncaisser
                        ? 'Encaisser ${formatFcfa(c.total)}'
                        : 'Déjà payée',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: c.aEncaisser
                          ? YokfaCouleurs.orangeFonce
                          : YokfaCouleurs.vert,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            for (final l in c.lignes) Text('${l.quantite} × ${l.nom}'),
            if (c.lieu != null && c.lieu!.repere.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 18,
                    color: YokfaCouleurs.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(c.lieu!.repere)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (itineraire != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        itineraire,
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Itinéraire'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _livrer(context),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Livrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
