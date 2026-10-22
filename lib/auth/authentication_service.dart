import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthenticationService {
  Future<void> signIn({required String email, required String password});
}

class AuthenticationException implements Exception {
  const AuthenticationException(this.message);

  final String message;
}

class FirebaseAuthenticationService implements AuthenticationService {
  FirebaseAuthenticationService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw const AuthenticationException(
          'La connexion n’a pas pu être confirmée. Réessayez.',
        );
      }
    } on FirebaseAuthException catch (error) {
      throw AuthenticationException(_messageFor(error.code));
    } on FirebaseException {
      throw const AuthenticationException(
        'Le service de connexion est indisponible. Réessayez plus tard.',
      );
    }
  }

  String _messageFor(String code) {
    return switch (code) {
      'invalid-email' => 'Saisissez une adresse email valide.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Login ou mot de passe incorrect.',
      'user-disabled' => 'Ce compte est désactivé.',
      'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
      'network-request-failed' =>
        'Connexion réseau indisponible. Vérifiez votre connexion.',
      _ => 'La connexion a échoué. Réessayez.',
    };
  }
}
