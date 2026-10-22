import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum CartAddResult { added, alreadyPresent }

abstract class CartRepository {
  Future<CartAddResult> addActivity(String activityId);
}

class FirestoreCartRepository implements CartRepository {
  FirestoreCartRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<CartAddResult> addActivity(String activityId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Aucun utilisateur connecté.');
    }

    final cartItem = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(activityId);

    if ((await cartItem.get()).exists) {
      return CartAddResult.alreadyPresent;
    }

    await cartItem.set({
      'activityId': activityId,
      'addedAt': FieldValue.serverTimestamp(),
    });
    return CartAddResult.added;
  }
}
