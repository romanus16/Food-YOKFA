import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/auth_gerant.dart';
import 'core/firebase_bootstrap.dart';
import 'core/identite.dart';
import 'core/notifications_gerant.dart';
import 'core/theme.dart';
import 'data/repositories/commande_repository.dart';
import 'data/repositories/config_repository.dart';
import 'data/repositories/livreur_repository.dart';
import 'data/repositories/menu_repository.dart';
import 'data/repositories/promo_repository.dart';
import 'features/home/firebase_absent_screen.dart';
import 'features/gerant/detail_commande_screen.dart';
import 'features/home/accueil_shell.dart';
import 'features/home/intro_animee.dart';
import 'features/panier/panier.dart';

class FoodYokfaApp extends StatelessWidget {
  const FoodYokfaApp({
    super.key,
    required this.firebase,
    this.db,
    this.identite,
    this.authGerant,
    this.notifications,
    this.intro = false,
  });

  final FirebaseStatus firebase;

  /// Base Firestore à utiliser. Par défaut l'instance Firebase ; les tests
  /// passent une base factice.
  final FirebaseFirestore? db;

  /// Identité du client. Par défaut la connexion anonyme Firebase.
  final Identite? identite;

  /// Connexion des gérants. Par défaut Firebase Auth.
  final AuthGerant? authGerant;

  /// Notifications push du gérant. Par défaut Firebase Cloud Messaging.
  final NotificationsGerant? notifications;

  /// Joue l'intro animée du logo à l'ouverture.
  final bool intro;

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Food YOKFA',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: firebase.isDemo
          ? (context, child) => _BandeauDemo(child: child!)
          : null,
      home: firebase.isReady
          ? (intro
                ? const IntroAnimee(child: AccueilShell())
                : const AccueilShell())
          : FirebaseAbsentScreen(erreur: firebase.error),
    );
    if (!firebase.isReady) return app;

    final base = db ?? FirebaseFirestore.instance;
    return MultiProvider(
      providers: [
        Provider<FirebaseFirestore>.value(value: base),
        Provider(create: (_) => MenuRepository(base)),
        Provider(create: (_) => CommandeRepository(base)),
        Provider(create: (_) => ConfigRepository(base)),
        Provider(create: (_) => PromoRepository(base)),
        Provider(create: (_) => LivreurRepository(base)),
        ChangeNotifierProvider(create: (_) => Panier()),
        Provider<Identite>(create: (_) => identite ?? IdentiteFirebase()),
        Provider<AuthGerant>(
          create: (_) => authGerant ?? AuthGerantFirebase(base),
        ),
        Provider<NotificationsGerant>(
          create: (_) => notifications ?? NotificationsGerantFirebase(base),
        ),
      ],
      child: _OuvertureNotifications(navigatorKey: navigatorKey, child: app),
    );
  }
}

/// Bandeau en haut de l'écran : on est en mode démo.
class _BandeauDemo extends StatelessWidget {
  const _BandeauDemo({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: couleurs.tertiary,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Mode démo : données d\'exemple, rien n\'est enregistré',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: couleurs.onTertiary, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Ouvre le détail de la commande quand le gérant touche une notification.
class _OuvertureNotifications extends StatefulWidget {
  const _OuvertureNotifications({
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<_OuvertureNotifications> createState() =>
      _OuvertureNotificationsState();
}

class _OuvertureNotificationsState extends State<_OuvertureNotifications> {
  StreamSubscription<String>? _abonnement;

  @override
  void initState() {
    super.initState();
    _abonnement = context.read<NotificationsGerant>().ouvertures().listen(
      (id) => widget.navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => DetailCommandeScreen(commandeId: id),
        ),
      ),
      // Messagerie indisponible (tests, appareil sans services Google) :
      // l'appli fonctionne sans notifications.
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    _abonnement?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
