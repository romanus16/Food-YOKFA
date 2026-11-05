import 'package:flutter/material.dart';

/// Paiement de la commande (contenu complet : issue #6).
class PaiementScreen extends StatelessWidget {
  const PaiementScreen({super.key, required this.commandeId});

  final String commandeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: const Center(child: Text('Commande enregistrée.')),
    );
  }
}
