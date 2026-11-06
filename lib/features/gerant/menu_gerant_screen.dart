import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/photo.dart';
import '../../data/menu_demo.dart';
import '../../data/models/categorie.dart';
import '../../data/models/config_paiement.dart';
import '../../data/models/produit.dart';
import '../../data/repositories/config_repository.dart';
import '../../data/repositories/menu_repository.dart';

/// Gestion du menu par le gérant : catégories, produits, numéros marchands.
class MenuGerantScreen extends StatelessWidget {
  const MenuGerantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = context.read<MenuRepository>();
    return StreamBuilder<List<Categorie>>(
      stream: menu.categories(toutes: true),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cats = snap.data!;
        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const _NumerosMarchands(),
            const Divider(),
            if (cats.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Le menu est vide.'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () =>
                          chargerMenuDemo(context.read<FirebaseFirestore>()),
                      child: const Text('Charger le menu d\'exemple'),
                    ),
                  ],
                ),
              ),
            for (final c in cats) _CategorieSection(categorie: c),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () =>
                    _editerCategorie(context, null, cats.length + 1),
                icon: const Icon(Icons.create_new_folder),
                label: const Text('Ajouter une catégorie'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategorieSection extends StatelessWidget {
  const _CategorieSection({required this.categorie});

  final Categorie categorie;

  @override
  Widget build(BuildContext context) {
    final menu = context.read<MenuRepository>();
    final c = categorie;
    return ExpansionTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: PhotoPlat(
            url: Photos.categorie(c),
            emoji: c.icone,
            tailleEmoji: 24,
          ),
        ),
      ),
      title: Text(c.nom),
      subtitle: Text(
        '${c.visible ? 'Visible' : 'Masquée'} · position ${c.ordre}',
      ),
      children: [
        StreamBuilder<List<Produit>>(
          stream: menu.produits(c.id, tous: true),
          builder: (context, snap) {
            final produits = snap.data ?? const <Produit>[];
            return Column(
              children: [
                for (final p in produits)
                  ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: PhotoPlat(
                          url: p.photoUrl,
                          emoji: c.icone,
                          tailleEmoji: 20,
                        ),
                      ),
                    ),
                    title: Text(p.nom),
                    subtitle: Text(
                      [
                        formatFcfa(p.prix),
                        if (!p.disponible) 'indisponible',
                        if (!p.visible) 'masqué',
                      ].join(' · '),
                    ),
                    trailing: Switch(
                      value: p.disponible,
                      onChanged: (v) =>
                          menu.modifierProduit(p.copyWith(disponible: v)),
                    ),
                    onTap: () => _editerProduit(context, p, c.id),
                  ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _editerProduit(context, null, c.id),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un produit'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _editerCategorie(context, c, c.ordre),
                      child: const Text('Modifier la catégorie'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

Future<void> _editerCategorie(
  BuildContext context,
  Categorie? existante,
  int ordreParDefaut,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => Provider.value(
      value: context.read<MenuRepository>(),
      child: _DialogueCategorie(
        existante: existante,
        ordreParDefaut: ordreParDefaut,
      ),
    ),
  );
}

Future<void> _editerProduit(
  BuildContext context,
  Produit? existant,
  String categorieId,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Provider.value(
        value: context.read<MenuRepository>(),
        child: EditionProduitScreen(
          existant: existant,
          categorieId: categorieId,
        ),
      ),
    ),
  );
}

class _DialogueCategorie extends StatefulWidget {
  const _DialogueCategorie({this.existante, required this.ordreParDefaut});

  final Categorie? existante;
  final int ordreParDefaut;

  @override
  State<_DialogueCategorie> createState() => _DialogueCategorieState();
}

class _DialogueCategorieState extends State<_DialogueCategorie> {
  late final _nom = TextEditingController(text: widget.existante?.nom);
  late final _icone = TextEditingController(
    text: widget.existante?.icone ?? '🍽️',
  );
  late final _ordre = TextEditingController(
    text: '${widget.existante?.ordre ?? widget.ordreParDefaut}',
  );
  late final _photo = TextEditingController(text: widget.existante?.photoUrl);
  late bool _visible = widget.existante?.visible ?? true;

  @override
  void dispose() {
    _nom.dispose();
    _icone.dispose();
    _ordre.dispose();
    _photo.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_nom.text.trim().isEmpty) return;
    final menu = context.read<MenuRepository>();
    final c = Categorie(
      id: widget.existante?.id ?? '',
      nom: _nom.text.trim(),
      icone: _icone.text.trim().isEmpty ? '🍽️' : _icone.text.trim(),
      ordre: int.tryParse(_ordre.text) ?? widget.ordreParDefaut,
      visible: _visible,
      photoUrl: _photo.text.trim().isEmpty ? null : _photo.text.trim(),
    );
    if (widget.existante == null) {
      await menu.ajouterCategorie(c);
    } else {
      await menu.modifierCategorie(c);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existante == null
            ? 'Nouvelle catégorie'
            : 'Modifier la catégorie',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nom,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: _icone,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
            TextField(
              controller: _photo,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Photo (adresse, facultatif)',
                hintText: 'https://...',
              ),
            ),
            TextField(
              controller: _ordre,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Position'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible par les clients'),
              value: _visible,
              onChanged: (v) => setState(() => _visible = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _enregistrer, child: const Text('Enregistrer')),
      ],
    );
  }
}

