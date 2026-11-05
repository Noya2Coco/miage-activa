import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> load();

  Future<void> save(UserProfile profile, {String? newPassword});

  Future<void> signOut();
}

class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User _currentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ProfileException('Aucun utilisateur connecté.');
    }
    return user;
  }

  @override
  Future<UserProfile> load() async {
    final user = _currentUser();
    final document = await _firestore.collection('users').doc(user.uid).get();
    return UserProfile.fromMap(user.email ?? '', document.data());
  }

  @override
  Future<void> save(UserProfile profile, {String? newPassword}) async {
    final user = _currentUser();
    var passwordChanged = false;
    if (newPassword != null && newPassword.isNotEmpty) {
      try {
        await user.updatePassword(newPassword);
        passwordChanged = true;
      } on FirebaseAuthException catch (error) {
        throw ProfileException(switch (error.code) {
          'requires-recent-login' =>
            'Reconnectez-vous avant de modifier votre mot de passe.',
          'weak-password' => 'Choisissez un mot de passe plus fort.',
          _ => 'Impossible de modifier le mot de passe. Réessayez.',
        });
      }
    }

    try {
      await _firestore.collection('users').doc(user.uid).set(profile.toMap());
    } catch (_) {
      if (passwordChanged) {
        throw const ProfileException(
          'Le mot de passe a été modifié, mais le profil n’a pas été enregistré. Réessayez.',
        );
      }
      throw const ProfileException(
        'Impossible d’enregistrer le profil. Réessayez.',
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
