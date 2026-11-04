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

  const romaric = CompteGerant(uid: 'g1', email: 'romaric@yokfa.tg');

  Future<String> commande(FakeFirebaseFirestore db, {int heure = 12}) =>
      CommandeRepository(db).creer(
        clientId: 'c',
        lignes: const [
          LigneCommande(
            produitId: 's',
            nom: 'Spaghetti',
            quantite: 3,
            prixUnitaire: 1000,
          ),
        ],
        heureSouhaitee: DateTime(2026, 11, 5, heure, 30),
        filiere: 'Informatique',
        batiment: Batiment.ancien,
        moyenPaiement: MoyenPaiement.tmoney,
      );

  testWidgets('sans connexion : écran de connexion, erreur claire', (
    tester,
  ) async {
    final auth = AuthGerantFactice(comptes: {'romaric@yokfa.tg': 'secret1'});
    await tester.pumpWidget(
      monter(
        const GerantScreen(avecCamera: false),
        FakeFirebaseFirestore(),
        auth: auth,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Se connecter'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'romaric@yokfa.tg');
    await tester.enterText(find.byType(TextField).last, 'mauvais');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('E-mail ou mot de passe incorrect.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    // Connecté mais pas encore gérant : l'uid à transmettre est affiché.
    expect(find.textContaining('n\'est pas encore gérant'), findsOneWidget);
    expect(find.text('uid-romaric@yokfa.tg'), findsOneWidget);
  });

  testWidgets('le gérant voit les commandes à valider et valide le paiement', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final id = await commande(db);
    await CommandeRepository(db).enregistrerReferencePaiement(id, 'TX42');
    final auth = AuthGerantFactice(connecte: romaric, gerants: {'g1'});
    await tester.pumpWidget(
      monter(const GerantScreen(avecCamera: false), db, auth: auth),
    );
    await tester.pumpAndSettle();

    expect(find.text('Espace gérant'), findsOneWidget);
    expect(find.text('3 × Spaghetti'), findsOneWidget);
    await tester.tap(find.text('3 × Spaghetti'));
    await tester.pumpAndSettle();
    expect(find.text('Informatique'), findsOneWidget);
    expect(find.text('Ancien bâtiment'), findsOneWidget);
    expect(find.text('TX42'), findsOneWidget);

    await tester.tap(find.text('Valider le paiement'));
    await tester.pumpAndSettle();
    final c = (await CommandeRepository(db).lire(id))!;
    expect(c.statut, StatutCommande.payee);
    expect(find.text('Valider le paiement'), findsNothing);
  });

  testWidgets('filtre par statut, tri par heure souhaitée', (tester) async {
    final db = FakeFirebaseFirestore();
    final soir = await commande(db, heure: 19);
    await commande(db, heure: 11);
    await CommandeRepository(db).validerPaiement(soir);
    final auth = AuthGerantFactice(connecte: romaric, gerants: {'g1'});
    await tester.pumpWidget(
      monter(const GerantScreen(avecCamera: false), db, auth: auth),
    );
    await tester.pumpAndSettle();

    // « À valider » par défaut : seulement celle de 11 h.
    expect(find.textContaining('11:30'), findsOneWidget);
    expect(find.textContaining('19:30'), findsNothing);

    await tester.tap(find.text('Toutes'));
    await tester.pumpAndSettle();
    final y11 = tester.getTopLeft(find.textContaining('11:30')).dy;
    final y19 = tester.getTopLeft(find.textContaining('19:30')).dy;
    expect(y11, lessThan(y19));

    await tester.tap(find.text('À livrer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('19:30'), findsOneWidget);
    expect(find.textContaining('11:30'), findsNothing);
  });

  testWidgets('annulation avec confirmation', (tester) async {
    final db = FakeFirebaseFirestore();
    final id = await commande(db);
    final auth = AuthGerantFactice(connecte: romaric, gerants: {'g1'});
    await tester.pumpWidget(
      monter(const GerantScreen(avecCamera: false), db, auth: auth),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 × Spaghetti'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler la commande'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oui, annuler'));
    await tester.pumpAndSettle();
    expect(
      (await CommandeRepository(db).lire(id))!.statut,
      StatutCommande.annulee,
    );
  });
}
