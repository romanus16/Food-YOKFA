import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:food_yokfa/core/identite.dart';
import 'package:food_yokfa/data/repositories/commande_repository.dart';
import 'package:food_yokfa/data/repositories/config_repository.dart';
import 'package:food_yokfa/data/repositories/menu_repository.dart';
import 'package:food_yokfa/features/panier/panier.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

/// Monte un écran avec les mêmes fournisseurs que l'appli.
Widget monter(Widget ecran, FirebaseFirestore db, {Panier? panier}) {
  return MultiProvider(
    providers: [
      Provider(create: (_) => MenuRepository(db)),
      Provider(create: (_) => CommandeRepository(db)),
      Provider(create: (_) => ConfigRepository(db)),
      ChangeNotifierProvider.value(value: panier ?? Panier()),
      Provider<Identite>(create: (_) => IdentiteFactice()),
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ecran,
    ),
  );
}
