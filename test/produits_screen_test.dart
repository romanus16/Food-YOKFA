import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/app.dart';
import 'package:food_yokfa/core/firebase_bootstrap.dart';
import 'package:food_yokfa/data/menu_demo.dart';

void main() {
  testWidgets('choisir 3 spaghettis fait apparaître Commander', (tester) async {
    final db = FakeFirebaseFirestore();
    await chargerMenuDemo(db);
    await db.collection('produits').add({
      'nom': 'Attiéké',
      'categorieId': 'nourriture',
      'prix': 700,
      'disponible': false,
      'visible': true,
      'ordre': 99,
    });
    await tester.pumpWidget(
      FoodYokfaApp(firebase: const FirebaseStatus.ready(), db: db),
    );
    await tester.pumpAndSettle();
    expect(find.text('Commander'), findsNothing);

    // La barre du bas cache le bas de l'écran de test : on fait défiler.
    await tester.ensureVisible(find.text('Nourriture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nourriture'));
    await tester.pumpAndSettle();
    expect(find.text('Spaghetti'), findsOneWidget);
    expect(find.text('1 000 F'), findsOneWidget);
    expect(find.text('Indisponible'), findsOneWidget);
    expect(find.text('Commander'), findsNothing);

    final plus = find.byTooltip('Ajouter un Spaghetti');
    await tester.tap(plus);
    await tester.pump();
    expect(find.text('Commander'), findsOneWidget);
    await tester.tap(plus);
    await tester.tap(plus);
    await tester.pump();
    expect(find.textContaining('3 articles · 3 000 F'), findsOneWidget);

    await tester.tap(find.byTooltip('Retirer un Spaghetti'));
    await tester.pump();
    expect(find.textContaining('2 articles'), findsOneWidget);

    // Le panier est conservé en revenant à l'accueil.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Commander'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
