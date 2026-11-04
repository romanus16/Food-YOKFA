import 'package:flutter/material.dart';

/// Formulaire de commande (contenu complet : issue #5).
class FormulaireCommandeScreen extends StatelessWidget {
  const FormulaireCommandeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commander')),
      body: const Center(child: Text('Formulaire à venir.')),
    );
  }
}
