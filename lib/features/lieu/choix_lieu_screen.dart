import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'carte.dart';

/// Le client place le repère (fixe au centre) en déplaçant la carte,
/// puis valide. Renvoie le point choisi.
class ChoixLieuScreen extends StatefulWidget {
  const ChoixLieuScreen({super.key, this.initial, this.localiser});

  /// Point déjà choisi, s'il y en a un.
  final LatLng? initial;

  /// Position du téléphone. Par défaut le GPS.
  final Localiser? localiser;

  @override
  State<ChoixLieuScreen> createState() => _ChoixLieuScreenState();
}

class _ChoixLieuScreenState extends State<ChoixLieuScreen> {
  final _carte = MapController();
  late LatLng _centre = widget.initial ?? Carte.centreParDefaut;
  bool _recherche = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial == null) _allerAMaPosition(auDemarrage: true);
  }

  @override
  void dispose() {
    _carte.dispose();
    super.dispose();
  }

  Future<void> _allerAMaPosition({bool auDemarrage = false}) async {
    setState(() => _recherche = true);
    final p = await (widget.localiser ?? positionDuTelephone)();
    if (!mounted) return;
    setState(() => _recherche = false);
    if (p == null) {
      if (!auDemarrage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Position introuvable. Activez la localisation ou déplacez '
              'la carte à la main.',
            ),
          ),
        );
      }
      return;
    }
    _centre = p;
    _carte.move(p, 17);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lieu de livraison')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _carte,
            options: MapOptions(
              initialCenter: _centre,
              initialZoom: 16,
              onPositionChanged: (camera, _) => _centre = camera.center,
            ),
            children: [Carte.tuiles(), Carte.credit()],
          ),
          // Repère fixe au centre : c'est la carte qui bouge dessous.
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Déplacez la carte pour placer le repère là où vous serez.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          if (_recherche)
            const Positioned(
              top: 72,
              left: 0,
              right: 0,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ma position',
        onPressed: _recherche ? null : _allerAMaPosition,
        child: const Icon(Icons.my_location),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context, _centre),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.check),
            label: const Text('Valider ce lieu'),
          ),
        ),
      ),
    );
  }
}
