import 'package:flutter/foundation.dart';

import '../../data/models/commande.dart';
import '../../data/models/produit.dart';

/// Panier du client : quantités choisies, toutes catégories confondues.
class Panier extends ChangeNotifier {
  final Map<String, (Produit, int)> _lignes = {};

  int quantite(String produitId) => _lignes[produitId]?.$2 ?? 0;

  bool get estVide => _lignes.isEmpty;

  int get nombreArticles => _lignes.values.fold(0, (s, l) => s + l.$2);

  int get total => _lignes.values.fold(0, (s, l) => s + l.$1.prix * l.$2);

  /// Lignes prêtes à enregistrer dans une commande (nom et prix figés).
  List<LigneCommande> get lignes => [
    for (final (p, q) in _lignes.values)
      LigneCommande(
        produitId: p.id,
        nom: p.nom,
        quantite: q,
        prixUnitaire: p.prix,
      ),
  ];

  /// Appui sur « + ». Sans effet si le produit est indisponible.
  void ajouter(Produit p) {
    if (!p.disponible) return;
    _lignes[p.id] = (p, quantite(p.id) + 1);
    notifyListeners();
  }

  /// Appui sur « − ». La quantité ne descend jamais sous 0.
  void retirer(Produit p) {
    final q = quantite(p.id);
    if (q == 0) return;
    if (q == 1) {
      _lignes.remove(p.id);
    } else {
      _lignes[p.id] = (p, q - 1);
    }
    notifyListeners();
  }

  void vider() {
    _lignes.clear();
    notifyListeners();
  }
}
