import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  @override
  Future<void> create(NewActivity activity) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecté.');
    final document = _firestore.collection('activities').doc();
    final extension = switch (activity.photo.mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final imagePath = 'activities/${user.uid}/${document.id}.$extension';
    final image = _storage.ref(imagePath);
    await image.putData(
      activity.photo.bytes,
      SettableMetadata(contentType: activity.photo.mimeType),
    );
    try {
      final imageUrl = await image.getDownloadURL();
      await document.set({
        'title': activity.title,
        'category': activity.category,
        'location': activity.location,
        'maxParticipants': activity.maxParticipants,
        'price': activity.price,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'ownerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      try {
        await image.delete();
      } catch (_) {}
      rethrow;
    }
  }
}
