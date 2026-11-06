import 'package:cloud_firestore/cloud_firestore.dart';

/// Menu d'exemple pour démarrer (catégories citées dans le cahier des charges),
/// avec de vraies photos livrées dans l'appli (assets/photos).
/// Le gérant peut le charger depuis la gestion du menu, puis l'adapter.
Future<void> chargerMenuDemo(FirebaseFirestore db) async {
  final batch = db.batch();
  final categories = {
    'nourriture': ('Nourriture', '🍝', 1),
    'boissons': ('Boissons', '🥤', 2),
    'friandises': ('Friandises', '🍬', 3),
    'desserts': ('Desserts', '🍰', 4),
  };
  categories.forEach((id, c) {
    final (nom, icone, ordre) = c;
    batch.set(db.collection('categories').doc(id), {
      'nom': nom,
      'icone': icone,
      'ordre': ordre,
      'visible': true,
      'photoUrl': 'assets/photos/cat_$id.jpg',
    });
  });
  final produits = [
    ('nourriture', 'Spaghetti', 1000, 'spaghetti'),
    ('nourriture', 'Riz sauce', 800, 'riz_sauce'),
    ('nourriture', 'Poulet braisé', 1500, 'poulet'),
    ('nourriture', 'Alloco', 500, 'alloco'),
    ('boissons', 'Eau minérale', 300, 'eau'),
    ('boissons', 'Jus de bissap', 500, 'bissap'),
    ('boissons', 'Jus d\'ananas', 600, 'jus_ananas'),
    ('friandises', 'Biscuits', 200, 'biscuits'),
    ('friandises', 'Beignets', 300, 'beignets'),
    ('friandises', 'Donuts', 400, 'donuts'),
    ('desserts', 'Yaourt', 400, 'yaourt'),
    ('desserts', 'Cheesecake', 900, 'cheesecake'),
    ('desserts', 'Gâteau au chocolat', 700, 'gateau_chocolat'),
  ];
  for (var i = 0; i < produits.length; i++) {
    final (cat, nom, prix, photo) = produits[i];
    batch.set(db.collection('produits').doc(), {
      'nom': nom,
      'categorieId': cat,
      'prix': prix,
      'photoUrl': 'assets/photos/$photo.jpg',
      'disponible': true,
      'visible': true,
      'ordre': i,
    });
  }
  await batch.commit();
}
