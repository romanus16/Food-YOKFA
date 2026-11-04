import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../data/models/commande.dart';
import '../../data/repositories/commande_repository.dart';

/// Scan du QR code du client à la livraison.
/// Un code valide passe la commande au statut « Livrée ».
class ScanLivraisonScreen extends StatefulWidget {
  const ScanLivraisonScreen({super.key, this.avecCamera = true});

  /// `false` dans les tests (pas de caméra) : seule la saisie manuelle reste.
  final bool avecCamera;

  @override
  State<ScanLivraisonScreen> createState() => _ScanLivraisonScreenState();
}

class _ScanLivraisonScreenState extends State<ScanLivraisonScreen> {
  MobileScannerController? _camera;
  bool _occupe = false;

  @override
  void initState() {
    super.initState();
    if (widget.avecCamera) {
      _camera = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _traiter(String code) async {
    if (_occupe) return;
    final repo = context.read<CommandeRepository>();
    setState(() => _occupe = true);
    await _camera?.stop();
    Commande? livree;
    String? erreur;
    try {
      final c = await repo.chercherParCode(code);
      var encaissees = false;
      if (c.aEncaisser) {
        if (!mounted) return;
        encaissees = await _confirmerEncaissement(c);
        if (!encaissees) {
          if (mounted) setState(() => _occupe = false);
          await _camera?.start();
          return;
        }
      }
      livree = await repo.confirmerLivraison(
        code,
        especesEncaissees: encaissees,
      );
    } catch (e) {
      erreur = e.toString();
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          livree != null ? Icons.check_circle : Icons.error,
          color: livree != null
              ? Colors.green
              : Theme.of(ctx).colorScheme.error,
          size: 48,
        ),
        title: Text(livree != null ? 'Commande livrée' : 'QR code refusé'),
        content: Text(
          livree != null
              ? '${livree.lignes.map((l) => '${l.quantite} × ${l.nom}').join('\n')}'
                    '\n\n${livree.batiment.libelle} · ${formatFcfa(livree.total)}'
              : erreur!,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Scanner un autre code'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _occupe = false);
    await _camera?.start();
  }

  /// Commande en espèces : le livreur confirme avoir reçu le montant.
  Future<bool> _confirmerEncaissement(Commande c) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.payments_outlined, size: 48),
        title: Text('Encaisser ${formatFcfa(c.total)}'),
        content: Text(
          'Paiement en espèces.\n\n'
          '${c.lignes.map((l) => '${l.quantite} × ${l.nom}').join('\n')}',
        ),
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
    );
    return ok ?? false;
  }

  Future<void> _saisieManuelle() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogueCode(),
    );
    if (code != null) await _traiter(code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _camera == null
              ? const Center(child: Icon(Icons.qr_code_scanner, size: 96))
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _camera,
                      onDetect: (capture) {
                        final code = capture.barcodes
                            .map((b) => b.rawValue)
                            .whereType<String>()
                            .firstOrNull;
                        if (code != null) _traiter(code);
                      },
                      errorBuilder: (context, error) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Caméra indisponible (${error.errorCode.name}). '
                            'Autorisez la caméra ou saisissez le code.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    if (_occupe)
                      const ColoredBox(
                        color: Colors.black45,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Visez le QR code affiché sur le téléphone du client.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _occupe ? null : _saisieManuelle,
                icon: const Icon(Icons.keyboard),
                label: const Text('Saisir le code à la main'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogueCode extends StatefulWidget {
  const _DialogueCode();

  @override
  State<_DialogueCode> createState() => _DialogueCodeState();
}

class _DialogueCodeState extends State<_DialogueCode> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Saisir le code'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Code de la commande'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
