# Food YOKFA

Application mobile de commande de repas : le client choisit ses plats, paie par
T-Money ou Flooz, reçoit un QR code, et le livreur scanne ce code pour confirmer
la livraison. Le gérant est notifié à chaque commande.

Le détail des fonctionnalités est dans le
[cahier des charges](https://github.com/romanus16/food-yokfa/issues) et dans
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
2. Dans le projet, activez **Firestore Database** et **Authentication**.
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
  features/
    home/                   écran d'accueil (catégories : issue #3)
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
```

Ces deux commandes tournent aussi automatiquement sur chaque pull request
(GitHub Actions, `.github/workflows/ci.yml`).
