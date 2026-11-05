import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/models/config_paiement.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/data/repositories/config_repository.dart';
import 'package:food_yokfa/features/paiement/paiement_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/harness.dart';

void main() {
  Future<(FakeFirebaseFirestore, String)> preparer() async {
    final db = FakeFirebaseFirestore();
    await ConfigRepository(db).enregistrerPaiement(
      const ConfigPaiement(
        numeroTmoney: '90 00 00 01',
        numeroFlooz: '99 00 00 02',
      ),
    );
    final id = await CommandeRepository(db).creer(
      clientId: 'client-test',
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
      batiment: Batiment.nouveau,
      moyenPaiement: MoyenPaiement.flooz,
    );
    return (db, id);
  }

  testWidgets('affiche le numéro Flooz et enregistre la référence', (
    tester,
  ) async {
    final (db, id) = await preparer();
    await tester.pumpWidget(monter(PaiementScreen(commandeId: id), db));
    await tester.pumpAndSettle();

    expect(find.text('Payer par Flooz'), findsOneWidget);
    expect(find.textContaining('3 000 F'), findsWidgets);
    expect(find.text('99 00 00 02'), findsOneWidget);

    // Référence vide refusée.
    await tester.tap(find.text('J\'ai payé'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez la référence de paiement.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'CI251104.1234.A56789');
    await tester.tap(find.text('J\'ai payé'));
    await tester.pumpAndSettle();
    final c = (await CommandeRepository(db).lire(id))!;
    expect(c.referencePaiement, 'CI251104.1234.A56789');
    expect(c.statut, StatutCommande.enAttentePaiement);
  });

  testWidgets('passe à « Payée » quand le gérant valide', (tester) async {
    final (db, id) = await preparer();
    await CommandeRepository(db).enregistrerReferencePaiement(id, 'REF1');
    await tester.pumpWidget(monter(PaiementScreen(commandeId: id), db));
    await tester.pumpAndSettle();
    expect(find.textContaining('en cours de vérification'), findsOneWidget);

    await CommandeRepository(db).validerPaiement(id);
    await tester.pumpAndSettle();
    expect(find.byType(SuiviPayee), findsOneWidget);
    expect(find.text('Paiement confirmé'), findsOneWidget);
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    final c = (await CommandeRepository(db).lire(id))!;
    expect(c.codeQr, hasLength(24));
    expect(qr.semanticsLabel, 'QR code de la commande');
  });

  testWidgets('numéro marchand non configuré : message clair', (tester) async {
    final db = FakeFirebaseFirestore();
    final id = await CommandeRepository(db).creer(
      clientId: 'c',
      lignes: const [
        LigneCommande(
          produitId: 'e',
          nom: 'Eau',
          quantite: 1,
          prixUnitaire: 300,
        ),
      ],
      heureSouhaitee: DateTime(2026, 11, 5, 12),
      filiere: 'Info',
      batiment: Batiment.nouveau,
      moyenPaiement: MoyenPaiement.tmoney,
    );
    await tester.pumpWidget(monter(PaiementScreen(commandeId: id), db));
    await tester.pumpAndSettle();
    expect(find.textContaining('pas encore configuré'), findsOneWidget);
  });
}
