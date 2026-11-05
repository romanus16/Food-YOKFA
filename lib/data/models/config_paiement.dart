import 'commande.dart';

/// Numéros des comptes marchands, modifiables par le gérant
/// (document Firestore `config/paiement`).
class ConfigPaiement {
  const ConfigPaiement({this.numeroTmoney = '', this.numeroFlooz = ''});

  final String numeroTmoney;
  final String numeroFlooz;

  String numeroPour(MoyenPaiement moyen) =>
      moyen == MoyenPaiement.tmoney ? numeroTmoney : numeroFlooz;

  factory ConfigPaiement.fromMap(Map<String, dynamic>? data) => ConfigPaiement(
    numeroTmoney: data?['numeroTmoney'] as String? ?? '',
    numeroFlooz: data?['numeroFlooz'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'numeroTmoney': numeroTmoney,
    'numeroFlooz': numeroFlooz,
  };
}
