import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/app.dart';
import 'package:food_yokfa/core/demo.dart';
import 'package:food_yokfa/core/firebase_bootstrap.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/features/lieu/carte.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));
  setUp(() {
    ModeDemo.actif = true;
    Carte.tuilesReseau = false;
  });
  tearDown(() => ModeDemo.actif = false);

  test('la base démo contient menu, numéros et commandes d\'exemple', () async {
    final db = await ModeDemo.creerBase();
    expect((await db.collection('categories').get()).docs, hasLength(4));
    final config = await db.collection('config').doc('paiement').get();
    expect(config.data()!['numeroTmoney'], isNotEmpty);
    final toutes = await CommandeRepository(db).toutes().first;
    expect(toutes, hasLength(3));
    final livree = await CommandeRepository(db)
        .confirmerLivraison(ModeDemo.codePayee);
    expect(livree.statut, StatutCommande.livree);
  });

  testWidgets('démo : menu affiché et espace gérant ouvert sans compte', (
    tester,
  ) async {
    final db = await tester.runAsync(ModeDemo.creerBase);
    await tester.pumpWidget(
      FoodYokfaApp(
        firebase: const FirebaseStatus.demo(),
        db: db,
        identite: IdentiteDemo(),
        authGerant: AuthGerantDemo(),
        notifications: NotificationsDemo(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nourriture'), findsOneWidget);
    expect(find.textContaining('Mode démo :'), findsOneWidget);

    await tester.tap(find.byTooltip('Plus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Espace gérant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('n\'importe quel e-mail'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'demo@yokfa.tg');
    await tester.enterText(find.byType(TextField).last, 'demo');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Se connecter'), findsNothing);
  });
}
