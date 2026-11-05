import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/features/commande/mes_commandes_screen.dart';
import 'package:food_yokfa/features/paiement/paiement_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/harness.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('liste seulement les commandes du client et rouvre le QR', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final repo = CommandeRepository(db);
    Future<String> creer(String client, String nom) => repo.creer(
      clientId: client,
      lignes: [
        LigneCommande(produitId: 'p', nom: nom, quantite: 1, prixUnitaire: 500),
      ],
      heureSouhaitee: DateTime(2026, 11, 5, 12),
      filiere: 'Info',
      batiment: Batiment.nouveau,
      moyenPaiement: MoyenPaiement.tmoney,
    );
    final id = await creer('client-test', 'Jus');
    await creer('autre-client', 'Riz');
    await repo.validerPaiement(id);

    await tester.pumpWidget(monter(const MesCommandesScreen(), db));
    await tester.pumpAndSettle();
    expect(find.text('1 × Jus'), findsOneWidget);
    expect(find.text('1 × Riz'), findsNothing);

    await tester.tap(find.text('1 × Jus'));
    await tester.pumpAndSettle();
    expect(find.byType(SuiviPayee), findsOneWidget);
  });
}
