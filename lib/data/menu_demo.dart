import 'package:cloud_firestore/cloud_firestore.dart';

/// Menu d'exemple pour démarrer (catégories citées dans le cahier des charges).
/// Le gérant peut le charger depuis la gestion du menu, puis l'adapter.
Future<void> chargerMenuDemo(FirebaseFirestore db) async {
  final batch = db.batch();
  final categories = {
    'nourriture': {'nom': 'Nourriture', 'icone': '🍝', 'ordre': 1},
    'boissons': {'nom': 'Boissons', 'icone': '🥤', 'ordre': 2},
    'friandises': {'nom': 'Friandises', 'icone': '🍬', 'ordre': 3},
    'desserts': {'nom': 'Desserts', 'icone': '🍰', 'ordre': 4},
  };
  categories.forEach((id, data) {
    batch.set(db.collection('categories').doc(id), {...data, 'visible': true});
  });
  final produits = [
    ('nourriture', 'Spaghetti', 1000),
    ('nourriture', 'Riz sauce', 800),
    ('boissons', 'Eau minérale', 300),
    ('boissons', 'Jus de bissap', 500),
    ('friandises', 'Biscuits', 200),
    ('desserts', 'Yaourt', 400),
  ];
  for (var i = 0; i < produits.length; i++) {
    final (cat, nom, prix) = produits[i];
    batch.set(db.collection('produits').doc(), {
      'nom': nom,
      'categorieId': cat,
      'prix': prix,
      'photoUrl': null,
      'disponible': true,
      'visible': true,
      'ordre': i,
    });
  }
  await batch.commit();
}
