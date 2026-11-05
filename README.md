# Activa

Activa est une application Flutter réalisée pour un mini-projet de Master 2 MIAGE IA2. Les US#1 à US#5 couvrent la connexion par Firebase Authentication, la consultation des activités, la gestion du panier et le profil utilisateur dans Cloud Firestore.

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

La collection `activities` est lisible uniquement par les utilisateurs connectés. Les utilisateurs connectés peuvent créer une activité depuis leur profil ; la modification et la suppression restent interdites côté client. Chaque document doit contenir `title` (texte), `category` (texte), `location` (texte), `maxParticipants` (entier positif), `price` (nombre positif ou nul) et `imageUrl` (URL d'image). Les activités créées contiennent aussi `ownerId`, `imagePath` et `createdAt`.

Le bouton « Ajouter au panier » crée un document `users/{uid}/cart/{activityId}` contenant `activityId` et `addedAt`. Les règles autorisent chaque utilisateur à lire son propre panier, à y ajouter une activité existante une seule fois et à retirer ses propres entrées. Les autres utilisateurs n'ont pas accès à ces documents.

Le profil utilise le document `users/{uid}` pour l'anniversaire, l'adresse, le code postal et la ville. Le login provient de Firebase Authentication et reste en lecture seule. Le mot de passe existant n'est jamais renvoyé par Firebase : le champ masqué du profil permet d'en saisir un nouveau, et peut rester vide pour le conserver. Un nouveau mot de passe est enregistré dans Firebase Authentication, jamais dans Firestore. Les règles Firestore limitent la lecture et l'écriture du profil à son propriétaire.

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
- Page « Mon profil » affichant le login, un champ de nouveau mot de passe masqué, l'anniversaire, l'adresse, le code postal et la ville. Le bouton « Valider » enregistre les données et « Se déconnecter » revient à la page de connexion.

- Depuis le profil, le bouton « Ajouter une activité » ouvre le formulaire de l'US#6 : choix d'une image, titre, catégorie en lecture seule déterminée par Gemini, lieu, capacité maximale et prix. Le prix n'accepte que les chiffres. « Valider » envoie l'image dans Cloud Storage puis crée l'activité dans Firestore.

Aucun paiement n'est proposé à ce stade.

## Mise en service de l'US#6

Le code utilise Firebase AI Logic avec le modèle `gemini-3.8-flash` via la Gemini Developer API, ainsi que Cloud Storage for Firebase pour les images. Les appels à l'IA n'embarquent aucune clé API privée dans l'application.

1. Accepter les [conditions de l'API Generative Language](https://console.cloud.google.com/terms/generative-language-api) avec le compte propriétaire du projet. L'activation d'AI Logic est bloquée tant que ces conditions ne sont pas acceptées.
2. Dans la [console Firebase du projet](https://console.firebase.google.com/project/activa-tp/ailogic), activer **AI Logic** avec la **Gemini Developer API** pour les applications Android et Web. Ne pas choisir Vertex AI pour ce projet.
3. Cloud Storage exige le forfait **Blaze**. Si ce forfait est accepté, l'activer dans la console Firebase, puis créer le bucket Storage par défaut `activa-tp.firebasestorage.app` (région Paris si disponible). Installer les règles après sa création : `firebase deploy --only firestore:rules,storage --project activa-tp`.
4. Dans **App Check > Apps**, enregistrer les jetons de débogage de l'application Android et du navigateur local. Le jeton Android apparaît dans les logs de l'émulateur ; celui du Web dans la console du navigateur. Ne jamais les committer. En production, configurer Play Integrity pour Android et une clé de site reCAPTCHA v3 pour le Web. Pour le Web en production, fournir `--dart-define=APP_CHECK_WEB_SITE_KEY=<clé-de-site>` à Flutter.
5. Lancer l'application, se connecter, ouvrir **Profil > Ajouter une activité**, choisir une image puis vérifier que la catégorie est remplie automatiquement et que « Valider » ajoute l'activité à la liste.

Le formulaire peut être compilé et testé sans ces opérations, mais l'analyse d'image et l'enregistrement réels ne sont pas disponibles tant que les services Firebase correspondants ne sont pas activés.

## Vérifications

```sh
dart format lib test
flutter analyze
flutter test
flutter build web
```

Sur la machine de développement utilisée ici, `flutter analyze` échoue depuis le chemin du dépôt contenant des caractères accentués avec une erreur interne de lecture JSON. L'analyse réussit depuis une jonction temporaire dont le chemin est ASCII ; `dart analyze` réussit aussi depuis le dépôt.

## Comptes de démonstration

Deux comptes dédiés à la démonstration ont été créés dans Firebase Authentication. Leurs identifiants sont publics conformément aux modalités de rendu du TP ; ne les utilisez pour aucun autre compte ni aucune donnée privée.

Ils disposent chacun d'un profil d'exemple modifiable dans Firestore.

| Compte | Login | Mot de passe |
|---|---|---|
| Démonstration 1 | demo1@gmail.com | password |
| Démonstration 2 | demo2@gmail.com | password |
