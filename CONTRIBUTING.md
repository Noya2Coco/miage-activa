# Contribuer à Activa

Ces règles s'appliquent à toute intervention sur le dépôt, quel que soit l'outil utilisé, notamment Codex et Claude.

## Code Flutter et Dart

- Écrire du Dart idiomatique et respecter `dart format` ainsi que `flutter analyze`.
- Choisir des noms explicites et des implémentations simples, compréhensibles directement.
- Donner une responsabilité claire à chaque fichier et éviter les fichiers inutilement volumineux.
- Ne factoriser que lorsqu'un besoin réel apparaît. Éviter les abstractions prématurées et les architectures disproportionnées.
- Ajouter une dépendance uniquement si la fonctionnalité le justifie.

## Commentaires et documentation

- Commenter uniquement une intention, une contrainte ou un comportement qui ne ressort pas du code. Ne pas paraphraser les instructions évidentes.
- Éviter les longs blocs de documentation générique, les signatures automatiques et les mentions de génération dans les sources.
- Rédiger la documentation du projet dans un français naturel. Éviter les emojis décoratifs, les tournures artificielles et les caractères Unicode inhabituels sans raison. Conserver les accents dans les textes destinés aux utilisateurs.
- Faire en sorte que le code soit lisible principalement grâce à sa structure et à ses noms.

## Développement et vérification

- Traiter une seule User Story à la fois et vérifier chacun de ses critères d'acceptation.
- Ne pas ajouter de fonctionnalités anticipées ni de données fictives présentées comme opérationnelles.
- Corriger les erreurs introduites avant de conclure une étape.
- Exécuter `flutter pub get`, `dart format`, `flutter analyze` et `flutter test` après des modifications pertinentes. Signaler précisément toute vérification impossible.
- Ne jamais enregistrer de mots de passe en clair dans Firestore ou dans le code.

## Git

- Ne jamais exécuter `git push`, publier une branche, créer une Pull Request, modifier les remotes ou réécrire l'historique existant.
- Les commits locaux sont possibles avec des messages courts, précis et fidèles aux modifications, sans signature automatique inutile ni auteur inventé.
- Ne jamais committer de secrets, d'identifiants privés ou de fichiers temporaires.
