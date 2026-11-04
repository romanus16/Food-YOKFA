import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { logger, setGlobalOptions } from "firebase-functions/v2";

import {
  CommandeDoc,
  nouvelleCommande,
  paiementAVerifier,
  referenceVientDEtreSaisie,
} from "./messages";

initializeApp();
// Région la plus proche du Togo proposée par Cloud Functions.
setGlobalOptions({ region: "europe-west1", maxInstances: 5 });

function lire(data: FirebaseFirestore.DocumentData | undefined): CommandeDoc {
  const d = data ?? {};
  const h = d.heureSouhaitee;
  return {
    ...d,
    heureSouhaitee: h instanceof Timestamp ? h.toDate() : undefined,
  } as CommandeDoc;
}

/**
 * Envoie une notification à tous les téléphones des gérants
 * (jetons stockés dans gerants/{uid}.tokens) et retire les jetons périmés.
 */
async function prevenirGerants(
  commandeId: string,
  message: { titre: string; corps: string },
): Promise<void> {
  const db = getFirestore();
  const gerants = await db.collection("gerants").get();
  const cibles: { uid: string; token: string }[] = [];
  gerants.forEach((g) => {
    const tokens = g.get("tokens");
    if (Array.isArray(tokens)) {
      for (const t of tokens) {
        if (typeof t === "string") cibles.push({ uid: g.id, token: t });
      }
    }
  });
  if (cibles.length === 0) {
    logger.info("Aucun téléphone gérant enregistré", { commandeId });
    return;
  }

  const res = await getMessaging().sendEachForMulticast({
    tokens: cibles.map((c) => c.token),
    notification: { title: message.titre, body: message.corps },
    data: { commandeId },
    android: { priority: "high", notification: { sound: "default" } },
    apns: { payload: { aps: { sound: "default" } } },
  });

  const perimes = res.responses
    .map((r, i) => ({ r, cible: cibles[i] }))
    .filter(
      ({ r }) =>
        !r.success &&
        (r.error?.code === "messaging/registration-token-not-registered" ||
          r.error?.code === "messaging/invalid-registration-token"),
    );
  await Promise.all(
    perimes.map(({ cible }) =>
      db
        .collection("gerants")
        .doc(cible.uid)
        .update({ tokens: FieldValue.arrayRemove(cible.token) }),
    ),
  );
  logger.info("Notification envoyée", {
    commandeId,
    succes: res.successCount,
    echecs: res.failureCount,
  });
}

/** Nouvelle commande passée par un client. */
export const notifierNouvelleCommande = onDocumentCreated(
  "commandes/{commandeId}",
  async (event) => {
    const c = lire(event.data?.data());
    await prevenirGerants(event.params.commandeId, nouvelleCommande(c));
  },
);

/** Le client a saisi sa référence : le gérant doit vérifier le paiement. */
export const notifierPaiementAVerifier = onDocumentUpdated(
  "commandes/{commandeId}",
  async (event) => {
    const avant = lire(event.data?.before.data());
    const apres = lire(event.data?.after.data());
    if (!referenceVientDEtreSaisie(avant, apres)) return;
    await prevenirGerants(event.params.commandeId, paiementAVerifier(apres));
  },
);
