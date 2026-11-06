import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/core/format.dart';
import 'package:food_yokfa/core/auth_gerant.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/models/livreur.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/features/gerant/detail_commande_screen.dart';
import 'package:food_yokfa/features/gerant/livreurs_gerant_screen.dart';
import 'package:food_yokfa/features/livreur/livreur_screen.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

const kossi = Livreur(uid: 'uid-kossi', nom: 'Kossi', actif: true);

Future<String> creerCommande(
  CommandeRepository repo, {
  MoyenPaiement moyen = MoyenPaiement.especes,
}) => repo.creer(
  clientId: 'client',
  lignes: const [
    LigneCommande(produitId: 'r', nom: 'Riz', quantite: 1, prixUnitaire: 800),
  ],
  heureSouhaitee: DateTime.now().add(const Duration(hours: 1)),
  filiere: 'Droit',
  batiment: Batiment.ancien,
  moyenPaiement: moyen,
);

void main() {
  group('livraison par un livreur', () {
    late FakeFirebaseFirestore db;
    late CommandeRepository repo;
    setUp(() {
      db = FakeFirebaseFirestore();
      repo = CommandeRepository(db);
    });

    test('le gérant confie, le livreur la voit puis la livre', () async {
      final id = await creerCommande(repo);
      await repo.confier(id, kossi);
      var c = (await repo.lire(id))!;
      expect(c.livreurId, 'uid-kossi');
      expect(c.livreurNom, 'Kossi');
      expect(c.confieeLe, isNotNull);
      expect((await repo.duLivreur('uid-kossi').first).single.id, id);

      expect(
        () => repo.livrerParLivreur(id, 'MAUVAIS', livreurId: 'uid-kossi'),
        throwsA(isA<CommandeException>()),
      );
      expect(
        () => repo.livrerParLivreur(id, c.codeQr, livreurId: 'uid-autre'),
        throwsA(isA<CommandeException>()),
      );
      expect(
        () => repo.livrerParLivreur(id, c.codeQr, livreurId: 'uid-kossi'),
        throwsA(
          isA<CommandeException>().having(
            (e) => e.message,
            'message',
            contains('Encaissez'),
          ),
        ),
      );
      await repo.livrerParLivreur(
        id,
        c.codeQr,
        livreurId: 'uid-kossi',
        especesEncaissees: true,
      );
      c = (await repo.lire(id))!;
      expect(c.statut, StatutCommande.livree);
      expect(c.payeeLe, isNotNull);
      expect(await repo.duLivreur('uid-kossi').first, isEmpty);
    });

    test('une commande mobile money non payée est refusée', () async {
      final id = await creerCommande(repo, moyen: MoyenPaiement.flooz);
      await repo.confier(id, kossi);
      final c = (await repo.lire(id))!;
      expect(await repo.duLivreur('uid-kossi').first, isEmpty);
      expect(
        () => repo.livrerParLivreur(id, c.codeQr, livreurId: 'uid-kossi'),
        throwsA(isA<CommandeException>()),
      );
    });
  });

  testWidgets('nouveau livreur : demande, puis acceptation par le gérant', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final auth = AuthGerantFactice(
      connecte: const CompteGerant(uid: 'uid-yao', email: 'yao@test.tg'),
    );
    await tester.pumpWidget(
      monter(const LivreurScreen(avecCamera: false), db, auth: auth),
    );
    await tester.pumpAndSettle();
    expect(find.text('Présentez-vous au gérant'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nom et prénom'),
      'Yao',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Téléphone'),
      '92000000',
    );
    await tester.tap(find.text('Envoyer ma demande'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Votre demande est envoyée'), findsOneWidget);

    // Côté gérant : la demande apparaît et il l'accepte.
    await tester.pumpWidget(
      monter(const Scaffold(body: LivreursGerantScreen()), db),
    );
    await tester.pumpAndSettle();
    expect(find.text('Demandes à accepter'), findsOneWidget);
    await tester.tap(find.byTooltip('Accepter Yao'));
    await tester.pumpAndSettle();
    expect(find.text('Demandes à accepter'), findsNothing);
    final doc = await db.collection('livreurs').doc('uid-yao').get();
    final l = Livreur.fromMap(doc.id, doc.data()!);
    expect(l.actif, isTrue);
    expect(l.telephone, '92000000');
  });

  testWidgets('le gérant confie une commande et le livreur la livre', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final repo = CommandeRepository(db);
    await db.collection('livreurs').doc('uid-kossi').set(kossi.toMap());
    final id = await creerCommande(repo);
    final code = (await repo.lire(id))!.codeQr;

    await tester.pumpWidget(monter(DetailCommandeScreen(commandeId: id), db));
    await tester.pumpAndSettle();
    expect(find.text('Aucun livreur'), findsOneWidget);
    await tester.tap(find.text('Confier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kossi'));
    await tester.pumpAndSettle();
    expect(find.text('Confiée à Kossi'), findsOneWidget);
    // On repart d'un écran neuf (sans le message « Commande confiée »).
    await tester.pumpWidget(const SizedBox());

    final auth = AuthGerantFactice(
      connecte: const CompteGerant(uid: 'uid-kossi', email: 'k@test.tg'),
    );
    await tester.pumpWidget(
      monter(const LivreurScreen(avecCamera: false), db, auth: auth),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 livraison à faire'), findsOneWidget);
    expect(find.text('Encaisser ${formatFcfa(800)}'), findsOneWidget);
    await tester.tap(find.text('Livrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saisir le code à la main'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('J\'ai reçu l\'argent'));
    await tester.pumpAndSettle();
    expect(find.text('Commande livrée. Merci !'), findsOneWidget);
    expect((await repo.lire(id))!.statut, StatutCommande.livree);
    expect(find.textContaining('Aucune livraison'), findsOneWidget);
  });
}
