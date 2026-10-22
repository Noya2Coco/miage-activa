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
    required this.imageUrl,
    this.isDemo = false,
  });

  final String id;
  final String title;
  final String category;
  final String location;
  final int maxParticipants;
  final double price;
  final String imageUrl;
  final bool isDemo;

  String get formattedPrice => price == 0 ? 'Gratuit' : formatPrice(price);

  factory Activity.fromMap(String id, Map<String, dynamic> data) {
    final title = data['title'];
    final category = data['category'];
    final location = data['location'];
    final maxParticipants = data['maxParticipants'];
    final price = data['price'];
    final imageUrl = data['imageUrl'];

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
        imageUrl is! String ||
        imageUrl.trim().isEmpty) {
      throw FormatException('Activité $id incomplète dans Firestore.');
    }

    return Activity(
      id: id,
      title: title,
      category: category,
      location: location,
      maxParticipants: maxParticipants,
      price: price.toDouble(),
      imageUrl: imageUrl,
      isDemo: data['demo'] == true,
    );
  }
}
