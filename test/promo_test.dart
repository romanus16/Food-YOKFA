import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/core/format.dart';
import 'package:food_yokfa/data/models/code_promo.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/models/produit.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/data/repositories/promo_repository.dart';
import 'package:food_yokfa/features/panier/panier.dart';
import 'package:food_yokfa/features/panier/panier_screen.dart';

import 'support/harness.dart';

const spaghetti = Produit(
  id: 's',
  nom: 'Spaghetti',
  categorieId: 'n',
  prix: 1000,
);

void main() {
  group('CodePromo.remisePour', () {
    test('pourcentage arrondi vers le bas', () {
      const p = CodePromo(code: 'A', type: TypeRemise.pourcentage, valeur: 15);
      expect(p.remisePour(1050), 157);
    });
    test('montant fixe, jamais plus que le panier', () {
      const p = CodePromo(code: 'B', type: TypeRemise.montant, valeur: 500);
      expect(p.remisePour(2000), 500);
      expect(p.remisePour(300), 300);
    });
    test('rien sous le minimum ou si désactivé', () {
      const p = CodePromo(
        code: 'C',
        type: TypeRemise.montant,
        valeur: 200,
        minimum: 1500,
      );
      expect(p.remisePour(1000), 0);
      expect(p.remisePour(1500), 200);
      const off = CodePromo(
        code: 'D',
        type: TypeRemise.pourcentage,
        valeur: 10,
        actif: false,
      );
      expect(off.remisePour(1000), 0);
    });
    test('code saisi normalisé', () {
      expect(CodePromo.normaliser(' bien venue '), 'BIENVENUE');
    });
  });

  group('PromoRepository.verifier', () {
    late FakeFirebaseFirestore db;
    late PromoRepository repo;
    setUp(() async {
      db = FakeFirebaseFirestore();
      repo = PromoRepository(db);
      await repo.enregistrer(
        const CodePromo(
          code: 'bienvenue',
          type: TypeRemise.pourcentage,
          valeur: 10,
        ),
      );
      await repo.enregistrer(
        const CodePromo(
          code: 'VIEUX',
          type: TypeRemise.pourcentage,
          valeur: 10,
          actif: false,
        ),
      );
      await repo.enregistrer(
        const CodePromo(
          code: 'ETUDIANT',
          type: TypeRemise.montant,
          valeur: 200,
          minimum: 1500,
        ),
      );
    });

    test('code valide, quelle que soit la casse', () async {
      final p = await repo.verifier('Bienvenue', 1000);
      expect(p.code, 'BIENVENUE');
    });
    test('codes refusés avec un message clair', () async {
      expect(
        () => repo.verifier('INCONNU', 1000),
        throwsA(
          isA<PromoException>().having(
            (e) => e.message,
            'message',
            contains('n\'existe pas'),
          ),
        ),
      );
      expect(
        () => repo.verifier('VIEUX', 1000),
        throwsA(isA<PromoException>()),
      );
      expect(
        () => repo.verifier('ETUDIANT', 1000),
        throwsA(
          isA<PromoException>().having(
            (e) => e.message,
            'message',
            contains(formatFcfa(1500)),
          ),
        ),
      );
    });
  });

  test('panier : la remise suit le total et disparaît au vidage', () {
    final panier = Panier()
      ..ajouter(spaghetti)
      ..ajouter(spaghetti);
    panier.appliquerPromo(
      const CodePromo(
        code: 'ETUDIANT',
        type: TypeRemise.montant,
        valeur: 200,
        minimum: 1500,
      ),
    );
    expect(panier.sousTotal, 2000);
    expect(panier.remise, 200);
    expect(panier.total, 1800);
    panier.retirer(spaghetti);
    expect(panier.remise, 0, reason: 'sous le minimum');
    expect(panier.total, 1000);
    panier.vider();
    expect(panier.promo, isNull);
  });

  test('la commande enregistre le code, la remise et le total payé', () async {
    final db = FakeFirebaseFirestore();
    final repo = CommandeRepository(db);
    final id = await repo.creer(
      clientId: 'c',
      lignes: const [
        LigneCommande(
          produitId: 's',
          nom: 'Spaghetti',
          quantite: 2,
          prixUnitaire: 1000,
        ),
      ],
      heureSouhaitee: DateTime(2026, 11, 7, 12),
      filiere: 'Info',
      batiment: Batiment.nouveau,
      moyenPaiement: MoyenPaiement.tmoney,
      promo: const CodePromo(
        code: 'BIENVENUE',
        type: TypeRemise.pourcentage,
        valeur: 10,
      ),
    );
    final c = (await repo.lire(id))!;
    expect(c.sousTotal, 2000);
    expect(c.remise, 200);
    expect(c.total, 1800);
    expect(c.codePromo, 'BIENVENUE');
    final brut = (await db.collection('commandes').doc(id).get()).data()!;
    expect(brut['total'], 1800);
    expect(brut['sousTotal'], 2000);
  });

  testWidgets('le client applique un code promo dans son panier', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await PromoRepository(db).enregistrer(
      const CodePromo(
        code: 'BIENVENUE',
        type: TypeRemise.pourcentage,
        valeur: 10,
      ),
    );
    final panier = Panier()
      ..ajouter(spaghetti)
      ..ajouter(spaghetti);
    await tester.pumpWidget(monter(const PanierScreen(), db, panier: panier));
    await tester.pumpAndSettle();
    expect(find.text('Commander · ${formatFcfa(2000)}'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'faux');
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    expect(find.text('Ce code promo n\'existe pas.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bienvenue');
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    expect(find.text('BIENVENUE · -10 %'), findsOneWidget);
    expect(find.text('- ${formatFcfa(200)}'), findsOneWidget);
    expect(find.text('Commander · ${formatFcfa(1800)}'), findsOneWidget);

    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();
    expect(find.text('Commander · ${formatFcfa(2000)}'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
  });
}
