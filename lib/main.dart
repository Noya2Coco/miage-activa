import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'auth/authentication_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthenticationService? authentication;
  String? configurationError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    authentication = FirebaseAuthenticationService();
  } on FirebaseException {
    configurationError =
        'Impossible d’initialiser Firebase. Vérifiez la configuration du projet et votre connexion.';
  } catch (_) {
    configurationError =
        'Firebase est indisponible. Vérifiez la configuration du projet.';
  }

  runApp(
    ActivaApp(
      authentication: authentication,
      configurationError: configurationError,
    ),
  );
}
