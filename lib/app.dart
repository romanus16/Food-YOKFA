import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/firebase_bootstrap.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';

class FoodYokfaApp extends StatelessWidget {
  const FoodYokfaApp({super.key, required this.firebase});

  final FirebaseStatus firebase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: HomeScreen(firebase: firebase),
    );
  }
}
