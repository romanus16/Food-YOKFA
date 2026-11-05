import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_gerant.dart';
import 'commandes_gerant_screen.dart';
import 'connexion_gerant_screen.dart';

/// Entrée de l'espace gérant : connexion, vérification du rôle,
/// puis accès aux outils du gérant.
class GerantScreen extends StatelessWidget {
  const GerantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthGerant>();
    return StreamBuilder<CompteGerant?>(
      stream: auth.compte(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final compte = snap.data;
        if (compte == null) return const ConnexionGerantScreen();
        return StreamBuilder<bool>(
          stream: auth.estGerant(compte.uid),
          builder: (context, role) {
            if (!role.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!role.data!) return _NonAutorise(compte: compte);
            return const EspaceGerant();
          },
        );
      },
    );
  }
}

/// Outils du gérant. Les onglets Scan et Menu s'ajoutent ici.
class EspaceGerant extends StatelessWidget {
  const EspaceGerant({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace gérant'),
        actions: const [BoutonDeconnexion()],
      ),
      body: const CommandesGerantScreen(),
    );
  }
}

class BoutonDeconnexion extends StatelessWidget {
  const BoutonDeconnexion({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Se déconnecter',
      icon: const Icon(Icons.logout),
      onPressed: () => context.read<AuthGerant>().deconnexion(),
    );
  }
}

class _NonAutorise extends StatelessWidget {
  const _NonAutorise({required this.compte});

  final CompteGerant compte;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace gérant'),
        actions: const [BoutonDeconnexion()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock, size: 56),
            const SizedBox(height: 16),
            Text(
              'Le compte ${compte.email} n\'est pas encore gérant.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Transmettez cet identifiant à l\'administrateur pour qu\'il '
              'crée le document gerants/<identifiant> dans Firestore :',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(compte.uid, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
