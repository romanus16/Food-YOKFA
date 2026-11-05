import 'package:intl/intl.dart';

final NumberFormat _fcfa = NumberFormat.decimalPattern('fr');

/// Formate un montant en francs CFA, sans décimales.
///
/// Exemple : `formatFcfa(1000)` donne `1 000 F`.
/// Les montants sont stockés en entiers (FCFA n'a pas de centimes).
String formatFcfa(int montant) {
  // intl utilise une espace insécable étroite comme séparateur de milliers
  // en français ; on la remplace par une espace insécable classique pour
  // un rendu homogène sur tous les téléphones.
  final chiffres = _fcfa.format(montant).replaceAll(' ', ' ');
  return '$chiffres F';
}
