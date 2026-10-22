import 'package:cloud_firestore/cloud_firestore.dart';

import 'activity.dart';

abstract class ActivityRepository {
  Stream<List<Activity>> watchActivities();
}

class FirestoreActivityRepository implements ActivityRepository {
  FirestoreActivityRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Activity>> watchActivities() {
    return _firestore.collection('activities').snapshots().map((snapshot) {
      final activities = snapshot.docs
          .map((document) => Activity.fromMap(document.id, document.data()))
          .toList();
      activities.sort((first, second) => first.title.compareTo(second.title));
      return activities;
    });
  }
}
