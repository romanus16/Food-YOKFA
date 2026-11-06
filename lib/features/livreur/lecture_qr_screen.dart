import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/demo.dart';

/// Lit le QR code du client et renvoie son contenu (ou `null`).
/// Si la caméra ne marche pas, le code peut être saisi à la main.
class LectureQrScreen extends StatefulWidget {
  const LectureQrScreen({super.key, this.avecCamera = true, this.codeDemo});

  /// `false` dans les tests (pas de caméra) : seule la saisie manuelle reste.
  final bool avecCamera;

  /// En démo, code à saisir pour cette commande (affiché en aide).
  final String? codeDemo;

  @override
  State<LectureQrScreen> createState() => _LectureQrScreenState();
}

class _LectureQrScreenState extends State<LectureQrScreen> {
  MobileScannerController? _camera;
  bool _lu = false;

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

  void _rendre(String code) {
    if (_lu) return;
    _lu = true;
    Navigator.pop(context, code);
  }

  Future<void> _saisir() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogueCode(),
    );
    if (code != null && code.trim().isNotEmpty) _rendre(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR code du client')),
      body: Column(
        children: [
          Expanded(
            child: _camera == null
                ? const Center(child: Icon(Icons.qr_code_scanner, size: 96))
                : MobileScanner(
                    controller: _camera,
                    onDetect: (capture) {
                      final code = capture.barcodes
                          .map((b) => b.rawValue)
                          .whereType<String>()
                          .firstOrNull;
                      if (code != null) _rendre(code);
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
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Visez le QR code affiché sur le téléphone du client.',
                    textAlign: TextAlign.center,
                  ),
                  if (ModeDemo.actif && widget.codeDemo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Démo : saisissez ${widget.codeDemo} à la main.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _saisir,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Saisir le code à la main'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
