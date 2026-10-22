import 'package:flutter/material.dart';

class ActivityImage extends StatelessWidget {
  const ActivityImage({
    super.key,
    required this.url,
    required this.description,
  });

  final String url;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      semanticLabel: description,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFE2EFEC),
        child: Center(
          child: Icon(Icons.image_not_supported_outlined, size: 42),
        ),
      ),
    );
  }
}
