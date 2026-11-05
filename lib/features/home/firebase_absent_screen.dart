import 'package:flutter/material.dart';

/// Affiché quand Firebase n'a pas pu démarrer (projet pas encore configuré).
class FirebaseAbsentScreen extends StatelessWidget {
  const FirebaseAbsentScreen({super.key, this.erreur});

  final String? erreur;

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
              Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Firebase non configuré (voir README)',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (erreur != null) ...[
                const SizedBox(height: 8),
                Text(
                  erreur!,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
