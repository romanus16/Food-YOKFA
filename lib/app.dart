import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/firebase_bootstrap.dart';
import 'core/theme.dart';
import 'data/repositories/commande_repository.dart';
import 'data/repositories/config_repository.dart';
import 'data/repositories/menu_repository.dart';
import 'features/home/firebase_absent_screen.dart';
import 'features/home/home_screen.dart';
import 'features/panier/panier.dart';

class FoodYokfaApp extends StatelessWidget {
  const FoodYokfaApp({super.key, required this.firebase, this.db});

  final FirebaseStatus firebase;

  /// Base Firestore à utiliser. Par défaut l'instance Firebase ; les tests
  /// passent une base factice.
  final FirebaseFirestore? db;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
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
      home: firebase.isReady
          ? const HomeScreen()
          : FirebaseAbsentScreen(erreur: firebase.error),
    );
    if (!firebase.isReady) return app;

    final base = db ?? FirebaseFirestore.instance;
    return MultiProvider(
      providers: [
        Provider(create: (_) => MenuRepository(base)),
        Provider(create: (_) => CommandeRepository(base)),
        Provider(create: (_) => ConfigRepository(base)),
        ChangeNotifierProvider(create: (_) => Panier()),
      ],
      child: app,
    );
  }
}
