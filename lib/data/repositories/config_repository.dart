import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/config_paiement.dart';

class ConfigRepository {
  ConfigRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _paiement =>
      _db.collection('config').doc('paiement');

  Stream<ConfigPaiement> paiement() =>
      _paiement.snapshots().map((d) => ConfigPaiement.fromMap(d.data()));

  Future<void> enregistrerPaiement(ConfigPaiement c) =>
      _paiement.set(c.toMap());
}
