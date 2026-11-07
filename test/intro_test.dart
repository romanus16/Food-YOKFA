import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_yokfa/features/home/intro_animee.dart';

Widget _app() => const MaterialApp(
  home: IntroAnimee(child: Scaffold(body: Text('Accueil'))),
);

void main() {
  testWidgets('l\'intro forme le logo puis laisse place à l\'appli', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 3500));
    expect(find.text('BON APPÉTIT'), findsOneWidget);
    await tester.pump(dureeIntro);
    await tester.pump();
    expect(find.text('BON APPÉTIT'), findsNothing);
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets('toucher l\'écran passe l\'intro', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(200, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.text('BON APPÉTIT'), findsNothing);
  });

  testWidgets('pas d\'intro quand les animations sont réduites', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: IntroAnimee(child: Scaffold(body: Text('Accueil'))),
        ),
      ),
    );
    expect(find.text('BON APPÉTIT'), findsNothing);
  });
}
