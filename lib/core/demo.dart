import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import '../data/menu_demo.dart';
import '../data/models/commande.dart';
import 'auth_gerant.dart';
import 'identite.dart';
import 'notifications_gerant.dart';

/// Mode démo : l'appli tourne sans Firebase, avec une base en mémoire
/// préremplie (menu, numéros marchands, quelques commandes).
/// Tout est effacé quand on ferme ou recharge l'appli.
///
/// Activé automatiquement tant que Firebase n'est pas configuré, ou de force
/// avec `flutter run --dart-define=DEMO=true`.
///
/// La base en mémoire (fake_cloud_firestore) ne fonctionne que dans une
/// version de développement (`flutter run`, `flutter build web --debug`),
/// pas dans une version release.
abstract final class ModeDemo {
  static bool actif = false;

  /// Codes QR des commandes d'exemple, à saisir à la main au scan.
  static const codePayee = 'DEMO-PAYEE';
  static const codeEspeces = 'DEMO-ESPECES';

  /// Crée la base de démonstration.
  static Future<FirebaseFirestore> creerBase() async {
    final db = FakeFirebaseFirestore();
    await chargerMenuDemo(db);
    await db.collection('config').doc('paiement').set({
      'numeroTmoney': '90 00 00 00',
      'numeroFlooz': '99 00 00 00',
    });
    final maintenant = DateTime.now();
    final exemples = [
      Commande(
        id: '',
        clientId: 'client-exemple-1',
        lignes: const [
          LigneCommande(
            produitId: 'spaghetti',
            nom: 'Spaghetti',
            quantite: 2,
            prixUnitaire: 1000,
          ),
          LigneCommande(
            produitId: 'bissap',
            nom: 'Jus de bissap',
            quantite: 1,
            prixUnitaire: 500,
          ),
        ],
        heureSouhaitee: maintenant.add(const Duration(minutes: 45)),
        filiere: 'Informatique L2',
        batiment: Batiment.nouveau,
        moyenPaiement: MoyenPaiement.tmoney,
        referencePaiement: 'TM2611061234',
        codeQr: 'DEMO-A-VALIDER',
        creeLe: maintenant.subtract(const Duration(minutes: 10)),
      ),
      Commande(
        id: '',
        clientId: 'client-exemple-2',
        lignes: const [
          LigneCommande(
            produitId: 'riz',
            nom: 'Riz sauce',
            quantite: 1,
            prixUnitaire: 800,
          ),
        ],
        heureSouhaitee: maintenant.add(const Duration(minutes: 20)),
        filiere: 'Gestion L1',
        batiment: Batiment.ancien,
        moyenPaiement: MoyenPaiement.flooz,
        referencePaiement: 'FL2611065678',
        statut: StatutCommande.payee,
        payeeLe: maintenant.subtract(const Duration(minutes: 5)),
        codeQr: codePayee,
        creeLe: maintenant.subtract(const Duration(minutes: 25)),
      ),
      Commande(
        id: '',
        clientId: 'client-exemple-3',
        lignes: const [
          LigneCommande(
            produitId: 'yaourt',
            nom: 'Yaourt',
            quantite: 2,
            prixUnitaire: 400,
          ),
          LigneCommande(
            produitId: 'eau',
            nom: 'Eau minérale',
            quantite: 1,
            prixUnitaire: 300,
          ),
        ],
        heureSouhaitee: maintenant.add(const Duration(minutes: 30)),
        filiere: 'Droit L3',
        batiment: Batiment.nouveau,
        moyenPaiement: MoyenPaiement.especes,
        lieu: const LieuLivraison(
          latitude: 6.1757,
          longitude: 1.2117,
          repere: 'Devant l\'amphi B, banc sous le manguier',
        ),
        codeQr: codeEspeces,
        creeLe: maintenant.subtract(const Duration(minutes: 15)),
      ),
    ];
    for (final c in exemples) {
      await db.collection('commandes').add(c.toMap());
    }
    return db;
  }
}

class IdentiteDemo implements Identite {
  @override
  Future<String> clientId() async => 'client-demo';
}

/// En démo, n'importe quel e-mail et mot de passe ouvre l'espace gérant.
class AuthGerantDemo implements AuthGerant {
  CompteGerant? _compte;
  final _ctrl = StreamController<CompteGerant?>.broadcast();

  @override
  Stream<CompteGerant?> compte() async* {
    yield _compte;
    yield* _ctrl.stream;
  }

  void _changer(CompteGerant? c) {
    _compte = c;
    _ctrl.add(c);
  }

  @override
  Future<void> connexion(String email, String motDePasse) async {
    final e = email.trim();
    if (e.isEmpty || motDePasse.isEmpty) {
      throw Exception('Saisissez un e-mail et un mot de passe.');
    }
    _changer(CompteGerant(uid: 'gerant-demo', email: e));
  }

  @override
  Future<void> inscription(String email, String motDePasse) =>
      connexion(email, motDePasse);

  @override
  Future<void> deconnexion() async => _changer(null);

  @override
  Stream<bool> estGerant(String uid) => Stream.value(true);
}

/// Pas de notifications push en démo.
class NotificationsDemo implements NotificationsGerant {
  @override
  Future<void> activer(String uid) async {}

  @override
  Future<void> desactiver(String uid) async {}

  @override
  Stream<String> ouvertures() => const Stream.empty();

  @override
  Stream<NotificationRecue> premierPlan() => const Stream.empty();
}
