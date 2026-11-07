import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/photo.dart';
import '../../core/theme.dart';
import '../../data/models/categorie.dart';
import '../../data/repositories/menu_repository.dart';
import '../menu/produits_screen.dart';
import '../panier/barre_commander.dart';

/// Accueil : grande photo d'ambiance, puis les catégories du menu en cartes
/// photo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.ouvrirPanier});

  /// Ouvre l'onglet Panier de la barre du bas (sinon, la page Panier).
  final VoidCallback? ouvrirPanier;

  @override
  Widget build(BuildContext context) {
    final menu = context.read<MenuRepository>();
    return Scaffold(
      bottomNavigationBar: BarreCommander(onPressed: ouvrirPanier),
      body: StreamBuilder<List<Categorie>>(
        stream: menu.categories(),
        builder: (context, snap) {
          final Widget contenu;
          if (snap.hasError) {
            contenu = const _Message(
              icone: Icons.wifi_off,
              texte: 'Impossible de charger le menu. Vérifiez votre connexion.',
            );
          } else if (!snap.hasData) {
            contenu = const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snap.data!.isEmpty) {
            contenu = const _Message(
              icone: Icons.restaurant_menu,
              texte: 'Le menu n\'est pas encore disponible.',
            );
          } else {
            contenu = _Categories(categories: snap.data!);
          }
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _Entete()),
              SliverToBoxAdapter(child: contenu),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

/// Photo d'ambiance avec le nom de l'appli.
class _Entete extends StatelessWidget {
  const _Entete();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final haut = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 290 + haut,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const PhotoPlat(url: Photos.accueil),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xB30B0B0B),
                        Color(0x330B0B0B),
                        Color(0xF20B0B0B),
                      ],
                      stops: [0, 0.4, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, haut + 12, 8, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Logo(),
                const Spacer(),
                Text(
                  'Bon appétit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: YokfaCouleurs.dore,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Des plats chauds,\nlivrés jusqu\'à votre bâtiment',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pastille(icone: Icons.bolt_rounded, texte: 'Rapide'),
                    _Pastille(
                      icone: Icons.phone_android_rounded,
                      texte: 'T-Money · Flooz · espèces',
                    ),
                    _Pastille(icone: Icons.qr_code_2_rounded, texte: 'QR code'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: YokfaCouleurs.dore.withValues(alpha: 0.6),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(yokfaLogo, width: 46, height: 46),
          ),
        ),
        const SizedBox(width: 10),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Food ',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'YOKFA',
                style: TextStyle(color: YokfaCouleurs.dore),
              ),
            ],
          ),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: YokfaCouleurs.noir.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YokfaCouleurs.dore.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: YokfaCouleurs.dore),
          const SizedBox(width: 5),
          Text(
            texte,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.categories});

  final List<Categorie> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Que voulez-vous commander ?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                'Choisissez une catégorie',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: YokfaCouleurs.gris,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final c in categories) _CategorieTuile(categorie: c),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorieTuile extends StatelessWidget {
  const _CategorieTuile({required this.categorie});

  final Categorie categorie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(yokfaRayon),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(yokfaRayon),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProduitsScreen(categorie: categorie),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PhotoPlat(
                  url: Photos.categorie(categorie),
                  emoji: categorie.icone,
                  tailleEmoji: 56,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xD9000000)],
                      stops: [0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categorie.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Voir les plats',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: YokfaCouleurs.dore,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: YokfaCouleurs.dore,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: YokfaCouleurs.sable,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 36, color: YokfaCouleurs.orange),
          ),
          const SizedBox(height: 14),
          Text(texte, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
