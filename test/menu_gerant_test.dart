import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/data/models/produit.dart';
import 'package:food_yokfa/data/models/config_paiement.dart';
import 'package:food_yokfa/data/repositories/menu_repository.dart';
import 'package:food_yokfa/features/gerant/menu_gerant_screen.dart';

import 'support/harness.dart';

void main() {
  Widget ecran(FakeFirebaseFirestore db) =>
      monter(const Scaffold(body: MenuGerantScreen()), db);

  testWidgets('menu vide : charger l\'exemple', (tester) async {
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(ecran(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Charger le menu d\'exemple'));
    await tester.pumpAndSettle();
    expect(find.text('Nourriture'), findsOneWidget);
    expect(find.text('Desserts'), findsOneWidget);
  });

  testWidgets('ajouter un produit puis le rendre indisponible', (tester) async {
    final db = FakeFirebaseFirestore();
    final menu = MenuRepository(db);
    await db.collection('categories').doc('n').set({
      'nom': 'Nourriture',
      'icone': '🍝',
      'ordre': 1,
      'visible': true,
    });
    await tester.pumpWidget(ecran(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nourriture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter un produit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Indiquez un nom.'), findsOneWidget);
    expect(find.text('Indiquez un prix.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nom'),
      'Spaghetti',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Prix'), '1000');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    var produits = await menu.produits('n').first;
    expect(produits.single.nom, 'Spaghetti');
    expect(produits.single.prix, 1000);
    expect(produits.single.disponible, isTrue);

    expect(find.text('Spaghetti'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    produits = await menu.produits('n').first;
    expect(produits.single.disponible, isFalse);
  });

  testWidgets('modifier le prix d\'un produit', (tester) async {
    final db = FakeFirebaseFirestore();
    final menu = MenuRepository(db);
    await db.collection('categories').doc('n').set({
      'nom': 'Nourriture',
      'icone': '🍝',
      'ordre': 1,
      'visible': true,
    });
    await menu.ajouterProduit(
      const Produit(id: '', nom: 'Riz', categorieId: 'n', prix: 800),
    );
    await tester.pumpWidget(ecran(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nourriture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riz'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Prix'), '900');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect((await menu.produits('n').first).single.prix, 900);
  });

  testWidgets('ajouter une catégorie masquée', (tester) async {
    final db = FakeFirebaseFirestore();
    final menu = MenuRepository(db);
    await menu.ajouterProduit(
      const Produit(id: '', nom: 'x', categorieId: 'z', prix: 1),
    );
    await db.collection('categories').doc('n').set({
      'nom': 'Nourriture',
      'icone': '🍝',
      'ordre': 1,
      'visible': true,
    });
    await tester.pumpWidget(ecran(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter une catégorie'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom'),
      'Petit-déjeuner',
    );
    await tester.tap(find.text('Visible par les clients'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Petit-déjeuner'), findsOneWidget);
    final visibles = await menu.categories().first;
    expect(visibles.map((c) => c.nom), ['Nourriture']);
    final toutes = await menu.categories(toutes: true).first;
    expect(toutes.map((c) => c.nom), ['Nourriture', 'Petit-déjeuner']);
  });

  testWidgets('renseigner les numéros marchands', (tester) async {
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(ecran(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Numéros marchands'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'T-Money (Togocel)'),
      '90000001',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Flooz (Moov)'),
      '99000002',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final c = ConfigPaiement.fromMap(
      (await db.collection('config').doc('paiement').get()).data(),
    );
    expect(c.numeroTmoney, '90000001');
    expect(c.numeroFlooz, '99000002');
    expect(find.textContaining('T-Money : 90000001'), findsOneWidget);
  });
}
