import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/photo.dart';
import '../../core/theme.dart';

/// Taille maximale d'une photo de la galerie, une fois réduite. La photo est
/// enregistrée dans le menu (Firestore limite un document à 1 Mo).
const int tailleMaxPhoto = 600 * 1024;

/// Transforme les octets d'une image en texte `data:image/...;base64,...`,
/// enregistrable dans le menu et lisible par [PhotoPlat].
String photoEnTexte(Uint8List octets, {String? type}) {
  final png =
      octets.length > 4 &&
      octets[0] == 0x89 &&
      octets[1] == 0x50 &&
      octets[2] == 0x4E &&
      octets[3] == 0x47;
  final mime = type ?? (png ? 'image/png' : 'image/jpeg');
  return 'data:$mime;base64,${base64Encode(octets)}';
}

/// Aperçu de la photo avec les boutons « Galerie », « Retirer » et, en
/// option, un champ pour coller un lien internet.
class ChoixPhoto extends StatefulWidget {
  const ChoixPhoto({
    super.key,
    required this.photo,
    required this.onChanged,
    this.emoji = '🍽️',
  });

  final String? photo;
  final String emoji;
  final ValueChanged<String?> onChanged;

  @override
  State<ChoixPhoto> createState() => _ChoixPhotoState();
}

class _ChoixPhotoState extends State<ChoixPhoto> {
  late final _lien = TextEditingController(
    text: _estLien(widget.photo) ? widget.photo : '',
  );
  late bool _lienOuvert = _estLien(widget.photo);
  bool _chargement = false;

  static bool _estLien(String? p) =>
      p != null && (p.startsWith('http://') || p.startsWith('https://'));

  @override
  void dispose() {
    _lien.dispose();
    super.dispose();
  }

  void _message(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _galerie() async {
    XFile? fichier;
    try {
      fichier = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 75,
      );
    } catch (_) {
      _message('Impossible d\'ouvrir la galerie.');
      return;
    }
    if (fichier == null || !mounted) return;
    setState(() => _chargement = true);
    final octets = await fichier.readAsBytes();
    if (!mounted) return;
    setState(() => _chargement = false);
    if (octets.length > tailleMaxPhoto) {
      _message('Cette photo est trop lourde. Choisissez-en une autre.');
      return;
    }
    final type = fichier.mimeType;
    _lien.clear();
    widget.onChanged(
      photoEnTexte(
        octets,
        type: type != null && type.startsWith('image/') ? type : null,
      ),
    );
  }

  void _retirer() {
    _lien.clear();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = widget.photo?.trim() ?? '';
    final aPhoto = photo.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: YokfaCouleurs.sable,
          borderRadius: BorderRadius.circular(yokfaRayon),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _chargement ? null : _galerie,
            child: SizedBox(
              height: 190,
              child: _chargement
                  ? const Center(child: CircularProgressIndicator())
                  : aPhoto
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        PhotoPlat(
                          url: photo,
                          emoji: widget.emoji,
                          tailleEmoji: 56,
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Changer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 44,
                          color: YokfaCouleurs.orange,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajouter une photo',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Touchez pour choisir dans la galerie',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: YokfaCouleurs.gris,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _chargement ? null : _galerie,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Galerie'),
              ),
            ),
            if (aPhoto) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retirer,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Retirer'),
                ),
              ),
            ],
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _lienOuvert = !_lienOuvert),
            icon: Icon(
              _lienOuvert ? Icons.expand_less_rounded : Icons.link_rounded,
            ),
            label: const Text('Ou utiliser un lien internet'),
          ),
        ),
        if (_lienOuvert)
          TextField(
            controller: _lien,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Lien de la photo',
              hintText: 'https://...',
              prefixIcon: Icon(Icons.link_rounded),
            ),
            onChanged: (v) =>
                widget.onChanged(v.trim().isEmpty ? null : v.trim()),
          ),
      ],
    );
  }
}

/// Carte blanche avec un titre, qui regroupe des champs du formulaire.
class SectionFormulaire extends StatelessWidget {
  const SectionFormulaire({
    super.key,
    required this.titre,
    required this.icone,
    required this.children,
  });

  final String titre;
  final IconData icone;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icone, size: 20, color: YokfaCouleurs.orange),
                const SizedBox(width: 8),
                Text(titre, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            for (final c in children) ...[const SizedBox(height: 14), c],
          ],
        ),
      ),
    );
  }
}

/// Interrupteur avec un titre et une explication, dans une section.
class OptionInterrupteur extends StatelessWidget {
  const OptionInterrupteur({
    super.key,
    required this.titre,
    required this.explication,
    required this.valeur,
    required this.onChanged,
  });

  final String titre;
  final String explication;
  final bool valeur;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(titre),
      subtitle: Text(explication),
      value: valeur,
      onChanged: onChanged,
    );
  }
}

/// Page de formulaire : contenu centré (largeur limitée) et bouton
/// « Enregistrer » toujours visible en bas.
class PageFormulaire extends StatelessWidget {
  const PageFormulaire({
    super.key,
    required this.titre,
    required this.formKey,
    required this.onEnregistrer,
    required this.children,
  });

  final String titre;
  final GlobalKey<FormState> formKey;
  final VoidCallback? onEnregistrer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onEnregistrer,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Enregistrer'),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final c in children) ...[c, const SizedBox(height: 16)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
