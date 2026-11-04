import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/data/models/produit.dart';
import 'package:food_yokfa/features/panier/panier.dart';

void main() {
  const spaghetti = Produit(
    id: 's',
    nom: 'Spaghetti',
    categorieId: 'n',
    prix: 1000,
  );
  const eau = Produit(id: 'e', nom: 'Eau', categorieId: 'b', prix: 300);
  const rupture = Produit(
    id: 'r',
    nom: 'Rupture',
    categorieId: 'n',
    prix: 500,
    disponible: false,
  );

  test('+ ajoute une unité, − en retire, jamais sous 0', () {
    final p = Panier();
    p.ajouter(spaghetti);
    p.ajouter(spaghetti);
    p.ajouter(spaghetti);
    expect(p.quantite('s'), 3);
    p.retirer(spaghetti);
    expect(p.quantite('s'), 2);
    p.retirer(spaghetti);
    p.retirer(spaghetti);
    p.retirer(spaghetti);
    expect(p.quantite('s'), 0);
    expect(p.estVide, isTrue);
  });

  test('total et lignes, toutes catégories confondues', () {
    final p = Panier()
      ..ajouter(spaghetti)
      ..ajouter(spaghetti)
      ..ajouter(eau);
    expect(p.total, 2300);
    expect(p.nombreArticles, 3);
    expect(p.lignes.map((l) => (l.nom, l.quantite, l.prixUnitaire)), [
      ('Spaghetti', 2, 1000),
      ('Eau', 1, 300),
    ]);
  });

  test('un produit indisponible ne peut pas être ajouté', () {
    final p = Panier()..ajouter(rupture);
    expect(p.estVide, isTrue);
  });
}
