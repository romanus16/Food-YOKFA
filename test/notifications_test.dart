import 'package:flutter/material.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/core/auth_gerant.dart';
import 'package:food_yokfa/core/notifications_gerant.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/features/gerant/detail_commande_screen.dart';
import 'package:food_yokfa/features/gerant/gerant_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('le téléphone du gérant est enregistré puis retiré', (
    tester,
  ) async {
    final notifs = NotificationsFactices();
    final auth = AuthGerantFactice(
      connecte: const CompteGerant(uid: 'g1', email: 'g@yokfa.tg'),
      gerants: {'g1'},
    );
    await tester.pumpWidget(
      monter(
        const GerantScreen(avecCamera: false),
        FakeFirebaseFirestore(),
        auth: auth,
        notifications: notifs,
      ),
    );
    await tester.pumpAndSettle();
    expect(notifs.actives, {'g1'});

    await tester.tap(find.byTooltip('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(notifs.actives, isEmpty);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('notification reçue appli ouverte : bandeau avec « Voir »', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final id = await CommandeRepository(db).creer(
      clientId: 'c',
      lignes: const [
        LigneCommande(
          produitId: 's',
          nom: 'Spaghetti',
          quantite: 3,
          prixUnitaire: 1000,
        ),
      ],
      heureSouhaitee: DateTime(2026, 11, 5, 12, 30),
      filiere: 'Info',
      batiment: Batiment.ancien,
      moyenPaiement: MoyenPaiement.tmoney,
    );
    final notifs = NotificationsFactices();
    await tester.pumpWidget(
      monter(
        const GerantScreen(avecCamera: false),
        db,
        auth: AuthGerantFactice(
          connecte: const CompteGerant(uid: 'g1', email: 'g@yokfa.tg'),
          gerants: {'g1'},
        ),
        notifications: notifs,
      ),
    );
    await tester.pumpAndSettle();

    notifs.premierPlanCtrl.add(
      NotificationRecue(
        titre: 'Nouvelle commande',
        corps: '3 × Spaghetti, ancien bâtiment, pour 12 h 30',
        commandeId: id,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.textContaining('Nouvelle commande : 3 × Spaghetti'),
      findsOneWidget,
    );
    // Appel direct : en test, la barre de navigation recouvre le bandeau.
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pumpAndSettle();
    expect(find.byType(DetailCommandeScreen), findsOneWidget);
    expect(find.text('Valider le paiement'), findsOneWidget);
  });
}