class EditionProduitScreen extends StatefulWidget {
  const EditionProduitScreen({
    super.key,
    this.existant,
    required this.categorieId,
  });

  final Produit? existant;
  final String categorieId;

  @override
  State<EditionProduitScreen> createState() => _EditionProduitScreenState();
}

class _EditionProduitScreenState extends State<EditionProduitScreen> {
  final _form = GlobalKey<FormState>();
  late final _nom = TextEditingController(text: widget.existant?.nom);
  late final _prix = TextEditingController(
    text: widget.existant == null ? '' : '${widget.existant!.prix}',
  );
  late final _photo = TextEditingController(text: widget.existant?.photoUrl);
  late final _ordre = TextEditingController(
    text: '${widget.existant?.ordre ?? 0}',
  );
  late String _categorieId = widget.existant?.categorieId ?? widget.categorieId;
  late bool _disponible = widget.existant?.disponible ?? true;
  late bool _visible = widget.existant?.visible ?? true;

  @override
  void dispose() {
    _nom.dispose();
    _prix.dispose();
    _photo.dispose();
    _ordre.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) return;
    final menu = context.read<MenuRepository>();
    final photo = _photo.text.trim();
    final p = Produit(
      id: widget.existant?.id ?? '',
      nom: _nom.text.trim(),
      categorieId: _categorieId,
      prix: int.parse(_prix.text),
      photoUrl: photo.isEmpty ? null : photo,
      disponible: _disponible,
      visible: _visible,
      ordre: int.tryParse(_ordre.text) ?? 0,
    );
    if (widget.existant == null) {
      await menu.ajouterProduit(p);
    } else {
      await menu.modifierProduit(p);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.read<MenuRepository>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existant == null ? 'Nouveau produit' : 'Modifier le produit',
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nom,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Indiquez un nom.' : null,
            ),
            TextFormField(
              controller: _prix,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Prix',
                suffixText: 'F CFA',
              ),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Indiquez un prix.'
                  : null,
            ),
            StreamBuilder<List<Categorie>>(
              stream: menu.categories(toutes: true),
              builder: (context, snap) {
                final cats = snap.data ?? const <Categorie>[];
                if (cats.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String>(
                  initialValue: cats.any((c) => c.id == _categorieId)
                      ? _categorieId
                      : null,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: [
                    for (final c in cats)
                      DropdownMenuItem(value: c.id, child: Text(c.nom)),
                  ],
                  onChanged: (v) => setState(() => _categorieId = v!),
                );
              },
            ),
            TextFormField(
              controller: _photo,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Lien de la photo (facultatif)',
              ),
            ),
            TextFormField(
              controller: _ordre,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Position'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disponible'),
              value: _disponible,
              onChanged: (v) => setState(() => _disponible = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible par les clients'),
              value: _visible,
              onChanged: (v) => setState(() => _visible = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _enregistrer,
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumerosMarchands extends StatelessWidget {
  const _NumerosMarchands();

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigRepository>();
    return StreamBuilder<ConfigPaiement>(
      stream: config.paiement(),
      builder: (context, snap) {
        final c = snap.data ?? const ConfigPaiement();
        String afficher(String n) => n.isEmpty ? 'non renseigné' : n;
        return ListTile(
          leading: const Icon(Icons.phone_android),
          title: const Text('Numéros marchands'),
          subtitle: Text(
            'T-Money : ${afficher(c.numeroTmoney)}\n'
            'Flooz : ${afficher(c.numeroFlooz)}',
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.edit),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => _DialogueNumeros(config: config, actuelle: c),
          ),
        );
      },
    );
  }
}

class _DialogueNumeros extends StatefulWidget {
  const _DialogueNumeros({required this.config, required this.actuelle});

  final ConfigRepository config;
  final ConfigPaiement actuelle;

  @override
  State<_DialogueNumeros> createState() => _DialogueNumerosState();
}

class _DialogueNumerosState extends State<_DialogueNumeros> {
  late final _tmoney = TextEditingController(
    text: widget.actuelle.numeroTmoney,
  );
  late final _flooz = TextEditingController(text: widget.actuelle.numeroFlooz);

  @override
  void dispose() {
    _tmoney.dispose();
    _flooz.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Numéros marchands'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _tmoney,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'T-Money (Togocel)'),
          ),
          TextField(
            controller: _flooz,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Flooz (Moov)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () async {
            await widget.config.enregistrerPaiement(
              ConfigPaiement(
                numeroTmoney: _tmoney.text.trim(),
                numeroFlooz: _flooz.text.trim(),
              ),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
