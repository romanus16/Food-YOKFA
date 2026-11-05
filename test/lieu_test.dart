import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/models/produit.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/features/commande/formulaire_commande_screen.dart';
import 'package:food_yokfa/features/gerant/detail_commande_screen.dart';
import 'package:food_yokfa/features/lieu/carte.dart';
import 'package:food_yokfa/features/panier/panier.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';

import 'support/harness.dart';

void main() {
  setUpAll(() {
    Carte.tuilesReseau = false;
    return initializeDateFormatting('fr');
  });

  void grandEcran(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
  }

  group('LieuLivraison', () {
    test('aller-retour Firestore et lien d\'itinéraire', () {
      const lieu = LieuLivraison(
        latitude: 6.17,
        longitude: 1.21,
        repere: ' Amphi B ',
      );
      final relu = LieuLivraison.fromMap(lieu.toMap())!;
      expect(relu.latitude, 6.17);
      expect(relu.longitude, 1.21);
      expect(relu.repere, 'Amphi B');
      expect(
        relu.itineraire.toString(),
        'https://www.google.com/maps/dir/?api=1&destination=6.17%2C1.21',
      );
    });

    test('un lieu vide n\'est pas enregistré', () async {
      final db = FakeFirebaseFirestore();
      final repo = CommandeRepository(db);
      final id = await repo.creer(
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
        lieu: const LieuLivraison(repere: '  '),
      );
      expect((await repo.lire(id))!.lieu, isNull);
    });
  });

  testWidgets('le client choisit le lieu sur la carte et un repère', (
    tester,
  ) async {
    grandEcran(tester);
    final db = FakeFirebaseFirestore();
    final panier = Panier()
      ..ajouter(
        const Produit(id: 's', nom: 'Spaghetti', categorieId: 'n', prix: 1000),
      );
    await tester.pumpWidget(
      monter(
        FormulaireCommandeScreen(
          maintenant: () => DateTime(2026, 11, 5, 10, 0),
          localiser: () async => const LatLng(6.1751, 1.2132),
        ),
        db,
        panier: panier,
      ),
    );

    await tester.tap(find.text('Choisir sur la carte'));
    await tester.pumpAndSettle();
    expect(find.text('Lieu de livraison'), findsOneWidget);
    await tester.tap(find.text('Valider ce lieu'));
    await tester.pumpAndSettle();
    expect(find.text('Lieu choisi sur la carte'), findsOneWidget);
    expect(find.text('6.17510, 1.21320'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Point de repère'),
      'Devant l\'amphi B',
    );
    await tester.tap(find.text('Choisir le jour et l\'heure'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Informatique L2');
    await tester.tap(find.text('Nouveau bâtiment'));
    await tester.tap(find.text('T-Money'));
    await tester.pump();
    await tester.tap(find.textContaining('Valider ·'));
    await tester.pumpAndSettle();

    final docs = (await db.collection('commandes').get()).docs;
    expect(docs, hasLength(1));
    final c = Commande.fromMap(docs.first.id, docs.first.data());
    expect(c.lieu!.latitude, 6.1751);
    expect(c.lieu!.longitude, 1.2132);
    expect(c.lieu!.repere, 'Devant l\'amphi B');
  });

  testWidgets('le livreur voit le lieu et le bouton Itinéraire', (
    tester,
  ) async {
    grandEcran(tester);
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
      lieu: const LieuLivraison(
        latitude: 6.1751,
        longitude: 1.2132,
        repere: 'Devant l\'amphi B',
      ),
    );
    await tester.pumpWidget(monter(DetailCommandeScreen(commandeId: id), db));
    await tester.pumpAndSettle();
    expect(find.byType(CarteLieu), findsOneWidget);
    expect(find.text('Devant l\'amphi B'), findsOneWidget);
    expect(find.text('Itinéraire'), findsOneWidget);
  });
}
