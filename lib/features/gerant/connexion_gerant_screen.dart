import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_gerant.dart';
import '../../core/demo.dart';
import '../../core/photo.dart';
import '../../core/theme.dart';

/// Connexion par e-mail, partagée par l'espace gérant et l'espace livreur.
class ConnexionGerantScreen extends StatefulWidget {
  const ConnexionGerantScreen({
    super.key,
    this.titre = 'Espace gérant',
    this.accroche = 'Validez les paiements, livrez, gérez le menu.',
    this.photo = 'assets/photos/cat_nourriture.jpg',
    this.role = 'gérant',
  });

  final String titre;
  final String accroche;
  final String photo;

  /// « gérant » ou « livreur », pour le bouton de création de compte.
  final String role;

  @override
  State<ConnexionGerantScreen> createState() => _ConnexionGerantScreenState();
}

class _ConnexionGerantScreenState extends State<ConnexionGerantScreen> {
  final _email = TextEditingController();
  final _mdp = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    _mdp.dispose();
    super.dispose();
  }

  Future<void> _agir(bool inscription) async {
    final auth = context.read<AuthGerant>();
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      if (inscription) {
        await auth.inscription(_email.text, _mdp.text);
      } else {
        await auth.connexion(_email.text, _mdp.text);
      }
    } catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _envoi = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(yokfaRayon),
            child: SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoPlat(url: widget.photo),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x11000000), Color(0xCC000000)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        Text(
                          widget.accroche,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (ModeDemo.actif) ...[
            Card(
              color: YokfaCouleurs.sable,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Mode démo : saisissez n\'importe quel e-mail et '
                  'mot de passe pour entrer dans l\'${widget.titre.toLowerCase()}.',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mdp,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 12),
            Text(
              _erreur!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _envoi ? null : () => _agir(false),
            child: const Text('Se connecter'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _envoi ? null : () => _agir(true),
            child: Text('Créer un compte ${widget.role}'),
          ),
        ],
      ),
    );
  }
}
