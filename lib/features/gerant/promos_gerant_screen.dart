import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models/code_promo.dart';
import '../../data/repositories/promo_repository.dart';
import 'formulaire_menu.dart';

/// Codes promo du gérant : liste, activation, création.
class PromosGerantScreen extends StatelessWidget {
  const PromosGerantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PromoRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Codes promo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editer(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau code'),
      ),
      body: StreamBuilder<List<CodePromo>>(
        stream: repo.tous(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final codes = snap.data!;
          if (codes.isEmpty) {
            return const EtatVide(
              icone: Icons.local_offer_outlined,
              texte:
                  'Aucun code promo.\nCréez-en un : le client le saisit dans '
                  'son panier et la réduction s\'applique au total.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              for (final p in codes)
                Card(
                  child: ListTile(
                    leading: PastilleIcone(
                      icone: Icons.local_offer_rounded,
                      couleur: p.actif
                          ? YokfaCouleurs.orange
                          : YokfaCouleurs.gris,
                    ),
                    title: Text('${p.code} · ${p.description}'),
                    subtitle: Text(
                      [
                        p.minimum > 0
                            ? 'Dès ${formatFcfa(p.minimum)}'
                            : 'Sans minimum',
                        p.actif ? 'actif' : 'désactivé',
                      ].join(' · '),
                    ),
                    trailing: Switch(
                      value: p.actif,
                      onChanged: (v) => repo.enregistrer(
                        CodePromo(
                          code: p.code,
                          type: p.type,
                          valeur: p.valeur,
                          minimum: p.minimum,
                          actif: v,
                        ),
                      ),
                    ),
                    onTap: () => _editer(context, p),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _editer(BuildContext context, CodePromo? existant) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Provider.value(
            value: context.read<PromoRepository>(),
            child: EditionPromoScreen(existant: existant),
          ),
        ),
      );
}

class EditionPromoScreen extends StatefulWidget {
  const EditionPromoScreen({super.key, this.existant});

  final CodePromo? existant;

  @override
  State<EditionPromoScreen> createState() => _EditionPromoScreenState();
}

class _EditionPromoScreenState extends State<EditionPromoScreen> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.existant?.code);
  late final _valeur = TextEditingController(
    text: widget.existant == null ? '' : '${widget.existant!.valeur}',
  );
  late final _minimum = TextEditingController(
    text: widget.existant == null || widget.existant!.minimum == 0
        ? ''
        : '${widget.existant!.minimum}',
  );
  late TypeRemise _type = widget.existant?.type ?? TypeRemise.pourcentage;
  late bool _actif = widget.existant?.actif ?? true;

  @override
  void dispose() {
    _code.dispose();
    _valeur.dispose();
    _minimum.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) return;
    final repo = context.read<PromoRepository>();
    await repo.enregistrer(
      CodePromo(
        code: CodePromo.normaliser(_code.text),
        type: _type,
        valeur: int.parse(_valeur.text),
        minimum: int.tryParse(_minimum.text) ?? 0,
        actif: _actif,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _supprimer() async {
    await context.read<PromoRepository>().supprimer(widget.existant!.code);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final existant = widget.existant;
    return PageFormulaire(
      titre: existant == null ? 'Nouveau code promo' : 'Modifier le code',
      formKey: _form,
      onEnregistrer: _enregistrer,
      children: [
        SectionFormulaire(
          titre: 'Code',
          icone: Icons.local_offer_rounded,
          children: [
            TextFormField(
              controller: _code,
              enabled: existant == null,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Code',
                hintText: 'Ex. BIENVENUE',
                helperText: 'Le client le saisit dans son panier.',
              ),
              validator: (v) => CodePromo.normaliser(v ?? '').length < 3
                  ? 'Au moins 3 caractères.'
                  : null,
            ),
          ],
        ),
        SectionFormulaire(
          titre: 'Réduction',
          icone: Icons.percent_rounded,
          children: [
            SegmentedButton<TypeRemise>(
              segments: const [
                ButtonSegment(
                  value: TypeRemise.pourcentage,
                  label: Text('Pourcentage'),
                  icon: Icon(Icons.percent_rounded),
                ),
                ButtonSegment(
                  value: TypeRemise.montant,
                  label: Text('Montant'),
                  icon: Icon(Icons.payments_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            TextFormField(
              controller: _valeur,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Réduction',
                suffixText: _type == TypeRemise.pourcentage ? '%' : 'F CFA',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '') ?? 0;
                if (n <= 0) return 'Indiquez la réduction.';
                if (_type == TypeRemise.pourcentage && n > 100) {
                  return '100 % au maximum.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _minimum,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Panier minimum (facultatif)',
                suffixText: 'F CFA',
              ),
            ),
            OptionInterrupteur(
              titre: 'Actif',
              explication: 'Les clients peuvent utiliser ce code.',
              valeur: _actif,
              onChanged: (v) => setState(() => _actif = v),
            ),
          ],
        ),
        if (existant != null)
          OutlinedButton.icon(
            onPressed: _supprimer,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Supprimer ce code'),
          ),
      ],
    );
  }
}
