import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Notification reçue pendant que l'appli est ouverte.
class NotificationRecue {
  const NotificationRecue({
    required this.titre,
    required this.corps,
    this.commandeId,
  });
  final String titre;
  final String corps;
  final String? commandeId;
}

/// Notifications push du gérant (envoyées par les Cloud Functions).
abstract class NotificationsGerant {
  /// Demande l'autorisation et enregistre ce téléphone pour le gérant [uid].
  Future<void> activer(String uid);

  /// Ce téléphone ne reçoit plus les notifications du gérant [uid].
  Future<void> desactiver(String uid);

  /// Identifiants des commandes dont le gérant a touché la notification.
  Stream<String> ouvertures();

  /// Notifications reçues appli ouverte (le système ne les affiche pas).
  Stream<NotificationRecue> premierPlan();
}

/// Utilise les jetons FCM classiques (getToken), que le SDK Admin des Cloud
/// Functions sait cibler avec sendEachForMulticast. Le nouveau mécanisme
/// register()/onRegistered (identifiants d'installation) pourra le
/// remplacer quand il sera pris en charge côté serveur.
// ignore_for_file: deprecated_member_use
class NotificationsGerantFirebase implements NotificationsGerant {
  NotificationsGerantFirebase(this._db, [FirebaseMessaging? messaging])
    : _messaging = messaging;

  final FirebaseFirestore _db;
  final FirebaseMessaging? _messaging;
  StreamSubscription<String>? _rafraichissement;

  FirebaseMessaging get messaging => _messaging ?? FirebaseMessaging.instance;

  DocumentReference<Map<String, dynamic>> _gerant(String uid) =>
      _db.collection('gerants').doc(uid);

  @override
  Future<void> activer(String uid) async {
    final reglages = await messaging.requestPermission();
    if (reglages.authorizationStatus == AuthorizationStatus.denied) return;
    final token = await messaging.getToken();
    if (token != null) {
      await _gerant(uid).update({
        'tokens': FieldValue.arrayUnion([token]),
      });
    }
    await _rafraichissement?.cancel();
    _rafraichissement = messaging.onTokenRefresh.listen((t) {
      _gerant(uid).update({
        'tokens': FieldValue.arrayUnion([t]),
      });
    });
  }

  @override
  Future<void> desactiver(String uid) async {
    await _rafraichissement?.cancel();
    _rafraichissement = null;
    final token = await messaging.getToken();
    if (token != null) {
      await _gerant(uid).update({
        'tokens': FieldValue.arrayRemove([token]),
      });
    }
    await messaging.deleteToken();
  }

  @override
  Stream<String> ouvertures() async* {
    final initial = await messaging.getInitialMessage();
    final id = initial?.data['commandeId'] as String?;
    if (id != null) yield id;
    yield* FirebaseMessaging.onMessageOpenedApp
        .map((m) => m.data['commandeId'] as String?)
        .where((id) => id != null)
        .cast<String>();
  }

  @override
  Stream<NotificationRecue> premierPlan() => FirebaseMessaging.onMessage.map(
    (m) => NotificationRecue(
      titre: m.notification?.title ?? 'Food YOKFA',
      corps: m.notification?.body ?? '',
      commandeId: m.data['commandeId'] as String?,
    ),
  );
}
