import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/categorie.dart';
import '../models/produit.dart';

/// Lecture et écriture du menu (catégories et produits).
///
/// Les tris et filtres sont faits côté application pour éviter
/// d'avoir à créer des index composites Firestore : le menu est petit.
class MenuRepository {
  MenuRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _produits =>
      _db.collection('produits');

  /// Catégories triées par ordre. [toutes] inclut les catégories masquées.
  Stream<List<Categorie>> categories({bool toutes = false}) {
    return _categories.snapshots().map((snap) {
      final liste =
          snap.docs
              .map((d) => Categorie.fromMap(d.id, d.data()))
              .where((c) => toutes || c.visible)
              .toList()
            ..sort(_parOrdre((c) => c.ordre, (c) => c.nom));
      return liste;
    });
  }

  /// Produits d'une catégorie triés par ordre. [tous] inclut les masqués.
  Stream<List<Produit>> produits(String categorieId, {bool tous = false}) {
    return _produits
        .where('categorieId', isEqualTo: categorieId)
        .snapshots()
        .map((snap) {
          final liste =
              snap.docs
                  .map((d) => Produit.fromMap(d.id, d.data()))
                  .where((p) => tous || p.visible)
                  .toList()
                ..sort(_parOrdre((p) => p.ordre, (p) => p.nom));
          return liste;
        });
  }

  Future<String> ajouterCategorie(Categorie c) async =>
      (await _categories.add(c.toMap())).id;

  Future<void> modifierCategorie(Categorie c) =>
      _categories.doc(c.id).set(c.toMap());

  Future<String> ajouterProduit(Produit p) async =>
      (await _produits.add(p.toMap())).id;

  Future<void> modifierProduit(Produit p) => _produits.doc(p.id).set(p.toMap());

  static int Function(T, T) _parOrdre<T>(
    int Function(T) ordre,
    String Function(T) nom,
  ) {
    return (a, b) {
      final o = ordre(a).compareTo(ordre(b));
      return o != 0 ? o : nom(a).compareTo(nom(b));
    };
  }
}
