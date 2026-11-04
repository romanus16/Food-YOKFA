import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/core/auth_gerant.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/features/gerant/gerant_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  Future<void> saisir(WidgetTester tester, String code) async {
    await tester.tap(find.text('Saisir le code à la main'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
  }

  testWidgets('scan d\'un QR valide puis du même QR', (tester) async {
    final db = FakeFirebaseFirestore();
    final repo = CommandeRepository(db);
    final id = await repo.creer(
      clientId: 'c',
      lignes: const [
        LigneCommande(
          produitId: 's',
          nom: 'Spaghetti',
          quantite: 3,
          prixUnitaire: 1000,
        ),
      ],
      heureSouhaitee: DateTime(2026, 11, 5, 12),
      filiere: 'Info',
      batiment: Batiment.ancien,
      moyenPaiement: MoyenPaiement.tmoney,
    );
    final code = (await repo.lire(id))!.codeQr;
    final auth = AuthGerantFactice(
      connecte: const CompteGerant(uid: 'g1', email: 'g@yokfa.tg'),
      gerants: {'g1'},
    );
    await tester.pumpWidget(
      monter(const GerantScreen(avecCamera: false), db, auth: auth),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scanner'));
    await tester.pumpAndSettle();

    // Pas encore payée : refusé.
    await saisir(tester, code);
    expect(find.text('QR code refusé'), findsOneWidget);
    expect(
      find.text('Cette commande n\'est pas encore payée.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Scanner un autre code'));
    await tester.pumpAndSettle();

    await repo.validerPaiement(id);
    await saisir(tester, code);
    expect(find.text('Commande livrée'), findsOneWidget);
    expect(find.textContaining('3 × Spaghetti'), findsOneWidget);
    expect((await repo.lire(id))!.statut, StatutCommande.livree);
    await tester.tap(find.text('Scanner un autre code'));
    await tester.pumpAndSettle();

    await saisir(tester, code);
    expect(find.text('Cette commande a déjà été livrée.'), findsOneWidget);
    await tester.tap(find.text('Scanner un autre code'));
    await tester.pumpAndSettle();

    await saisir(tester, 'n-importe-quoi');
    expect(find.textContaining('QR code inconnu'), findsOneWidget);
  });
}
