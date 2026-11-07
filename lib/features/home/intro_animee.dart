import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Un morceau du logo : d'où il arrive et de combien il tourne en arrivant.
class _Morceau {
  const _Morceau(this.nom, this.depart, this.rotation);

  final String nom;

  /// Point de départ, en tailles de logo par rapport à sa place finale.
  final Offset depart;

  /// Rotation de départ, en radians.
  final double rotation;

  String get image => 'assets/logo/morceaux/$nom.png';
}

/// Ordre d'arrivée : d'abord le cadre (vagues), puis les lettres, puis les
/// ustensiles et la vapeur qui s'échappe de la cloche.
const _morceaux = [
  _Morceau('vague', Offset(0, 1.5), 1.2),
  _Morceau('arc', Offset(0, -1.6), -1.0),
  _Morceau('y', Offset(-1.7, 0.1), -0.9),
  _Morceau('f', Offset(1.7, 0.1), 0.9),
  _Morceau('toque', Offset(-1.3, -1.4), -1.5),
  _Morceau('cloche', Offset(1.3, -1.3), 1.5),
  _Morceau('fourchette', Offset(-1.6, 1.2), -1.8),
  _Morceau('cuillere', Offset(1.6, 1.2), 1.8),
  _Morceau('vapeur', Offset(0.5, -1.8), 2.2),
];

/// Durée totale de l'intro (le client voulait environ 5 secondes).
const dureeIntro = Duration(milliseconds: 4600);

/// Intro à l'ouverture de l'appli : les morceaux du logo YF arrivent de
/// partout et se rassemblent, le logo fait un tour sur lui-même, un reflet
/// le traverse, puis l'appli apparaît. Toucher l'écran passe l'intro.
class IntroAnimee extends StatefulWidget {
  const IntroAnimee({super.key, required this.child});

  /// L'appli, déjà construite sous l'intro (le menu se charge pendant ce
  /// temps).
  final Widget child;

  @override
  State<IntroAnimee> createState() => _IntroAnimeeState();
}

class _IntroAnimeeState extends State<IntroAnimee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: dureeIntro,
  )..addStatusListener(_statut);
  bool _fini = false;
  bool _prepare = false;

  void _statut(AnimationStatus s) {
    if (s == AnimationStatus.completed && mounted) {
      setState(() => _fini = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prepare) return;
    _prepare = true;
    // Animations réduites (réglage d'accessibilité) : pas d'intro.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _fini = true;
      return;
    }
    for (final m in _morceaux) {
      precacheImage(AssetImage(m.image), context);
    }
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Saute directement à la sortie de l'intro.
  void _passer() {
    if (_c.value < _debutSortie) {
      _c.value = _debutSortie;
      _c.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_fini)
          Positioned.fill(
            child: Semantics(
              label: 'Food YOKFA',
              button: true,
              hint: 'Touchez pour passer l\'intro',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _passer,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => _Scene(t: _c.value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

const double _debutSortie = 0.86;

/// Progression de [t] entre [a] et [b], de 0 à 1, avec une courbe.
double _entre(double t, double a, double b, [Curve courbe = Curves.linear]) =>
    courbe.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

class _Scene extends StatelessWidget {
  const _Scene({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final ecran = MediaQuery.sizeOf(context);
    final taille = math.min(340.0, math.min(ecran.width, ecran.height) * 0.68);
    final sortie = _entre(t, _debutSortie, 1, Curves.easeInCubic);
    final halo = _entre(t, 0.25, 0.55);
    final pouls = 0.5 + 0.5 * math.sin(t * math.pi * 5);
    final texte = _entre(t, 0.6, 0.78, Curves.easeOutCubic);

    return Opacity(
      opacity: 1 - sortie,
      child: Material(
        color: YokfaCouleurs.noir,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Halo orange qui respire derrière le logo.
            Center(
              child: Opacity(
                opacity: (halo * (0.55 + 0.3 * pouls)).clamp(0.0, 1.0),
                child: Container(
                  width: taille * 1.7,
                  height: taille * 1.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        YokfaCouleurs.orange.withValues(alpha: 0.42),
                        YokfaCouleurs.dore.withValues(alpha: 0.10),
                        YokfaCouleurs.noir.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 1 + 0.35 * sortie,
                    child: _Logo(t: t, taille: taille),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: texte,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - texte)),
                      child: const _Titre(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le logo qui se forme, tourne puis brille.
class _Logo extends StatelessWidget {
  const _Logo({required this.t, required this.taille});

  final double t;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final morceaux = <Widget>[
      for (var i = 0; i < _morceaux.length; i++) _morceau(i),
    ];
    Widget logo = SizedBox(
      width: taille,
      height: taille,
      child: Stack(children: morceaux),
    );

    // Reflet doré qui traverse le logo une fois formé.
    final reflet = _entre(t, 0.62, 0.8, Curves.easeInOut);
    if (reflet > 0 && reflet < 1) {
      final x = -0.4 + 1.8 * reflet;
      logo = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0),
            const Color(0xFFFFF4D6).withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0),
          ],
          stops: [
            (x - 0.18).clamp(0.0, 1.0),
            x.clamp(0.0, 1.0),
            (x + 0.18).clamp(0.0, 1.0),
          ],
        ).createShader(rect),
        child: logo,
      );
    }

    // Un tour complet sur lui-même, comme une pièce qu'on fait tourner.
    final tour = _entre(t, 0.42, 0.62, Curves.easeInOutCubic);
    final rebond = math.sin(tour * math.pi) * 0.08;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(tour * 2 * math.pi)
        ..scaleByDouble(1 + rebond, 1 + rebond, 1, 1),
      child: logo,
    );
  }

  Widget _morceau(int i) {
    final m = _morceaux[i];
    final debut = 0.02 + i * 0.035;
    final fin = debut + 0.24;
    final p = _entre(t, debut, fin, Curves.easeOutBack);
    final opacite = _entre(t, debut, debut + 0.08);
    final reste = 1 - p;
    return Positioned.fill(
      child: Opacity(
        opacity: opacite,
        child: Transform.translate(
          offset: m.depart * taille * reste,
          child: Transform.rotate(
            angle: m.rotation * reste,
            child: Transform.scale(
              scale: 0.35 + 0.65 * p,
              child: Image.asset(
                m.image,
                width: taille,
                height: taille,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'BON APPÉTIT',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
