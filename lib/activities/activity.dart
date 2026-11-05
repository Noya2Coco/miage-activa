import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

String formatPrice(double price) =>
    '${price.toStringAsFixed(2).replaceAll('.', ',')} €';

class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.maxParticipants,
    required this.price,
    this.imageUrl,
    this.imageBytes,
    this.isDemo = false,
  });

  final String id;
  final String title;
  final String category;
  final String location;
  final int maxParticipants;
  final double price;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final bool isDemo;

  String get formattedPrice => price == 0 ? 'Gratuit' : formatPrice(price);

  factory Activity.fromMap(String id, Map<String, dynamic> data) {
    final title = data['title'];
    final category = data['category'];
    final location = data['location'];
    final maxParticipants = data['maxParticipants'];
    final price = data['price'];
    final imageUrl = data['imageUrl'];
    final imageBlob = data['imageBytes'];
    final imageBytes = imageBlob is Blob ? imageBlob.bytes : null;

    if (title is! String ||
        title.trim().isEmpty ||
        category is! String ||
        category.trim().isEmpty ||
        location is! String ||
        location.trim().isEmpty ||
        maxParticipants is! int ||
        maxParticipants <= 0 ||
        price is! num ||
        price < 0 ||
        ((imageUrl is! String || imageUrl.trim().isEmpty) &&
            (imageBytes == null || imageBytes.isEmpty))) {
      throw FormatException('Activité $id incomplète dans Firestore.');
    }

    return Activity(
      id: id,
      title: title,
      category: category,
      location: location,
      maxParticipants: maxParticipants,
      price: price.toDouble(),
      imageUrl: imageUrl is String ? imageUrl : null,
      imageBytes: imageBytes,
      isDemo: data['demo'] == true,
    );
  }
}
