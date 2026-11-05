// Construction du texte des notifications, sans dépendance à Firebase
// (pour pouvoir le tester facilement).

export interface Ligne {
  nom?: string;
  quantite?: number;
}

export interface CommandeDoc {
  lignes?: Ligne[];
  total?: number;
  batiment?: string;
  heureSouhaitee?: Date;
  referencePaiement?: string | null;
  moyenPaiement?: string;
  statut?: string;
}

const BATIMENTS: Record<string, string> = {
  nouveau: "nouveau bâtiment",
  ancien: "ancien bâtiment",
};

/** 1000 → « 1 000 F » */
export function fcfa(montant: number): string {
  return `${Math.round(montant)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, " ")} F`;
}

/** Heure au Togo (UTC+0, fuseau Africa/Lome) : « 12 h 30 ». */
export function heure(d: Date): string {
  const parts = new Intl.DateTimeFormat("fr-FR", {
    timeZone: "Africa/Lome",
    hour: "2-digit",
    minute: "2-digit",
  }).formatToParts(d);
  const h = parts.find((p) => p.type === "hour")?.value ?? "";
  const m = parts.find((p) => p.type === "minute")?.value ?? "";
  return `${h} h ${m}`;
}

export function resume(c: CommandeDoc): string {
  return (c.lignes ?? [])
    .map((l) => `${l.quantite ?? 0} × ${l.nom ?? "?"}`)
    .join(", ");
}

export function nouvelleCommande(c: CommandeDoc): {
  titre: string;
  corps: string;
} {
  const morceaux = [resume(c)];
  if (c.batiment) morceaux.push(BATIMENTS[c.batiment] ?? c.batiment);
  if (c.heureSouhaitee) morceaux.push(`pour ${heure(c.heureSouhaitee)}`);
  if (c.moyenPaiement === "especes") {
    morceaux.push(`espèces ${fcfa(c.total ?? 0)} à encaisser`);
  }
  return {
    titre: "Nouvelle commande",
    corps: morceaux.join(", "),
  };
}

export function paiementAVerifier(c: CommandeDoc): {
  titre: string;
  corps: string;
} {
  return {
    titre: "Paiement à vérifier",
    corps: `${fcfa(c.total ?? 0)} · référence ${c.referencePaiement} · ${resume(c)}`,
  };
}

/** `true` quand le client vient de saisir sa référence de paiement. */
export function referenceVientDEtreSaisie(
  avant: CommandeDoc,
  apres: CommandeDoc,
): boolean {
  return !avant.referencePaiement && !!apres.referencePaiement;
}
