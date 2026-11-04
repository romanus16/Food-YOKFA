import 'dart:async';

import 'package:food_yokfa/core/auth_gerant.dart';
import 'package:food_yokfa/core/identite.dart';

class IdentiteFactice implements Identite {
  IdentiteFactice([this.id = 'client-test']);
  final String id;
  @override
  Future<String> clientId() async => id;
}

/// Connexion gérant factice : `comptes` associe e-mail → mot de passe,
/// `gerants` liste les uid ayant le rôle.
class AuthGerantFactice implements AuthGerant {
  AuthGerantFactice({
    CompteGerant? connecte,
    this.comptes = const {},
    Set<String>? gerants,
  }) : _compte = connecte,
       gerants = gerants ?? {};

  CompteGerant? _compte;
  final Map<String, String> comptes;
  final Set<String> gerants;
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
    if (comptes[email] != motDePasse) {
      throw Exception('E-mail ou mot de passe incorrect.');
    }
    _changer(CompteGerant(uid: 'uid-$email', email: email));
  }

  @override
  Future<void> inscription(String email, String motDePasse) async {
    _changer(CompteGerant(uid: 'uid-$email', email: email));
  }

  @override
  Future<void> deconnexion() async => _changer(null);

  @override
  Stream<bool> estGerant(String uid) => Stream.value(gerants.contains(uid));
}
