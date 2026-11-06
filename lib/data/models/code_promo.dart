/// Type de réduction d'un code promo.
enum TypeRemise {
  pourcentage('pourcentage', 'Pourcentage'),
  montant('montant', 'Montant fixe');

  const TypeRemise(this.code, this.libelle);
  final String code;
  final String libelle;

  static TypeRemise fromCode(String? code) => TypeRemise.values.firstWhere(
    (t) => t.code == code,
    orElse: () => pourcentage,
  );
}

/// Code promo créé par le gérant, appliqué sur le total du panier.
/// Stocké dans `codesPromo/{CODE}` (le code en majuscules sert d'identifiant).
class CodePromo {
  const CodePromo({
    required this.code,
    required this.type,
    required this.valeur,
    this.minimum = 0,
    this.actif = true,
  });

  /// Code en majuscules, sans espaces (ex. BIENVENUE).
  final String code;
  final TypeRemise type;

  /// Pourcentage (1 à 100) ou montant en FCFA selon [type].
  final int valeur;

  /// Total minimum du panier pour utiliser le code (0 = aucun).
  final int minimum;

  final bool actif;

  /// Met un code saisi au bon format : majuscules, sans espaces.
  static String normaliser(String saisie) =>
      saisie.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  /// Réduction en FCFA pour un panier de [sousTotal] (jamais plus que le
  /// panier ; 0 si le minimum n'est pas atteint).
  int remisePour(int sousTotal) {
    if (!actif || sousTotal <= 0 || sousTotal < minimum) return 0;
    final r = switch (type) {
      TypeRemise.pourcentage => sousTotal * valeur.clamp(0, 100) ~/ 100,
      TypeRemise.montant => valeur,
    };
    return r.clamp(0, sousTotal);
  }

  /// Texte court : « -10 % » ou « -500 F ».
  String get description => switch (type) {
    TypeRemise.pourcentage => '-$valeur %',
    TypeRemise.montant => '-$valeur F',
  };

  factory CodePromo.fromMap(String code, Map<String, dynamic> data) =>
      CodePromo(
        code: code,
        type: TypeRemise.fromCode(data['type'] as String?),
        valeur: (data['valeur'] as num?)?.toInt() ?? 0,
        minimum: (data['minimum'] as num?)?.toInt() ?? 0,
        actif: data['actif'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
    'type': type.code,
    'valeur': valeur,
    'minimum': minimum,
    'actif': actif,
  };
}
