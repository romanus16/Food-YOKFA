import 'package:flutter/material.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/app.dart';
import 'package:food_yokfa/core/firebase_bootstrap.dart';
import 'package:food_yokfa/data/menu_demo.dart';

void main() {
  testWidgets('affiche les catégories du menu dans l\'ordre', (tester) async {
    final db = FakeFirebaseFirestore();
    await chargerMenuDemo(db);
    await db.collection('categories').doc('cachee').set({
      'nom': 'Cachée',
      'icone': '❓',
      'ordre': 0,
      'visible': false,
    });
    await tester.pumpWidget(
      FoodYokfaApp(firebase: const FirebaseStatus.ready(), db: db),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nourriture'), findsOneWidget);
    expect(find.text('Boissons'), findsOneWidget);
    expect(find.text('Friandises'), findsOneWidget);
    expect(find.text('Desserts'), findsOneWidget);
    expect(find.text('Cachée'), findsNothing);
    final yNourriture = tester.getTopLeft(find.text('Nourriture')).dy;
    final yFriandises = tester.getTopLeft(find.text('Friandises')).dy;
    expect(yNourriture, lessThan(yFriandises));
  });

  testWidgets('un appui sur une catégorie ouvre ses produits', (tester) async {
    final db = FakeFirebaseFirestore();
    await chargerMenuDemo(db);
    await tester.pumpWidget(
      FoodYokfaApp(firebase: const FirebaseStatus.ready(), db: db),
    );
    await tester.pumpAndSettle();
    // La barre du bas cache le bas de l'écran de test : on fait défiler.
    await tester.ensureVisible(find.text('Boissons'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boissons'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text("Boissons")),
      findsOneWidget,
    );
  });

  testWidgets('menu vide : message clair', (tester) async {
    await tester.pumpWidget(
      FoodYokfaApp(
        firebase: const FirebaseStatus.ready(),
        db: FakeFirebaseFirestore(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Le menu n\'est pas encore disponible.'), findsOneWidget);
  });

  testWidgets('signale quand Firebase n\'est pas configuré', (tester) async {
    await tester.pumpWidget(
      const FoodYokfaApp(firebase: FirebaseStatus.failed('non configuré')),
    );
    expect(find.text('Firebase non configuré (voir README)'), findsOneWidget);
  });
}
