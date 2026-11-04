import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/identite.dart';
import '../../data/models/commande.dart';
import '../../data/repositories/commande_repository.dart';
import '../lieu/carte.dart';
import '../lieu/choix_lieu_screen.dart';
import '../paiement/paiement_screen.dart';
import '../panier/panier.dart';

/// Formulaire ouvert par « Commander » : heure souhaitée, filière,
/// bâtiment, lieu précis (facultatif) et moyen de paiement, avec le
/// récapitulatif du panier.
class FormulaireCommandeScreen extends StatefulWidget {
  const FormulaireCommandeScreen({super.key, this.maintenant, this.localiser});

  /// Heure de référence (pour les tests). Par défaut l'heure actuelle.
  final DateTime Function()? maintenant;

  /// Position du téléphone pour la carte (pour les tests). Par défaut le GPS.
  final Localiser? localiser;

  @override
  State<FormulaireCommandeScreen> createState() =>
      _FormulaireCommandeScreenState();
}

class _FormulaireCommandeScreenState extends State<FormulaireCommandeScreen> {
  final _form = GlobalKey<FormState>();
  final _filiere = TextEditingController();
  final _repere = TextEditingController();
  LatLng? _point;
  DateTime? _heure;
  Batiment? _batiment;
  MoyenPaiement? _paiement;
  bool _envoi = false;
  bool _tente = false;

  DateTime _now() => (widget.maintenant ?? DateTime.now)();

  @override
  void dispose() {
    _filiere.dispose();
    _repere.dispose();
    super.dispose();
  }

  Future<void> _choisirSurCarte() async {
    final p = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) =>
            ChoixLieuScreen(initial: _point, localiser: widget.localiser),
      ),
    );
    if (p != null && mounted) setState(() => _point = p);
  }

  Future<void> _choisirHeure() async {
    final now = _now();
    final base = _heure ?? now.add(const Duration(minutes: 30));
    final jour = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 7)),
      helpText: 'Jour de livraison',
    );
    if (jour == null || !mounted) return;
    final h = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: 'Heure de livraison',
    );
    if (h == null) return;
    setState(() {
      _heure = DateTime(jour.year, jour.month, jour.day, h.hour, h.minute);
    });
  }

  String? get _erreurHeure {
    if (_heure == null) return 'Choisissez quand vous voulez le plat.';
    if (_heure!.isBefore(_now())) return 'Cette heure est déjà passée.';
    return null;
  }

  Future<void> _valider() async {
    setState(() => _tente = true);
    final formOk = _form.currentState!.validate();
    if (!formOk ||
        _erreurHeure != null ||
        _batiment == null ||
        _paiement == null) {
      return;
    }
    final panier = context.read<Panier>();
    final repo = context.read<CommandeRepository>();
    final identite = context.read<Identite>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _envoi = true);
    try {
      final id = await repo.creer(
        clientId: await identite.clientId(),
        lignes: panier.lignes,
        heureSouhaitee: _heure!,
        filiere: _filiere.text,
        batiment: _batiment!,
        moyenPaiement: _paiement!,
        lieu: LieuLivraison(
          latitude: _point?.latitude,
          longitude: _point?.longitude,
          repere: _repere.text,
        ),
      );
      panier.vider();
      nav.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => PaiementScreen(commandeId: id)),
        (route) => route.isFirst,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('La commande n\'a pas pu être envoyée : $e')),
      );
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final panier = context.watch<Panier>();
    final theme = Theme.of(context);
    final erreurStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.error,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Commander')),
      body: Form(
        key: _form,
        // Colonne (et non ListView) avec des clés : les messages d'erreur
        // insérés ne doivent pas recréer les champs qui suivent.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Votre commande', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (final l in panier.lignes)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(child: Text('${l.quantite} × ${l.nom}')),
                              Text(formatFcfa(l.sousTotal)),
                            ],
                          ),
                        ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            formatFcfa(panier.total),
                            key: const Key('total'),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pour quand voulez-vous le plat ?',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('heure'),
                onPressed: _choisirHeure,
                icon: const Icon(Icons.schedule),
                label: Text(
                  _heure == null
                      ? 'Choisir le jour et l\'heure'
                      : DateFormat('EEEE d MMMM à HH:mm', 'fr').format(_heure!),
                ),
              ),
              if (_tente && _erreurHeure != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_erreurHeure!, style: erreurStyle),
                ),
              const SizedBox(height: 24),
              TextFormField(
                key: const ValueKey('filiere'),
                controller: _filiere,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Filière',
                  hintText: 'Ex. Informatique L2',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Indiquez votre filière.'
                    : null,
              ),
              const SizedBox(height: 24),
              Text('Bâtiment', style: theme.textTheme.titleMedium),
              RadioGroup<Batiment>(
                key: const ValueKey('batiment'),
                groupValue: _batiment,
                onChanged: (v) => setState(() => _batiment = v),
                child: Column(
                  children: [
                    for (final b in Batiment.values)
                      RadioListTile<Batiment>(
                        value: b,
                        title: Text(b.libelle),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              if (_tente && _batiment == null)
                Text('Choisissez un bâtiment.', style: erreurStyle),
              const SizedBox(height: 16),
              Text(
                'Lieu précis (facultatif)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_point == null)
                OutlinedButton.icon(
                  key: const ValueKey('carte'),
                  onPressed: _choisirSurCarte,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Choisir sur la carte'),
                )
              else
                Card(
                  key: const ValueKey('carte'),
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Lieu choisi sur la carte'),
                    subtitle: Text(
                      '${_point!.latitude.toStringAsFixed(5)}, '
                      '${_point!.longitude.toStringAsFixed(5)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Modifier le lieu',
                          onPressed: _choisirSurCarte,
                          icon: const Icon(Icons.edit_location_alt),
                        ),
                        IconButton(
                          tooltip: 'Retirer le lieu',
                          onPressed: () => setState(() => _point = null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('repere'),
                controller: _repere,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Point de repère',
                  hintText: 'Ex. devant l\'amphi B, sous le manguier',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Régler la facture par', style: theme.textTheme.titleMedium),
              RadioGroup<MoyenPaiement>(
                key: const ValueKey('paiement'),
                groupValue: _paiement,
                onChanged: (v) => setState(() => _paiement = v),
                child: Column(
                  children: [
                    for (final m in MoyenPaiement.values)
                      RadioListTile<MoyenPaiement>(
                        value: m,
                        title: Text(m.libelle),
                        subtitle: Text(m.operateur),
                        secondary: Icon(
                          m.estMobileMoney
                              ? Icons.phone_android
                              : Icons.payments_outlined,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              if (_tente && _paiement == null)
                Text('Choisissez un moyen de paiement.', style: erreurStyle),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _envoi ? null : _valider,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: _envoi
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Valider · ${formatFcfa(panier.total)}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
