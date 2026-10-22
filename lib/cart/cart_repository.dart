import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../activities/activity.dart';

enum CartAddResult { added, alreadyPresent }

class CartEntry {
  const CartEntry({required this.activityId, required this.activity});

  final String activityId;
  final Activity? activity;
}

abstract class CartRepository {
  Future<CartAddResult> addActivity(String activityId);

  Stream<List<CartEntry>> watchItems();

  Future<void> removeActivity(String activityId);
}

class FirestoreCartRepository implements CartRepository {
  FirestoreCartRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _cartCollection() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Aucun utilisateur connecté.');
    }
    return _firestore.collection('users').doc(user.uid).collection('cart');
  }

  @override
  Future<CartAddResult> addActivity(String activityId) async {
    final cartItem = _cartCollection().doc(activityId);

    if ((await cartItem.get()).exists) {
      return CartAddResult.alreadyPresent;
    }

    await cartItem.set({
      'activityId': activityId,
      'addedAt': FieldValue.serverTimestamp(),
    });
    return CartAddResult.added;
  }

  @override
  Stream<List<CartEntry>> watchItems() {
    final collection = _cartCollection();
    return collection.snapshots().asyncMap((snapshot) async {
      final entries = await Future.wait(
        snapshot.docs.map((item) async {
          final document = await _firestore
              .collection('activities')
              .doc(item.id)
              .get();
          return CartEntry(
            activityId: item.id,
            activity: document.exists
                ? Activity.fromMap(item.id, document.data()!)
                : null,
          );
        }),
      );
      entries.sort((first, second) {
        final firstTitle = first.activity?.title ?? first.activityId;
        final secondTitle = second.activity?.title ?? second.activityId;
        return firstTitle.compareTo(secondTitle);
      });
      return entries;
    });
  }

  @override
  Future<void> removeActivity(String activityId) =>
      _cartCollection().doc(activityId).delete();
}
