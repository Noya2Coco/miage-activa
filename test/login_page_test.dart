import 'dart:async';

import 'package:activa/app.dart';
import 'package:activa/auth/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthenticationService implements AuthenticationService {
  FakeAuthenticationService(this.result);

  final Future<void> Function(String email, String password) result;
  int calls = 0;

  @override
  Future<void> signIn({required String email, required String password}) {
    calls++;
    return result(email, password);
  }
}

void main() {
  testWidgets('affiche le formulaire et refuse les champs vides', (
    tester,
  ) async {
    final authentication = FakeAuthenticationService((_, _) async {});
    await tester.pumpWidget(ActivaApp(authentication: authentication));

    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('password-field')))
          .obscureText,
      isTrue,
    );

    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(
      find.text('Renseignez le login et le mot de passe.'),
      findsOneWidget,
    );
    expect(authentication.calls, 0);
  });

  testWidgets('affiche une erreur sans naviguer si les identifiants échouent', (
    tester,
  ) async {
    final authentication = FakeAuthenticationService(
      (_, _) async => throw const AuthenticationException(
        'Login ou mot de passe incorrect.',
      ),
    );
    await tester.pumpWidget(ActivaApp(authentication: authentication));
    await tester.enterText(
      find.byKey(const Key('login-field')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'incorrect',
    );
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Login ou mot de passe incorrect.'), findsOneWidget);
    expect(find.text('Activités'), findsNothing);
    expect(authentication.calls, 1);
  });

  testWidgets('montre le chargement et évite les requêtes multiples', (
    tester,
  ) async {
    final pending = Completer<void>();
    final authentication = FakeAuthenticationService((_, _) => pending.future);
    await tester.pumpWidget(ActivaApp(authentication: authentication));
    await tester.enterText(
      find.byKey(const Key('login-field')),
      ' test@example.com ',
    );
    await tester.enterText(find.byKey(const Key('password-field')), 'secret');
    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(authentication.calls, 1);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Activités'), findsOneWidget);
  });

  testWidgets('gère une erreur inattendue sans bloquer le formulaire', (
    tester,
  ) async {
    final authentication = FakeAuthenticationService(
      (_, _) async => throw StateError('réseau indisponible'),
    );
    await tester.pumpWidget(ActivaApp(authentication: authentication));
    await tester.enterText(
      find.byKey(const Key('login-field')),
      'test@example.com',
    );
    await tester.enterText(find.byKey(const Key('password-field')), 'secret');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Vérifiez votre réseau'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('explique l’absence de configuration Firebase', (tester) async {
    await tester.pumpWidget(
      const ActivaApp(configurationError: 'Firebase n’est pas configuré.'),
    );

    expect(find.text('Firebase n’est pas configuré.'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('reste utilisable sur un petit écran de téléphone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ActivaApp(authentication: FakeAuthenticationService((_, _) async {})),
    );

    expect(find.text('Se connecter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
