import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_gerant.dart';
import '../../core/demo.dart';

class ConnexionGerantScreen extends StatefulWidget {
  const ConnexionGerantScreen({super.key});

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
      appBar: AppBar(title: const Text('Espace gérant')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (ModeDemo.actif) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Mode démo : saisissez n\'importe quel e-mail et '
                  'mot de passe pour entrer dans l\'espace gérant.',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mdp,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              border: OutlineInputBorder(),
            ),
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
            child: const Text('Créer un compte gérant'),
          ),
        ],
      ),
    );
  }
}
