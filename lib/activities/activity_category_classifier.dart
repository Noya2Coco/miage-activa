import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

abstract class ActivityCategoryClassifier {
  Future<String> classify(Uint8List image, String mimeType);
}

class FirebaseAiActivityCategoryClassifier
    implements ActivityCategoryClassifier {
  FirebaseAiActivityCategoryClassifier({GenerativeModel? model})
    : _model =
          model ??
          FirebaseAI.googleAI().generativeModel(model: 'gemini-3.8-flash');

  final GenerativeModel _model;

  static const categories = [
    'Sport',
    'Culture',
    'Cuisine',
    'Nature',
    'Bien-être',
    'Autre',
  ];

  @override
  Future<String> classify(Uint8List image, String mimeType) async {
    final response = await _model.generateContent([
      Content.multi([
        TextPart(
          'Classe cette image pour une activité de loisirs. '
          'Réponds uniquement avec une catégorie parmi : '
          '${categories.join(', ')}. Si aucune catégorie ne convient, réponds Autre.',
        ),
        InlineDataPart(mimeType, image),
      ]),
    ]);
    final answer = response.text?.trim();
    for (final category in categories) {
      if (answer?.toLowerCase() == category.toLowerCase()) return category;
    }
    throw const FormatException('Catégorie non reconnue par l’IA.');
  }
}
