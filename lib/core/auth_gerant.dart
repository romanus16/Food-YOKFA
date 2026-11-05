import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Un gérant connecté par e-mail.
class CompteGerant {
  const CompteGerant({required this.uid, required this.email});
  final String uid;
  final String email;
}

/// Connexion des gérants (e-mail et mot de passe).
abstract class AuthGerant {
  /// Compte e-mail connecté, ou `null` (personne, ou client anonyme).
  Stream<CompteGerant?> compte();

  Future<void> connexion(String email, String motDePasse);

  Future<void> inscription(String email, String motDePasse);

  Future<void> deconnexion();

  /// `true` si ce compte figure dans `gerants/{uid}`.
  Stream<bool> estGerant(String uid);
}

class AuthGerantFirebase implements AuthGerant {
  AuthGerantFirebase(this._db, [FirebaseAuth? auth]) : _auth = auth;

  final FirebaseFirestore _db;
  final FirebaseAuth? _auth;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  @override
  Stream<CompteGerant?> compte() => auth.authStateChanges().map(
    (u) => u == null || u.isAnonymous
        ? null
        : CompteGerant(uid: u.uid, email: u.email ?? ''),
  );

  @override
  Future<void> connexion(String email, String motDePasse) => _traduire(
    () => auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: motDePasse,
    ),
  );

  @override
  Future<void> inscription(String email, String motDePasse) => _traduire(
    () => auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: motDePasse,
    ),
  );

  @override
  Future<void> deconnexion() => auth.signOut();

  @override
  Stream<bool> estGerant(String uid) =>
      _db.collection('gerants').doc(uid).snapshots().map((d) => d.exists);

  static Future<void> _traduire(Future<Object?> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw Exception(switch (e.code) {
        'invalid-email' => 'Adresse e-mail invalide.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' => 'E-mail ou mot de passe incorrect.',
        'email-already-in-use' => 'Un compte existe déjà avec cet e-mail.',
        'weak-password' => 'Mot de passe trop faible (6 caractères minimum).',
        'network-request-failed' => 'Pas de connexion internet.',
        _ => 'Erreur de connexion (${e.code}).',
      });
    }
  }
}
