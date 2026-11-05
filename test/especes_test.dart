import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/core/auth_gerant.dart';
import 'package:food_yokfa/core/format.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/features/gerant/gerant_screen.dart';
import 'package:food_yokfa/features/paiement/paiement_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  Future<String> commander(
    CommandeRepository repo, {
    MoyenPaiement moyen = MoyenPaiement.especes,
  }) => repo.creer(
    clientId: 'c',
    lignes: const [
      LigneCommande(
        produitId: 's',
        nom: 'Spaghetti',
        quantite: 2,
        prixUnitaire: 1000,
      ),
    ],
    heureSouhaitee: DateTime(2026, 11, 5, 12),
    filiere: 'Info',
    batiment: Batiment.nouveau,
    moyenPaiement: moyen,
  );

  group('dépôt', () {
    test(
      'espèces : livraison refusée tant que l\'argent n\'est pas reçu',
      () async {
        final repo = CommandeRepository(FakeFirebaseFirestore());
        final id = await commander(repo);
        final c = (await repo.lire(id))!;
        expect(c.aEncaisser, isTrue);
        expect(c.aLivrer, isTrue);

        await expectLater(
          repo.confirmerLivraison(c.codeQr),
          throwsA(isA<CommandeException>()),
        );
        await expectLater(
          repo.validerPaiement(id),
          throwsA(isA<CommandeException>()),
        );

        final livree = await repo.confirmerLivraison(
          c.codeQr,
          especesEncaissees: true,
        );
        expect(livree.statut, StatutCommande.livree);
        final relue = (await repo.lire(id))!;
        expect(relue.statut, StatutCommande.livree);
        expect(relue.payeeLe, isNotNull);
        expect(relue.livreeLe, isNotNull);
      },
    );

    test(
      'mobile money non payé : toujours refusé, même « encaissé »',
      () async {
        final repo = CommandeRepository(FakeFirebaseFirestore());
        final id = await commander(repo, moyen: MoyenPaiement.flooz);
        final c = (await repo.lire(id))!;
        expect(c.aLivrer, isFalse);
        await expectLater(
          repo.confirmerLivraison(c.codeQr, especesEncaissees: true),
          throwsA(isA<CommandeException>()),
        );
      },
    );
  });

  testWidgets('le client voit son QR code et le montant à préparer', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final id = await commander(CommandeRepository(db));
    await tester.pumpWidget(monter(PaiementScreen(commandeId: id), db));
    await tester.pumpAndSettle();

    expect(find.text('Paiement en espèces à la livraison'), findsOneWidget);
    expect(find.byKey(const Key('montant-especes')), findsOneWidget);
    expect(find.textContaining(formatFcfa(2000)), findsWidgets);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Référence de paiement'), findsNothing);
  });

  testWidgets('gérant : « À livrer », puis encaissement au scan', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final repo = CommandeRepository(db);
    final id = await commander(repo);
    final code = (await repo.lire(id))!.codeQr;
    await tester.pumpWidget(
      monter(
        const GerantScreen(avecCamera: false),
        db,
        auth: AuthGerantFactice(
          connecte: const CompteGerant(uid: 'g1', email: 'g@yokfa.tg'),
          gerants: {'g1'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pas dans « À valider » (rien à valider), mais dans « À livrer ».
    expect(find.text('Aucune commande.'), findsOneWidget);
    await tester.tap(find.text('À livrer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Espèces à encaisser'), findsOneWidget);

    await tester.tap(find.text('Scanner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saisir le code à la main'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Encaisser 2'), findsOneWidget);
    await tester.tap(find.text('Pas encore'));
    await tester.pumpAndSettle();
    expect((await repo.lire(id))!.statut, StatutCommande.enAttentePaiement);

    await tester.tap(find.text('Saisir le code à la main'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('J\'ai reçu l\'argent'));
    await tester.pumpAndSettle();
    expect(find.text('Commande livrée'), findsOneWidget);
    expect((await repo.lire(id))!.statut, StatutCommande.livree);
  });
}
