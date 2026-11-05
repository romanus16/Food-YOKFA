import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/commande.dart';

/// Réglages communs des cartes (OpenStreetMap, sans clé Google).
abstract final class Carte {
  /// `false` dans les tests : pas de téléchargement de tuiles.
  static bool tuilesReseau = true;

  /// Centre par défaut quand la position du téléphone est inconnue (Lomé).
  static const centreParDefaut = LatLng(6.1725, 1.2314);

  static Widget tuiles() => tuilesReseau
      ? TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.yokfa.food_yokfa',
        )
      : const ColoredBox(color: Color(0xFFE8F0E3));

  /// Crédit obligatoire des données OpenStreetMap.
  static Widget credit() => const Align(
    alignment: Alignment.bottomRight,
    child: ColoredBox(
      color: Color(0xCCFFFFFF),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          '© OpenStreetMap',
          style: TextStyle(fontSize: 10, color: Colors.black87),
        ),
      ),
    ),
  );
}

/// Position actuelle du téléphone, ou `null` si refusée ou indisponible.
typedef Localiser = Future<LatLng?> Function();

Future<LatLng?> positionDuTelephone() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(p.latitude, p.longitude);
  } catch (_) {
    return null;
  }
}

/// Le lieu de livraison, vu par le livreur : petite carte avec le repère,
/// point de repère en texte et bouton « Itinéraire ».
class CarteLieu extends StatelessWidget {
  const CarteLieu({super.key, required this.lieu});

  final LieuLivraison lieu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itineraire = lieu.itineraire;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lieu.aPosition)
            SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lieu.latitude!, lieu.longitude!),
                  initialZoom: 17,
                ),
                children: [
                  Carte.tuiles(),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lieu.latitude!, lieu.longitude!),
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: Icon(
                          Icons.location_on,
                          size: 40,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  Carte.credit(),
                ],
              ),
            ),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(
              lieu.repere.isEmpty ? 'Point choisi sur la carte' : lieu.repere,
            ),
            subtitle: lieu.aPosition && lieu.repere.isNotEmpty
                ? const Text('Point choisi sur la carte')
                : null,
          ),
          if (itineraire != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    launchUrl(itineraire, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.directions),
                label: const Text('Itinéraire'),
              ),
            ),
        ],
      ),
    );
  }
}
