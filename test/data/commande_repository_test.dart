import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/data/models/commande.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late CommandeRepository repo;

  const lignes = [
    LigneCommande(
      produitId: 'p1',
      nom: 'Spaghetti',
      quantite: 3,
      prixUnitaire: 1000,
    ),
    LigneCommande(produitId: 'p2', nom: 'Eau', quantite: 1, prixUnitaire: 300),
  ];

  Future<String> creer() => repo.creer(
    clientId: 'client1',
    lignes: lignes,
    heureSouhaitee: DateTime(2026, 11, 5, 12, 30),
    filiere: ' Informatique ',
    batiment: Batiment.ancien,
    moyenPaiement: MoyenPaiement.flooz,
  );

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = CommandeRepository(db);
  });

  test('crée une commande en attente de paiement avec total et QR', () async {
    final id = await creer();
    final c = (await repo.lire(id))!;
    expect(c.statut, StatutCommande.enAttentePaiement);
    expect(c.total, 3300);
    expect(c.nombreArticles, 4);
    expect(c.filiere, 'Informatique');
    expect(c.batiment, Batiment.ancien);
    expect(c.moyenPaiement, MoyenPaiement.flooz);
    expect(c.codeQr.length, 24);
    final brut = (await db.collection('commandes').doc(id).get()).data()!;
    expect(brut['total'], 3300);
  });

  test('refuse une commande vide', () {
    expect(
      () => repo.creer(
        clientId: 'c',
        lignes: const [],
        heureSouhaitee: DateTime.now(),
        filiere: 'x',
        batiment: Batiment.nouveau,
        moyenPaiement: MoyenPaiement.tmoney,
      ),
      throwsA(isA<CommandeException>()),
    );
  });

  test('les codes QR sont uniques', () {
    final codes = List.generate(500, (_) => repo.genererCodeQr()).toSet();
    expect(codes.length, 500);
  });

  test('parcours complet : paiement validé puis livraison par QR', () async {
    final id = await creer();
    await repo.enregistrerReferencePaiement(id, ' TX123 ');
    var c = (await repo.lire(id))!;
    expect(c.referencePaiement, 'TX123');

    // Pas de livraison avant paiement.
    await expectLater(
      repo.confirmerLivraison(c.codeQr),
      throwsA(isA<CommandeException>()),
    );

    await repo.validerPaiement(id);
    c = (await repo.lire(id))!;
    expect(c.statut, StatutCommande.payee);
    expect(c.payeeLe, isNotNull);

    final livree = await repo.confirmerLivraison(c.codeQr);
    expect(livree.statut, StatutCommande.livree);
    c = (await repo.lire(id))!;
    expect(c.statut, StatutCommande.livree);
    expect(c.livreeLe, isNotNull);

    // Un QR déjà scanné est refusé.
    await expectLater(
      repo.confirmerLivraison(c.codeQr),
      throwsA(predicate((e) => e.toString().contains('déjà été livrée'))),
    );
  });

  test('QR inconnu refusé', () async {
    await expectLater(
      repo.confirmerLivraison('inconnu'),
      throwsA(predicate((e) => e.toString().contains('inconnu'))),
    );
  });

  test('liste du gérant filtrée par statut et triée par heure', () async {
    await repo.creer(
      clientId: 'a',
      lignes: lignes,
      heureSouhaitee: DateTime(2026, 11, 5, 19),
      filiere: 'x',
      batiment: Batiment.nouveau,
      moyenPaiement: MoyenPaiement.tmoney,
    );
    final id2 = await creer(); // 12 h 30
    final toutes = await repo.toutes().first;
    expect(toutes.map((c) => c.heureSouhaitee.hour), [12, 19]);
    await repo.validerPaiement(id2);
    final payees = await repo.toutes(statut: StatutCommande.payee).first;
    expect(payees.map((c) => c.id), [id2]);
  });
}
