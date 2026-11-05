# Food YOKFA

Application mobile de commande de repas : le client choisit ses plats, paie par
T-Money ou Flooz, reçoit un QR code, et le livreur scanne ce code pour confirmer
la livraison. Le gérant est notifié à chaque commande.

Le détail des fonctionnalités est dans le
[cahier des charges](https://claude.ai/artifact/QaRMKPNcdCnKvsV2uZkRf7) et dans
les [issues](https://github.com/romanus16/food-yokfa/issues).

## Technologies

- **Flutter** (Dart) : une seule base de code pour Android (prioritaire) et iOS.
- **Firebase** : base de données Firestore, authentification, notifications
  push (Firebase Cloud Messaging).

## Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) 3.47 ou plus récent
  (`flutter doctor` doit être au vert pour Android).
- Un compte Google pour créer le projet Firebase.
- [Firebase CLI](https://firebase.google.com/docs/cli) et
  [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) :

  ```bash
  npm install -g firebase-tools
  dart pub global activate flutterfire_cli
  ```

## Démarrer

```bash
flutter pub get
flutter run
```

Sans configuration Firebase, l'application démarre quand même et affiche
« Firebase non configuré » sur l'écran d'accueil.

## Configurer Firebase (une seule fois)

1. Créez un projet sur la [console Firebase](https://console.firebase.google.com/).
2. Dans le projet, activez **Firestore Database** et **Authentication**, avec
   les fournisseurs **Anonyme** (clients, sans inscription) et
   **Adresse e-mail/Mot de passe** (gérants).
3. À la racine du dépôt :

   ```bash
   firebase login
   flutterfire configure --platforms=android,ios
   ```

   Cette commande remplace `lib/firebase_options.dart` et ajoute
   `android/app/google-services.json` (et `ios/Runner/GoogleService-Info.plist`).
4. Déployez les règles de sécurité Firestore :

   ```bash
   firebase use --add        # choisir le projet créé à l'étape 1
   firebase deploy --only firestore
   ```

5. Relancez l'application : l'accueil doit afficher « Connecté à Firebase ».

## Notifications au gérant (Cloud Functions)

Deux fonctions dans `functions/` envoient une notification push à tous les
téléphones des gérants :

- **Nouvelle commande** : « 3 × Spaghetti, ancien bâtiment, pour 12 h 30 » ;
- **Paiement à vérifier** : quand le client saisit sa référence de paiement.

Le téléphone d'un gérant s'enregistre automatiquement en ouvrant l'espace
gérant (jeton stocké dans `gerants/{uid}.tokens`) et se retire à la
déconnexion. Toucher la notification ouvre le détail de la commande.

Mise en service :

1. Les Cloud Functions demandent le forfait **Blaze** (paiement à l'usage ;
   le quota gratuit couvre largement un petit volume de commandes).
2. Déployez :

   ```bash
   cd functions && npm install && cd ..
   firebase deploy --only functions
   ```

3. Sur iPhone, il faut en plus une clé APNs dans la console Firebase
   (Paramètres du projet → Cloud Messaging).

## Données (Firestore)

| Collection | Contenu |
| --- | --- |
| `categories` | nom, icône (emoji), ordre, visible |
| `produits` | nom, categorieId, prix (FCFA entier), photoUrl, disponible, visible, ordre |
| `commandes` | clientId, lignes (produit, nom, quantité, prix unitaire), total, heureSouhaitee, filiere, batiment (`nouveau` / `ancien`), moyenPaiement (`tmoney` / `flooz`), referencePaiement, statut, codeQr, creeLe, payeeLe, livreeLe |
| `config/paiement` | numeroTmoney, numeroFlooz (comptes marchands) |
| `gerants/{uid}` | un document par gérant (son contenu n'importe pas) |

Statuts d'une commande : `en_attente_paiement` → `payee` → `livree`
(ou `annulee`).

### Donner le rôle de gérant à quelqu'un

1. La personne crée son compte gérant dans l'appli (e-mail et mot de passe).
2. Dans la console Firebase, **Authentication** : copiez son UID.
3. Dans **Firestore** : créez le document `gerants/<UID>` (un champ
   quelconque, par exemple `nom: "Romaric"`).

## Organisation du code

```
lib/
  main.dart                 démarrage + initialisation Firebase
  app.dart                  MaterialApp, langue française, thème
  firebase_options.dart     généré par `flutterfire configure`
  core/
    firebase_bootstrap.dart initialisation Firebase sans planter l'appli
    format.dart             formatage des montants en FCFA (1 000 F)
    theme.dart              couleurs
  data/
    models/                 Categorie, Produit, Commande, ConfigPaiement
    repositories/           accès Firestore (menu, commandes, config)
    menu_demo.dart          menu d'exemple à charger au démarrage
  features/
    home/                   écran d'accueil (catégories : issue #3)
functions/                  Cloud Functions (notifications), TypeScript
firestore.rules             règles de sécurité Firestore
```

Conventions :

- Interface en français.
- Montants stockés en **entiers FCFA** (pas de décimales), affichés avec
  `formatFcfa`.
- Une fonctionnalité = un dossier dans `lib/features/`.

## Vérifications

```bash
flutter analyze
flutter test
cd functions && npm test
```

Ces deux commandes tournent aussi automatiquement sur chaque pull request
(GitHub Actions, `.github/workflows/ci.yml`).
