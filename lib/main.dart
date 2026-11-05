import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
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
    const webSiteKey = String.fromEnvironment('APP_CHECK_WEB_SITE_KEY');
    if (!kIsWeb || kDebugMode || webSiteKey.isNotEmpty) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerWeb: kDebugMode
              ? WebDebugProvider()
              : ReCaptchaV3Provider(webSiteKey),
        );
      } catch (error) {
        debugPrint('Firebase App Check indisponible : $error');
      }
    }
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
