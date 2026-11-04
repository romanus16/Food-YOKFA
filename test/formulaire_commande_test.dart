import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/core/identite.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/models/produit.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/features/commande/formulaire_commande_screen.dart';
import 'package:food_yokfa/features/panier/panier.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'support/fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  Future<(FakeFirebaseFirestore, Panier)> ouvrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final db = FakeFirebaseFirestore();
    final panier = Panier()
      ..ajouter(
        const Produit(id: 's', nom: 'Spaghetti', categorieId: 'n', prix: 1000),
      )
      ..ajouter(
        const Produit(id: 's', nom: 'Spaghetti', categorieId: 'n', prix: 1000),
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => CommandeRepository(db)),
          Provider<Identite>(create: (_) => IdentiteFactice()),
          ChangeNotifierProvider.value(value: panier),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: FormulaireCommandeScreen(
            maintenant: () => DateTime(2026, 11, 5, 10, 0),
          ),
        ),
      ),
    );
    return (db, panier);
  }

  testWidgets('bloque la validation tant qu\'un champ manque', (tester) async {
    final (db, _) = await ouvrir(tester);
    expect(find.text('2 × Spaghetti'), findsOneWidget);
    await tester.tap(find.textContaining('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Choisissez quand vous voulez le plat.'), findsOneWidget);
    expect(find.text('Indiquez votre filière.'), findsOneWidget);
    expect(find.text('Choisissez un bâtiment.'), findsOneWidget);
    expect(find.text('Choisissez un moyen de paiement.'), findsOneWidget);
    expect((await db.collection('commandes').get()).docs, isEmpty);
  });

  testWidgets('crée la commande et vide le panier', (tester) async {
    final (db, panier) = await ouvrir(tester);
    await tester.tap(find.text('Choisir le jour et l\'heure'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Informatique L2');
    await tester.tap(find.text('Ancien bâtiment'));
    await tester.tap(find.text('Flooz'));
    await tester.pump();
    await tester.tap(find.textContaining('Valider'));
    await tester.pumpAndSettle();

    final docs = (await db.collection('commandes').get()).docs;
    expect(docs, hasLength(1));
    final c = Commande.fromMap(docs.first.id, docs.first.data());
    expect(c.clientId, 'client-test');
    expect(c.total, 2000);
    expect(c.filiere, 'Informatique L2');
    expect(c.batiment, Batiment.ancien);
    expect(c.moyenPaiement, MoyenPaiement.flooz);
    expect(c.heureSouhaitee, DateTime(2026, 11, 5, 10, 30));
    expect(c.statut, StatutCommande.enAttentePaiement);
    expect(panier.estVide, isTrue);
  });
}
