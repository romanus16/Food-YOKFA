import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/format.dart';
import '../models/code_promo.dart';

/// Erreur affichable quand un code promo est refusé.
class PromoException implements Exception {
  const PromoException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PromoRepository {
  PromoRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _codes =>
      _db.collection('codesPromo');

  /// Vérifie un code saisi par le client pour un panier de [sousTotal].
  Future<CodePromo> verifier(String saisie, int sousTotal) async {
    final code = CodePromo.normaliser(saisie);
    if (code.isEmpty) throw const PromoException('Saisissez un code promo.');
    final doc = await _codes.doc(code).get();
    if (!doc.exists) throw const PromoException('Ce code promo n\'existe pas.');
    final promo = CodePromo.fromMap(doc.id, doc.data()!);
    if (!promo.actif) {
      throw const PromoException('Ce code promo n\'est plus valable.');
    }
    if (sousTotal < promo.minimum) {
      throw PromoException(
        'Ce code demande un panier d\'au moins ${formatFcfa(promo.minimum)}.',
      );
    }
    return promo;
  }

  /// Tous les codes (gérant), par ordre alphabétique.
  Stream<List<CodePromo>> tous() => _codes.snapshots().map(
    (s) =>
        s.docs.map((d) => CodePromo.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => a.code.compareTo(b.code)),
  );

  Future<void> enregistrer(CodePromo promo) =>
      _codes.doc(CodePromo.normaliser(promo.code)).set(promo.toMap());

  Future<void> supprimer(String code) => _codes.doc(code).delete();
}
