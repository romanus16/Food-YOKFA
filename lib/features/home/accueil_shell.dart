import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../commande/mes_commandes_screen.dart';
import '../panier/panier.dart';
import '../panier/panier_screen.dart';
import 'home_screen.dart';
import 'plus_screen.dart';

/// Écran principal du client, avec la barre du bas :
/// Accueil (le menu), Panier, Commandes (suivi et QR codes), Plus.
class AccueilShell extends StatefulWidget {
  const AccueilShell({super.key});

  @override
  State<AccueilShell> createState() => _AccueilShellState();
}

class _AccueilShellState extends State<AccueilShell> {
  int _onglet = 0;

  void _aller(int i) => setState(() => _onglet = i);

  @override
  Widget build(BuildContext context) {
    final n = context.select<Panier, int>((p) => p.nombreArticles);
    return Scaffold(
      body: IndexedStack(
        index: _onglet,
        children: [
          HomeScreen(ouvrirPanier: () => _aller(1)),
          const PanierScreen(),
          const MesCommandesScreen(),
          const PlusScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: _aller,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: n > 0,
              label: Text('$n'),
              child: const Icon(Icons.shopping_basket_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: n > 0,
              label: Text('$n'),
              child: const Icon(Icons.shopping_basket_rounded),
            ),
            label: 'Panier',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Commandes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'Plus',
          ),
        ],
      ),
    );
  }
}
