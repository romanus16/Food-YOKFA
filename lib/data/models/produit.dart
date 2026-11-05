/// Un produit du menu (ex. Spaghetti, 1 000 F).
class Produit {
  const Produit({
    required this.id,
    required this.nom,
    required this.categorieId,
    required this.prix,
    this.photoUrl,
    this.disponible = true,
    this.visible = true,
    this.ordre = 0,
  });

  final String id;
  final String nom;
  final String categorieId;

  /// Prix en FCFA (entier, pas de centimes).
  final int prix;

  final String? photoUrl;

  /// Un produit indisponible est affiché mais ne peut pas être commandé.
  final bool disponible;

  /// Un produit masqué n'apparaît pas chez le client.
  final bool visible;

  final int ordre;

  factory Produit.fromMap(String id, Map<String, dynamic> data) {
    return Produit(
      id: id,
      nom: data['nom'] as String? ?? '',
      categorieId: data['categorieId'] as String? ?? '',
      prix: (data['prix'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] as String?,
      disponible: data['disponible'] as bool? ?? true,
      visible: data['visible'] as bool? ?? true,
      ordre: (data['ordre'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'nom': nom,
    'categorieId': categorieId,
    'prix': prix,
    'photoUrl': photoUrl,
    'disponible': disponible,
    'visible': visible,
    'ordre': ordre,
  };

  Produit copyWith({
    String? nom,
    String? categorieId,
    int? prix,
    String? photoUrl,
    bool? disponible,
    bool? visible,
    int? ordre,
  }) {
    return Produit(
      id: id,
      nom: nom ?? this.nom,
      categorieId: categorieId ?? this.categorieId,
      prix: prix ?? this.prix,
      photoUrl: photoUrl ?? this.photoUrl,
      disponible: disponible ?? this.disponible,
      visible: visible ?? this.visible,
      ordre: ordre ?? this.ordre,
    );
  }
}
