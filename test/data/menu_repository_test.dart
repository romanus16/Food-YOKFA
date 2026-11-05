import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/data/menu_demo.dart';
import 'package:food_yokfa/data/models/produit.dart';
import 'package:food_yokfa/data/repositories/menu_repository.dart';

void main() {
  test('le menu de démo contient les catégories dans l\'ordre', () async {
    final db = FakeFirebaseFirestore();
    await chargerMenuDemo(db);
    final repo = MenuRepository(db);
    final cats = await repo.categories().first;
    expect(cats.map((c) => c.nom), [
      'Nourriture',
      'Boissons',
      'Friandises',
      'Desserts',
    ]);
    final plats = await repo.produits('nourriture').first;
    expect(plats.first.nom, 'Spaghetti');
    expect(plats.first.prix, 1000);
  });

  test('les éléments masqués ne sont pas montrés au client', () async {
    final db = FakeFirebaseFirestore();
    final repo = MenuRepository(db);
    await repo.ajouterProduit(
      const Produit(id: '', nom: 'Visible', categorieId: 'c', prix: 100),
    );
    await repo.ajouterProduit(
      const Produit(
        id: '',
        nom: 'Caché',
        categorieId: 'c',
        prix: 100,
        visible: false,
      ),
    );
    expect((await repo.produits('c').first).map((p) => p.nom), ['Visible']);
    expect((await repo.produits('c', tous: true).first).length, 2);
  });
}
