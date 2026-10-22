# Activa

Activa est une application Flutter réalisée pour un mini-projet de Master 2 MIAGE IA2. Les US#1 à US#4 couvrent la connexion par Firebase Authentication, la consultation des activités et la gestion du panier dans Cloud Firestore.

Les conventions du dépôt sont dans [CONTRIBUTING.md](CONTRIBUTING.md).

## Prérequis

- Flutter et Dart compatibles avec le SDK indiqué dans `pubspec.yaml` (Flutter 3.44.6 et Dart 3.12.2 utilisés pendant le développement).
- Un accès au projet Firebase `activa-tp`, avec le fournisseur **Email/Password** activé dans Authentication et une base Cloud Firestore créée.
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

Dans la console du même projet Firebase, activer **Authentication > Sign-in method > Email/Password** et créer les comptes de démonstration dans **Authentication > Users**. Le champ **Login** de l'application correspond à l'adresse email Firebase. L'application ne crée pas de comptes.

La base Firestore `(default)` du projet `activa-tp` a été créée dans la région `europe-west9` (Paris). Pour appliquer les règles présentes dans le dépôt :

```sh
firebase deploy --only firestore:rules --project activa-tp
```

La collection `activities` est lisible uniquement par les utilisateurs connectés. L'application cliente ne peut pas y écrire ; ajoutez ou modifiez les activités depuis la console Firebase avec un compte administrateur. Chaque document doit contenir `title` (texte), `category` (texte), `location` (texte), `maxParticipants` (entier positif), `price` (nombre positif ou nul) et `imageUrl` (URL d'image). Le champ booléen `demo` est facultatif ; lorsqu'il vaut `true`, l'interface indique qu'il s'agit d'une démonstration.

Le bouton « Ajouter au panier » crée un document `users/{uid}/cart/{activityId}` contenant `activityId` et `addedAt`. Les règles autorisent chaque utilisateur à lire son propre panier, à y ajouter une activité existante une seule fois et à retirer ses propres entrées. Les autres utilisateurs n'ont pas accès à ces documents.

Trois documents de démonstration ont été ajoutés à Firestore. Leur contenu est conservé dans [data/demo_activities.json](data/demo_activities.json) pour référence. Les images sont servies par [Unsplash](https://unsplash.com/license) et nécessitent une connexion réseau.

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
- Navigation vers la liste des activités après une connexion confirmée.
- Lecture de toutes les activités depuis Firestore, avec image, titre, lieu et prix ; états de chargement, liste vide et erreur.
- Barre de navigation « Activités », « Panier » et « Profil » avec l'entrée courante mise en évidence.
- Détail de l'activité avec image, titre, catégorie, lieu, capacité maximale et prix.
- Bouton « Retour » et ajout de l'activité au panier de l'utilisateur connecté, avec confirmation et gestion des doublons et des erreurs.
- Page « Panier » affichant les activités de l'utilisateur connecté (image, titre, lieu, prix), le total général et une croix de retrait par activité. Le total se recalcule après un retrait.

La page « Profil » affiche encore un message d'attente. Aucun paiement n'est proposé à ce stade.

## Vérifications

```sh
dart format lib test
flutter analyze
flutter test
flutter build web
```

Sur la machine de développement utilisée ici, `flutter analyze` échoue depuis le chemin du dépôt contenant des caractères accentués avec une erreur interne de lecture JSON. L'analyse réussit depuis une jonction temporaire dont le chemin est ASCII ; `dart analyze` réussit aussi depuis le dépôt.

## Comptes de démonstration

Deux comptes dédiés à la démonstration ont été créés dans Firebase Authentication. Le mot de passe commun est réservé à ce TP ; ne l'utilisez pour aucun autre compte.

| Compte | Login | Mot de passe |
|---|---|---|
| Démonstration 1 | demo1@gmail.com | password |
| Démonstration 2 | demo2@gmail.com | password |
