/// Une catégorie du menu (Nourriture, Boissons, Friandises...).
class Categorie {
  const Categorie({
    required this.id,
    required this.nom,
    this.icone = '🍽️',
    this.ordre = 0,
    this.visible = true,
    this.photoUrl,
  });

  final String id;
  final String nom;

  /// Emoji affiché sur le bouton de la catégorie.
  final String icone;

  /// Position dans la liste (croissant).
  final int ordre;

  /// Une catégorie masquée n'apparaît pas chez le client.
  final bool visible;

  /// Photo de la catégorie (adresse web ou fichier `assets/...`).
  final String? photoUrl;

  factory Categorie.fromMap(String id, Map<String, dynamic> data) {
    return Categorie(
      id: id,
      nom: data['nom'] as String? ?? '',
      icone: data['icone'] as String? ?? '🍽️',
      ordre: (data['ordre'] as num?)?.toInt() ?? 0,
      visible: data['visible'] as bool? ?? true,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'nom': nom,
    'icone': icone,
    'ordre': ordre,
    'visible': visible,
    'photoUrl': photoUrl,
  };

  Categorie copyWith({
    String? nom,
    String? icone,
    int? ordre,
    bool? visible,
    String? photoUrl,
  }) {
    return Categorie(
      id: id,
      nom: nom ?? this.nom,
      icone: icone ?? this.icone,
      ordre: ordre ?? this.ordre,
      visible: visible ?? this.visible,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
