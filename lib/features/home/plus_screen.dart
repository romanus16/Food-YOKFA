import 'package:flutter/material.dart';

import '../../core/widgets.dart';
import '../gerant/gerant_screen.dart';
import '../livreur/livreur_screen.dart';

/// Onglet « Plus » : accès aux espaces de travail et informations utiles.
class PlusScreen extends StatelessWidget {
  const PlusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void ouvrir(Widget ecran) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => ecran));
    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Espaces de travail', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          CarteOptions(
            child: Column(
              children: [
                ListTile(
                  leading: const PastilleIcone(icone: Icons.storefront_rounded),
                  title: const Text('Espace gérant'),
                  subtitle: const Text(
                    'Commandes, livreurs, menu et codes promo',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => ouvrir(const GerantScreen()),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const PastilleIcone(
                    icone: Icons.delivery_dining_rounded,
                  ),
                  title: const Text('Espace livreur'),
                  subtitle: const Text('Livraisons confiées par le gérant'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => ouvrir(const LivreurScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Comment ça marche', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const CarteOptions(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.restaurant_menu_rounded),
                  title: Text('Choisissez vos plats'),
                  subtitle: Text('Ajoutez-les au panier, avec un code promo.'),
                ),
                ListTile(
                  leading: Icon(Icons.phone_android_rounded),
                  title: Text('Payez'),
                  subtitle: Text('T-Money, Flooz ou espèces à la livraison.'),
                ),
                ListTile(
                  leading: Icon(Icons.qr_code_2_rounded),
                  title: Text('Montrez votre QR code'),
                  subtitle: Text(
                    'Le livreur le scanne en vous remettant la commande.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
