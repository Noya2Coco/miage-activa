import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';

// Étiquettes du modèle de base ML Kit regroupées par catégorie d'activité.
// Liste complète : https://developers.google.com/ml-kit/vision/image-labeling/label-map
// Les catégories, plus « Autre », doivent rester alignées sur firestore.rules.
const _labelsByCategory = {
  'Sport': {
    'Archery',
    'Backpacking',
    'Badminton',
    'Balance',
    'Bicycle',
    'Boxer',
    'Canoe',
    'Caving',
    'Competition',
    'Curling',
    'Cycling',
    'Fishing',
    'Gymnastics',
    'Helmet',
    'Jersey',
    'Kayak',
    'Longboard',
    'Marathon',
    'Muscle',
    'Pitch',
    'Polo',
    'Race',
    'Racing',
    'Rafting',
    'Rodeo',
    'Roller',
    'Rowing',
    'Rugby',
    'Running',
    'Scuba diving',
    'Skateboard',
    'Skateboarder',
    'Skiing',
    'Sledding',
    'Snorkeling',
    'Snowboarding',
    'Soccer',
    'Softball',
    'Sports',
    'Stadium',
    'Surfboard',
    'Surfing',
    'Swimming',
    'Team',
    'Track',
    'Tubing',
    'Unicycle',
    'Wakeboarding',
    'Waterskiing',
    'Windsurfing',
  },
  'Culture': {
    'Aquarium',
    'Ballroom',
    'Bullfighting',
    'Carnival',
    'Castle',
    'Cathedral',
    'Church',
    'Circus',
    'Comics',
    'Concert',
    'Dance',
    'Deejay',
    'Fiction',
    'Fireworks',
    'Miniature',
    'Monument',
    'Mosque',
    'Museum',
    'Musical',
    'Musical instrument',
    'Musician',
    'Nightclub',
    'Palace',
    'Piano',
    'Pop music',
    'Porcelain',
    'Poster',
    'Ruins',
    'Singer',
    'Song',
    'Statue',
    'Temple',
    'Tower',
    'Watercolor paint',
  },
  'Cuisine': {
    'Alcohol',
    'Bento',
    'Bread',
    'Cake',
    'Cappuccino',
    'Cheeseburger',
    'Coffee',
    'Cola',
    'Cookie',
    'Cookware and bakeware',
    'Countertop',
    'Couscous',
    'Cuisine',
    'Cup',
    'Cutlery',
    'Eating',
    'Fast food',
    'Food',
    'Fruit',
    'Gelato',
    'Hot dog',
    'Icing',
    'Juice',
    'Kitchen',
    'Lunch',
    'Meal',
    'Menu',
    'Pasteles',
    'Pho',
    'Pie',
    'Pizza',
    'Placemat',
    'Saucer',
    'Steaming',
    'Supper',
    'Sushi',
    'Tablecloth',
    'Tableware',
    'Vegetable',
    'Wine',
  },
  'Nature': {
    'Aurora',
    'Beach',
    'Bird',
    'Branch',
    'Butterfly',
    'Camping',
    'Canyon',
    'Cave',
    'Cliff',
    'Desert',
    'Dune',
    'Farm',
    'Field',
    'Flora',
    'Flower',
    'Fog',
    'Forest',
    'Garden',
    'Glacier',
    'Himalayan',
    'Horse',
    'Iceberg',
    'Jungle',
    'Lake',
    'Mountain',
    'Park',
    'Petal',
    'Picnic',
    'Plant',
    'Prairie',
    'Rainbow',
    'Ranch',
    'Reef',
    'River',
    'Rock',
    'Safari',
    'Sand',
    'Sky',
    'Soil',
    'Storm',
    'Sunset',
    'Swamp',
    'Twig',
    'Underwater',
    'Volcano',
    'Waterfall',
  },
  'Shopping': {
    'Bag',
    'Bangle',
    'Beanie',
    'Blazer',
    'Bracelet',
    'Cap',
    'Denim',
    'Dress',
    'Glasses',
    'Gown',
    'Handbag',
    'Hat',
    'Jacket',
    'Jeans',
    'Jewellery',
    'Leather',
    'Leggings',
    'Lipstick',
    'Money',
    'Necklace',
    'Outerwear',
    'Product',
    'Receipt',
    'Ring',
    'Scarf',
    'Shoe',
    'Shorts',
    'Sneakers',
    'Sunglasses',
    'Textile',
    'Tie',
    'Tights',
  },
  'Bien-être': {'Bathing', 'Pool', 'Skin', 'Sleep', 'Swimwear'},
};

/// Additionne la confiance des étiquettes reconnues pour chaque catégorie
/// et retient la plus probable, ou « Autre » si aucune ne correspond.
String categoryForLabels(Map<String, double> confidenceByLabel) {
  final scores = <String, double>{};
  confidenceByLabel.forEach((label, confidence) {
    for (final entry in _labelsByCategory.entries) {
      if (entry.value.contains(label)) {
        scores[entry.key] = (scores[entry.key] ?? 0) + confidence;
      }
    }
  });
  if (scores.isEmpty) return 'Autre';
  return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

abstract class ActivityCategoryClassifier {
  Future<String> classify(Uint8List image, String mimeType);
}

/// Reconnaissance d'image exécutée sur le téléphone avec ML Kit :
/// aucun appel réseau, aucun quota, résultat en moins d'une seconde.
class OnDeviceActivityCategoryClassifier implements ActivityCategoryClassifier {
  @override
  Future<String> classify(Uint8List image, String mimeType) async {
    // ML Kit lit une image encodée (JPEG, PNG) depuis un fichier.
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/activity_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.4),
    );
    try {
      await file.writeAsBytes(image, flush: true);
      final labels = await labeler.processImage(InputImage.fromFile(file));
      return categoryForLabels({
        for (final label in labels) label.label: label.confidence,
      });
    } finally {
      await labeler.close();
      if (await file.exists()) await file.delete();
    }
  }
}
