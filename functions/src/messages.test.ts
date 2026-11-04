import { test } from "node:test";
import assert from "node:assert/strict";

import {
  fcfa,
  heure,
  nouvelleCommande,
  paiementAVerifier,
  referenceVientDEtreSaisie,
} from "./messages";

test("formate les montants en FCFA", () => {
  assert.equal(fcfa(1000), "1 000 F");
  assert.equal(fcfa(300), "300 F");
  assert.equal(fcfa(1250000), "1 250 000 F");
});

test("heure du Togo (UTC+0)", () => {
  assert.equal(heure(new Date("2026-11-05T12:30:00Z")), "12 h 30");
});

test("texte d'une nouvelle commande", () => {
  const m = nouvelleCommande({
    lignes: [{ nom: "Spaghetti", quantite: 3 }],
    batiment: "ancien",
    heureSouhaitee: new Date("2026-11-05T12:30:00Z"),
  });
  assert.equal(m.titre, "Nouvelle commande");
  assert.equal(m.corps, "3 × Spaghetti, ancien bâtiment, pour 12 h 30");
});

test("nouvelle commande en espèces", () => {
  const m = nouvelleCommande({
    lignes: [{ nom: "Spaghetti", quantite: 2 }],
    batiment: "nouveau",
    moyenPaiement: "especes",
    total: 2000,
  });
  assert.equal(
    m.corps,
    `2 × Spaghetti, nouveau bâtiment, espèces ${fcfa(2000)} à encaisser`,
  );
});

test("texte d'un paiement à vérifier", () => {
  const m = paiementAVerifier({
    lignes: [{ nom: "Eau", quantite: 2 }],
    total: 600,
    referencePaiement: "TX42",
  });
  assert.equal(m.corps, "600 F · référence TX42 · 2 × Eau");
});

test("détecte la saisie de la référence, une seule fois", () => {
  assert.equal(referenceVientDEtreSaisie({}, { referencePaiement: "A" }), true);
  assert.equal(
    referenceVientDEtreSaisie(
      { referencePaiement: "A" },
      { referencePaiement: "A", statut: "payee" },
    ),
    false,
  );
  assert.equal(referenceVientDEtreSaisie({}, {}), false);
});
