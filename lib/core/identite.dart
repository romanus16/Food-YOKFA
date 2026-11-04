import 'package:firebase_auth/firebase_auth.dart';

/// Donne l'identifiant du client qui commande.
abstract class Identite {
  /// Identifiant stable du client sur ce téléphone.
  Future<String> clientId();
}

/// Connexion anonyme Firebase : le client commande sans créer de compte.
/// L'identifiant reste le même tant que l'appli n'est pas désinstallée.
class IdentiteFirebase implements Identite {
  IdentiteFirebase([FirebaseAuth? auth]) : _auth = auth;

  final FirebaseAuth? _auth;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  @override
  Future<String> clientId() async {
    final actuel = auth.currentUser;
    if (actuel != null) return actuel.uid;
    final cred = await auth.signInAnonymously();
    return cred.user!.uid;
  }
}
