import 'package:flutter/material.dart';

import '../../core/firebase_bootstrap.dart';

/// Écran d'accueil provisoire.
///
/// Les catégories (Nourriture, Boissons, Friandises...) arrivent avec
/// l'issue #3. Pour l'instant, l'écran confirme que l'application démarre
/// et indique si Firebase est bien connecté.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.firebase});

  final FirebaseStatus firebase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Food YOKFA')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_menu,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Bienvenue', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Le menu arrive bientôt.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _FirebaseBadge(firebase: firebase),
            ],
          ),
        ),
      ),
    );
  }
}

class _FirebaseBadge extends StatelessWidget {
  const _FirebaseBadge({required this.firebase});

  final FirebaseStatus firebase;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ok = firebase.isReady;
    return Card(
      color: ok ? colors.secondaryContainer : colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ok ? Icons.cloud_done : Icons.cloud_off),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                ok
                    ? 'Connecté à Firebase'
                    : 'Firebase non configuré (voir README)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
