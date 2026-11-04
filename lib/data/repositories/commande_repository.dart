import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/format.dart';
import '../models/commande.dart';

/// Erreur métier affichable à l'utilisateur.
class CommandeException implements Exception {
  const CommandeException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CommandeRepository {
  CommandeRepository(this._db, {Random? random})
    : _random = random ?? Random.secure();

  final FirebaseFirestore _db;
  final Random _random;

  CollectionReference<Map<String, dynamic>> get _commandes =>
      _db.collection('commandes');

  static const _alphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';

  /// Identifiant aléatoire de 24 caractères (environ 140 bits),
  /// impossible à deviner.
  String genererCodeQr() => List.generate(
    24,
    (_) => _alphabet[_random.nextInt(_alphabet.length)],
  ).join();

  /// Crée la commande au statut « En attente de paiement » et renvoie son id.
  Future<String> creer({
    required String clientId,
    required List<LigneCommande> lignes,
    required DateTime heureSouhaitee,
    required String filiere,
    required Batiment batiment,
    required MoyenPaiement moyenPaiement,
  }) async {
    if (lignes.isEmpty) {
      throw const CommandeException('La commande est vide.');
    }
    final commande = Commande(
      id: '',
      clientId: clientId,
      lignes: lignes,
      heureSouhaitee: heureSouhaitee,
      filiere: filiere.trim(),
      batiment: batiment,
      moyenPaiement: moyenPaiement,
      codeQr: genererCodeQr(),
      creeLe: DateTime.now(),
    );
    final ref = await _commandes.add(commande.toMap());
    return ref.id;
  }

  Future<Commande?> lire(String id) async {
    final d = await _commandes.doc(id).get();
    return d.exists ? Commande.fromMap(d.id, d.data()!) : null;
  }

  Stream<Commande?> suivre(String id) => _commandes
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Commande.fromMap(d.id, d.data()!) : null);

  /// Commandes d'un client, les plus récentes en premier.
  Stream<List<Commande>> duClient(String clientId) => _commandes
      .where('clientId', isEqualTo: clientId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => Commande.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => b.creeLe.compareTo(a.creeLe)),
      );

  /// Toutes les commandes (gérant), triées par heure de livraison souhaitée.
  /// [statut] filtre sur un statut si fourni.
  Stream<List<Commande>> toutes({StatutCommande? statut}) {
    Query<Map<String, dynamic>> q = _commandes;
    if (statut != null) q = q.where('statut', isEqualTo: statut.code);
    return q.snapshots().map(
      (s) =>
          s.docs.map((d) => Commande.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => a.heureSouhaitee.compareTo(b.heureSouhaitee)),
    );
  }

  /// Le client saisit la référence de sa transaction mobile money.
  Future<void> enregistrerReferencePaiement(String id, String reference) {
    final ref = reference.trim();
    if (ref.isEmpty) {
      throw const CommandeException('Saisissez la référence de paiement.');
    }
    return _commandes.doc(id).update({'referencePaiement': ref});
  }

  /// Le gérant confirme avoir reçu le paiement mobile money.
  /// Une commande en espèces est encaissée au scan, pas ici.
  Future<void> validerPaiement(String id) => _db.runTransaction((tx) async {
    final doc = await tx.get(_commandes.doc(id));
    final c = Commande.fromMap(doc.id, doc.data() ?? {});
    if (c.moyenPaiement == MoyenPaiement.especes) {
      throw const CommandeException(
        'Paiement en espèces : il est encaissé au scan du QR code.',
      );
    }
    if (c.statut != StatutCommande.enAttentePaiement) {
      throw CommandeException(
        'Cette commande est déjà « ${c.statut.libelle} ».',
      );
    }
    tx.update(doc.reference, {
      'statut': StatutCommande.payee.code,
      'payeeLe': Timestamp.now(),
    });
  });

  Future<void> annuler(String id) => _db.runTransaction((tx) async {
    final doc = await tx.get(_commandes.doc(id));
    final c = Commande.fromMap(doc.id, doc.data() ?? {});
    if (c.statut == StatutCommande.livree) {
      throw const CommandeException(
        'Une commande livrée ne peut pas être annulée.',
      );
    }
    tx.update(doc.reference, {'statut': StatutCommande.annulee.code});
  });

  /// Retrouve la commande correspondant au code lu dans le QR.
  Future<Commande> chercherParCode(String codeQr) async {
    final code = codeQr.trim();
    if (code.isEmpty) throw const CommandeException('QR code illisible.');
    final res = await _commandes
        .where('codeQr', isEqualTo: code)
        .limit(1)
        .get();
    if (res.docs.isEmpty) {
      throw const CommandeException(
        'QR code inconnu : aucune commande trouvée.',
      );
    }
    final d = res.docs.first;
    return Commande.fromMap(d.id, d.data());
  }

  /// Confirme la livraison à partir du code lu dans le QR.
  /// Renvoie la commande livrée, ou lève une [CommandeException]
  /// avec un message clair si le code est refusé.
  ///
  /// Pour une commande en espèces, [especesEncaissees] doit être vrai :
  /// le livreur confirme avoir reçu l'argent, et la commande passe
  /// directement de « En attente de paiement » à « Livrée ».
  Future<Commande> confirmerLivraison(
    String codeQr, {
    bool especesEncaissees = false,
  }) async {
    final trouvee = await chercherParCode(codeQr);
    final ref = _commandes.doc(trouvee.id);
    return _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final c = Commande.fromMap(doc.id, doc.data() ?? {});
      final now = Timestamp.now();
      final maj = <String, dynamic>{
        'statut': StatutCommande.livree.code,
        'livreeLe': now,
      };
      switch (c.statut) {
        case StatutCommande.livree:
          throw const CommandeException('Cette commande a déjà été livrée.');
        case StatutCommande.annulee:
          throw const CommandeException('Cette commande a été annulée.');
        case StatutCommande.enAttentePaiement:
          if (c.moyenPaiement != MoyenPaiement.especes) {
            throw const CommandeException(
              'Cette commande n\'est pas encore payée.',
            );
          }
          if (!especesEncaissees) {
            throw CommandeException(
              'Encaissez ${formatFcfa(c.total)} en espèces avant de confirmer.',
            );
          }
          maj['payeeLe'] = now;
        case StatutCommande.payee:
          break;
      }
      tx.update(ref, maj);
      return Commande.fromMap(doc.id, {...?doc.data(), ...maj});
    });
  }
}
