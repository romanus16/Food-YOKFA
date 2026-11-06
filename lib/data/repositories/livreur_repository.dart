import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/livreur.dart';

class LivreurRepository {
  LivreurRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _livreurs =>
      _db.collection('livreurs');

  /// Fiche du livreur [uid], ou `null` s'il n'a pas encore fait de demande.
  Stream<Livreur?> suivre(String uid) => _livreurs
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? Livreur.fromMap(d.id, d.data()!) : null);

  /// Le livreur demande à rejoindre l'équipe ; le gérant devra l'accepter.
  Future<void> demander({
    required String uid,
    required String nom,
    required String telephone,
    required String email,
  }) => _livreurs
      .doc(uid)
      .set(
        Livreur(
          uid: uid,
          nom: nom.trim(),
          telephone: telephone.trim(),
          email: email.trim(),
        ).toMap(),
      );

  /// Tous les livreurs et demandes (gérant), actifs d'abord puis par nom.
  Stream<List<Livreur>> tous() => _livreurs.snapshots().map(
    (s) => s.docs.map((d) => Livreur.fromMap(d.id, d.data())).toList()
      ..sort(
        (a, b) => a.actif == b.actif
            ? a.nom.toLowerCase().compareTo(b.nom.toLowerCase())
            : (a.actif ? -1 : 1),
      ),
  );

  /// Le gérant accepte une demande ou met un livreur en pause.
  Future<void> activer(String uid, bool actif) =>
      _livreurs.doc(uid).update({'actif': actif});

  /// Le gérant retire un livreur (ou refuse sa demande).
  Future<void> retirer(String uid) => _livreurs.doc(uid).delete();
}
