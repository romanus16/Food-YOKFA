/// Livreur : compte e-mail dont l'uid a un document `livreurs/{uid}`.
/// Le livreur crée lui-même sa demande ; le gérant l'accepte.
class Livreur {
  const Livreur({
    required this.uid,
    required this.nom,
    this.telephone = '',
    this.email = '',
    this.actif = false,
  });

  final String uid;
  final String nom;
  final String telephone;
  final String email;

  /// `false` tant que le gérant n'a pas accepté la demande.
  final bool actif;

  factory Livreur.fromMap(String uid, Map<String, dynamic> data) => Livreur(
    uid: uid,
    nom: data['nom'] as String? ?? '',
    telephone: data['telephone'] as String? ?? '',
    email: data['email'] as String? ?? '',
    actif: data['actif'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'nom': nom,
    'telephone': telephone,
    'email': email,
    'actif': actif,
  };
}
