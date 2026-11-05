import 'package:flutter/material.dart';

import '../../data/models/categorie.dart';

/// Produits d'une catégorie (contenu complet : issue #4).
class ProduitsScreen extends StatelessWidget {
  const ProduitsScreen({super.key, required this.categorie});

  final Categorie categorie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categorie.nom)),
      body: const Center(child: Text('Produits à venir.')),
    );
  }
}
