class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.isDemo = false,
  });

  final String id;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final bool isDemo;

  String get formattedPrice => price == 0
      ? 'Gratuit'
      : '${price.toStringAsFixed(2).replaceAll('.', ',')} €';

  factory Activity.fromMap(String id, Map<String, dynamic> data) {
    final title = data['title'];
    final location = data['location'];
    final price = data['price'];
    final imageUrl = data['imageUrl'];

    if (title is! String ||
        title.trim().isEmpty ||
        location is! String ||
        location.trim().isEmpty ||
        price is! num ||
        price < 0 ||
        imageUrl is! String ||
        imageUrl.trim().isEmpty) {
      throw FormatException('Activité $id incomplète dans Firestore.');
    }

    return Activity(
      id: id,
      title: title,
      location: location,
      price: price.toDouble(),
      imageUrl: imageUrl,
      isDemo: data['demo'] == true,
    );
  }
}
