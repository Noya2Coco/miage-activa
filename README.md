# Activa

Activa est une application Flutter réalisée pour le TP2 du Master 2 MIAGE IA2. Elle permet de se connecter, de consulter des activités, de les ajouter à un panier, de gérer son profil et de créer une activité dont la catégorie est déterminée automatiquement par reconnaissance d'image.

**L'application cible uniquement Android.** La reconnaissance d'image de l'US#6 s'exécute sur le téléphone avec Google ML Kit, qui n'existe pas pour le Web. Aucune configuration iOS n'est fournie.

Les conventions du dépôt sont dans [CONTRIBUTING.md](CONTRIBUTING.md).

## Comptes de démonstration

Deux comptes dédiés à la démonstration existent dans Firebase Authentication, chacun avec un profil d'exemple dans Firestore. Leurs identifiants sont publics conformément aux modalités de rendu du TP.

| Compte | Login | Mot de passe |
|---|---|---|
| Démonstration 1 | demo1@gmail.com | password |
| Démonstration 2 | demo2@gmail.com | password |

Saisir un nouveau mot de passe dans le profil puis cliquer sur « Valider » modifie réellement le mot de passe du compte. Pour garder ces identifiants valables, laisser ce champ vide lors des essais.

## Lancement

Prérequis : Flutter 3.44.6 / Dart 3.12.2 (ou compatibles avec `pubspec.yaml`), le SDK Android et un émulateur ou un téléphone Android détecté par `flutter devices`. Le projet Firebase `activa-tp` est déjà configuré : aucune clé ni étape supplémentaire n'est nécessaire.

```sh
flutter pub get
flutter run -d <identifiant-appareil-android>
```

Une connexion réseau est nécessaire pour Firebase et pour les images des activités de démonstration. La reconnaissance d'image, elle, fonctionne hors ligne.

## Fonctionnalités réalisées

Toutes les User Stories du sujet sont réalisées.

- **US#1 Connexion** : en-tête « Activa », champs « Login » et « Password » (masqué), bouton « Se connecter ». Les identifiants sont vérifiés par Firebase Authentication. En cas d'échec ou de champs vides, un message s'affiche et l'application reste utilisable.
- **US#2 Liste des activités** : liste déroulante lue depuis Firestore (image, titre, lieu, prix) et barre de navigation « Activités », « Panier », « Profil » dont l'entrée courante est mise en évidence.
- **US#3 Détail** : image, titre, catégorie, lieu, nombre de personnes maximum et prix, avec les boutons « Retour » et « Ajouter au panier » (enregistrement dans Firestore, doublons évités).
- **US#4 Panier** : activités du panier (image, titre, lieu, prix), total général et croix de retrait à droite de chaque activité. Le total se met à jour après un retrait. Aucun bouton de paiement.
- **US#5 Profil** : login en lecture seule, mot de passe masqué, anniversaire, adresse, code postal (clavier numérique, chiffres uniquement) et ville. « Valider » enregistre dans Firestore, « Se déconnecter » revient à la page de connexion.
- **US#6 Ajout d'une activité** : depuis le profil, le bouton « Ajouter une activité » ouvre un formulaire avec image, titre, catégorie non éditable remplie automatiquement à partir de l'image, lieu, nombre de personnes maximum et prix (clavier numérique, chiffres uniquement). « Valider » enregistre l'activité dans Firestore ; elle apparaît aussitôt dans la liste.

## Intelligence artificielle (US#6)

La catégorie est déterminée par [ML Kit Image Labeling](https://developers.google.com/ml-kit/vision/image-labeling), un réseau de neurones de Google exécuté directement sur le téléphone. Le modèle reconnaît environ 400 étiquettes (« Mountain », « Bicycle », « Pizza », « Museum », « Handbag »…). L'application additionne la confiance des étiquettes reconnues pour chaque catégorie et retient la plus probable :

| Catégorie | Exemples d'étiquettes |
|---|---|
| Sport | Bicycle, Cycling, Skiing, Surfing, Soccer, Stadium, Running |
| Culture | Museum, Monument, Concert, Statue, Castle, Musical instrument |
| Cuisine | Food, Pizza, Sushi, Cake, Coffee, Kitchen, Wine |
| Nature | Mountain, Forest, Lake, Beach, Waterfall, Flower, Sky |
| Shopping | Handbag, Shoe, Dress, Jewellery, Sunglasses, Jeans |
| Bien-être | Pool, Bathing, Sleep, Swimwear |
| Autre | aucune étiquette reconnue parmi les précédentes |

La correspondance complète est dans [lib/activities/activity_category_classifier.dart](lib/activities/activity_category_classifier.dart).

Ce choix évite les appels réseau, les quotas et la latence d'un service distant, sans clé API ni facturation. L'analyse prend une à deux secondes sur l'émulateur ; la toute première analyse après le lancement est plus lente, le temps de charger le modèle.

Pour tester, choisir dans la galerie du téléphone une photo de paysage de montagne (Nature), de vélo ou de match (Sport), de plat cuisiné (Cuisine) ou de sac et chaussures (Shopping). Sur un émulateur, une image peut être ajoutée à la galerie en la glissant sur la fenêtre de l'émulateur.

## Données Firebase

- `activities` : lisible par les utilisateurs connectés. Chaque document contient `title`, `category`, `location`, `maxParticipants` (entier positif), `price` (nombre positif ou nul) et une image. Les trois activités de démonstration utilisent `imageUrl` (images [Unsplash](https://unsplash.com/license)) ; leur contenu est conservé dans [data/demo_activities.json](data/demo_activities.json). Les activités créées depuis l'application contiennent `imageBytes` (JPEG compressé, 500 Kio maximum), `ownerId` et `createdAt`. Les images sont stockées dans Firestore pour éviter Cloud Storage et la facturation ; cette solution convient au TP mais pas à une grande photothèque.
- `users/{uid}` : anniversaire, adresse, code postal et ville. Le mot de passe n'est jamais stocké dans Firestore : un nouveau mot de passe est enregistré dans Firebase Authentication.
- `users/{uid}/cart/{activityId}` : `activityId` et `addedAt`.

Les règles de [firestore.rules](firestore.rules) limitent le profil et le panier à leur propriétaire, vérifient le format des activités créées et interdisent leur modification ou suppression côté client.

## Configuration d'une nouvelle copie Firebase

Cette section n'est utile que pour rattacher le code à un autre projet Firebase.

```sh
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=<projet> --platforms=android --android-package-name=com.example.activa
firebase deploy --only firestore:rules --project <projet>
```

Dans la console Firebase, activer **Authentication > Sign-in method > Email/Password**, créer les comptes dans **Authentication > Users** et créer une base Cloud Firestore. Le champ **Login** de l'application correspond à l'adresse email Firebase ; l'application ne crée pas de comptes.

## Vérifications

```sh
dart format lib test
dart analyze
flutter test
flutter build apk --debug
```
