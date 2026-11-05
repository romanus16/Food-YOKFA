import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/app.dart';
import 'package:food_yokfa/core/firebase_bootstrap.dart';

void main() {
  testWidgets('affiche l\'accueil quand Firebase est connecté', (tester) async {
    await tester.pumpWidget(
      const FoodYokfaApp(firebase: FirebaseStatus.ready()),
    );
    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.text('Connecté à Firebase'), findsOneWidget);
  });

  testWidgets('signale quand Firebase n\'est pas configuré', (tester) async {
    await tester.pumpWidget(
      const FoodYokfaApp(firebase: FirebaseStatus.failed('non configuré')),
    );
    expect(find.text('Firebase non configuré (voir README)'), findsOneWidget);
  });
}
