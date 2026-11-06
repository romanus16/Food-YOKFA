import 'package:cloud_firestore/cloud_firestore.dart';

/// Statuts d'une commande, dans l'ordre du parcours.
enum StatutCommande {
  enAttentePaiement('en_attente_paiement', 'En attente de paiement'),
  payee('payee', 'Payée'),
  livree('livree', 'Livrée'),
  annulee('annulee', 'Annulée');

  const StatutCommande(this.code, this.libelle);

  /// Valeur stockée dans Firestore.
  final String code;

  /// Texte affiché à l'écran.
  final String libelle;

  static StatutCommande fromCode(String? code) => StatutCommande.values
      .firstWhere((s) => s.code == code, orElse: () => enAttentePaiement);
}

enum Batiment {
  nouveau('nouveau', 'Nouveau bâtiment'),
  ancien('ancien', 'Ancien bâtiment');

  const Batiment(this.code, this.libelle);
  final String code;
  final String libelle;

  static Batiment fromCode(String? code) =>
      Batiment.values.firstWhere((b) => b.code == code, orElse: () => nouveau);
}

enum MoyenPaiement {
  tmoney('tmoney', 'T-Money', 'Togocel'),
  flooz('flooz', 'Flooz', 'Moov'),
  especes(
    'especes',
    'Espèces à la livraison',
    'Payez le livreur en main propre',
  );

  const MoyenPaiement(this.code, this.libelle, this.operateur);
  final String code;
  final String libelle;

  /// Opérateur mobile money, ou courte explication pour les espèces.
  final String operateur;

  /// Paiement fait avant la livraison, sur un compte marchand.
  bool get estMobileMoney => this != especes;

  static MoyenPaiement fromCode(String? code) => MoyenPaiement.values
      .firstWhere((m) => m.code == code, orElse: () => tmoney);
}

/// Une ligne de commande : un produit et sa quantité.
/// Le nom et le prix sont copiés au moment de la commande, pour que
/// l'historique reste juste si le menu change ensuite.
class LigneCommande {
  const LigneCommande({
    required this.produitId,
    required this.nom,
    required this.quantite,
    required this.prixUnitaire,
  });

  final String produitId;
  final String nom;
  final int quantite;
  final int prixUnitaire;

  int get sousTotal => quantite * prixUnitaire;

  factory LigneCommande.fromMap(Map<String, dynamic> data) => LigneCommande(
    produitId: data['produitId'] as String? ?? '',
    nom: data['nom'] as String? ?? '',
    quantite: (data['quantite'] as num?)?.toInt() ?? 0,
    prixUnitaire: (data['prixUnitaire'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'produitId': produitId,
    'nom': nom,
    'quantite': quantite,
    'prixUnitaire': prixUnitaire,
  };
}

/// Lieu précis de livraison choisi par le client (facultatif) :
/// un point sur la carte et/ou un point de repère en texte.
class LieuLivraison {
  const LieuLivraison({this.latitude, this.longitude, this.repere = ''});

  final double? latitude;
  final double? longitude;

  /// Exemple : « devant l'amphi B, banc sous le manguier ».
  final String repere;

  bool get aPosition => latitude != null && longitude != null;

  bool get estVide => !aPosition && repere.trim().isEmpty;

  /// Lien Google Maps qui ouvre l'itinéraire jusqu'au point.
  Uri? get itineraire => aPosition
      ? Uri.https('www.google.com', '/maps/dir/', {
          'api': '1',
          'destination': '$latitude,$longitude',
        })
      : null;

  static LieuLivraison? fromMap(Object? data) {
    if (data is! Map) return null;
    final lieu = LieuLivraison(
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      repere: data['repere'] as String? ?? '',
    );
    return lieu.estVide ? null : lieu;
  }

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'repere': repere.trim(),
  };
}

class Commande {
  const Commande({
    required this.id,
    required this.clientId,
    required this.lignes,
    required this.heureSouhaitee,
    required this.filiere,
    required this.batiment,
    required this.moyenPaiement,
    required this.codeQr,
    required this.creeLe,
    this.statut = StatutCommande.enAttentePaiement,
    this.referencePaiement,
    this.lieu,
    this.payeeLe,
    this.livreeLe,
    this.codePromo,
    this.remise = 0,
    this.livreurId,
    this.livreurNom,
    this.confieeLe,
  });

