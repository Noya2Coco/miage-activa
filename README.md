# Activa

Activa est une application Flutter réalisée pour un mini-projet de Master 2 MIAGE IA2. Cette étape couvre uniquement l'US#1 : connexion par email et mot de passe avec Firebase Authentication, suivie d'une page « Activités » minimale.

Les conventions du dépôt sont dans [CONTRIBUTING.md](CONTRIBUTING.md).

## Prérequis

- Flutter et Dart compatibles avec le SDK indiqué dans `pubspec.yaml` (Flutter 3.44.6 et Dart 3.12.2 utilisés pendant le développement).
- Un accès au projet Firebase associé à Activa, avec le fournisseur **Email/Password** activé dans Authentication.
- Chrome pour le lancement web. Pour Android, le SDK Android, les licences acceptées et un émulateur ou appareil détecté par `flutter devices` sont également nécessaires.

## Configuration Firebase

Le dépôt utilise la configuration générée par FlutterFire pour Android et Web : `lib/firebase_options.dart`, `firebase.json` et `android/app/google-services.json`. Le fichier d'options est utilisé dans `lib/main.dart` pour initialiser Firebase avec la configuration correspondant à la plateforme. Ces fichiers contiennent des identifiants de projet, pas de mots de passe utilisateur.

Pour configurer une nouvelle copie du dépôt ou actualiser ses applications Firebase :

```sh
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=activa-tp --platforms=android,web --android-package-name=com.example.activa
flutter pub get
```

Dans la console du même projet Firebase, activer **Authentication > Sign-in method > Email/Password** et créer les comptes de démonstration dans **Authentication > Users**. Le champ **Login** de l'application correspond à l'adresse email Firebase. L'application ne crée pas de comptes et n'utilise pas encore Firestore.

La [documentation Firebase pour Flutter](https://firebase.google.com/docs/flutter/setup?hl=fr) détaille FlutterFire et la [documentation sur Email/Password](https://firebase.google.com/docs/auth/flutter/password-auth) décrit le fournisseur d'authentification.

## Lancement

Dans le dossier du projet :

```sh
flutter pub get
flutter run -d chrome
```

Pour Android, vérifier d'abord `flutter doctor` et `flutter devices`, puis lancer `flutter run -d <identifiant-appareil>`.

## Fonctionnalités implémentées

- Formulaire de connexion « Login » et « Password », avec mot de passe masqué.
- Vérification des identifiants par Firebase Authentication, état de chargement et messages d'erreur.
- Navigation vers une page « Activités » minimale après une connexion confirmée.

La liste des activités, le panier, le profil et les autres User Stories ne sont pas implémentés. L'identifiant Firebase (`uid`) pourra servir à associer un profil Firestore dans une étape ultérieure.

## Vérifications

```sh
dart format lib test
flutter analyze
flutter test
```

Sur la machine de développement utilisée ici, `flutter analyze` échoue depuis le chemin du dépôt contenant des caractères accentués avec une erreur interne de lecture JSON. L'analyse réussit depuis une jonction temporaire dont le chemin est ASCII ; `dart analyze` réussit aussi depuis le dépôt.

## Comptes de démonstration

Deux comptes dédiés à la démonstration ont été créés dans Firebase Authentication. Le mot de passe commun est réservé à ce TP ; ne l'utilisez pour aucun autre compte.

| Compte | Login | Mot de passe |
|---|---|---|
| Démonstration 1 | demo1@gmail.com | password |
| Démonstration 2 | demo2@gmail.com | password |
