import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'activity_photo_picker.dart';

class NewActivity {
  const NewActivity({
    required this.title,
    required this.category,
    required this.location,
    required this.maxParticipants,
    required this.price,
    required this.photo,
  });

  final String title;
  final String category;
  final String location;
  final int maxParticipants;
  final int price;
  final ActivityPhoto photo;
}

abstract class ActivityCreationRepository {
  Future<void> create(NewActivity activity);
}

class FirebaseActivityCreationRepository implements ActivityCreationRepository {
  FirebaseActivityCreationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<void> create(NewActivity activity) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecté.');
    await _firestore.collection('activities').add({
      'title': activity.title,
      'category': activity.category,
      'location': activity.location,
      'maxParticipants': activity.maxParticipants,
      'price': activity.price,
      'imageBytes': Blob(activity.photo.bytes),
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