  final String id;
  final String clientId;
  final List<LigneCommande> lignes;
  final DateTime heureSouhaitee;
  final String filiere;
  final Batiment batiment;
  final MoyenPaiement moyenPaiement;

  /// Lieu précis de livraison, en plus du bâtiment (facultatif).
  final LieuLivraison? lieu;

  /// Identifiant aléatoire encodé dans le QR code remis au client.
  final String codeQr;

  final StatutCommande statut;

  /// Référence de la transaction mobile money saisie par le client.
  final String? referencePaiement;

  final DateTime creeLe;
  final DateTime? payeeLe;
  final DateTime? livreeLe;

  /// Code promo utilisé, s'il y en a un.
  final String? codePromo;

  /// Réduction du code promo, en FCFA (0 sans code).
  final int remise;

  /// Livreur à qui le gérant a confié la commande.
  final String? livreurId;
  final String? livreurNom;
  final DateTime? confieeLe;

  /// Total des produits, avant le code promo.
  int get sousTotal => lignes.fold(0, (s, l) => s + l.sousTotal);

  /// Montant à payer : produits moins la réduction du code promo.
  int get total => (sousTotal - remise).clamp(0, sousTotal);

  int get nombreArticles => lignes.fold(0, (s, l) => s + l.quantite);

  /// Commande en espèces pas encore livrée : le livreur doit encaisser
  /// [total] au moment du scan.
  bool get aEncaisser =>
      moyenPaiement == MoyenPaiement.especes &&
      statut == StatutCommande.enAttentePaiement;

  /// Commande prête à partir en livraison : payée, ou en espèces.
  bool get aLivrer => statut == StatutCommande.payee || aEncaisser;

  factory Commande.fromMap(String id, Map<String, dynamic> data) {
    return Commande(
      id: id,
      clientId: data['clientId'] as String? ?? '',
      lignes: ((data['lignes'] as List?) ?? const [])
          .map(
            (l) => LigneCommande.fromMap(Map<String, dynamic>.from(l as Map)),
          )
          .toList(),
      heureSouhaitee: _date(data['heureSouhaitee']) ?? DateTime.now(),
      filiere: data['filiere'] as String? ?? '',
      batiment: Batiment.fromCode(data['batiment'] as String?),
      moyenPaiement: MoyenPaiement.fromCode(data['moyenPaiement'] as String?),
      codeQr: data['codeQr'] as String? ?? '',
      statut: StatutCommande.fromCode(data['statut'] as String?),
      referencePaiement: data['referencePaiement'] as String?,
      lieu: LieuLivraison.fromMap(data['lieu']),
      creeLe: _date(data['creeLe']) ?? DateTime.now(),
      payeeLe: _date(data['payeeLe']),
      livreeLe: _date(data['livreeLe']),
      codePromo: data['codePromo'] as String?,
      remise: (data['remise'] as num?)?.toInt() ?? 0,
      livreurId: data['livreurId'] as String?,
      livreurNom: data['livreurNom'] as String?,
      confieeLe: _date(data['confieeLe']),
    );
  }

  Map<String, dynamic> toMap() => {
    'clientId': clientId,
    'lignes': lignes.map((l) => l.toMap()).toList(),
    'sousTotal': sousTotal,
    'codePromo': codePromo,
    'remise': remise,
    'total': total,
    'heureSouhaitee': Timestamp.fromDate(heureSouhaitee),
    'filiere': filiere,
    'batiment': batiment.code,
    'moyenPaiement': moyenPaiement.code,
    'codeQr': codeQr,
    'statut': statut.code,
    'referencePaiement': referencePaiement,
    'lieu': lieu?.toMap(),
    'creeLe': Timestamp.fromDate(creeLe),
    'payeeLe': payeeLe == null ? null : Timestamp.fromDate(payeeLe!),
    'livreeLe': livreeLe == null ? null : Timestamp.fromDate(livreeLe!),
    'livreurId': livreurId,
    'livreurNom': livreurNom,
    'confieeLe': confieeLe == null ? null : Timestamp.fromDate(confieeLe!),
  };

  static DateTime? _date(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
