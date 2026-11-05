import 'dart:typed_data';

import 'package:flutter/material.dart';

class ActivityImage extends StatelessWidget {
  const ActivityImage({
    super.key,
    this.url,
    this.bytes,
    required this.description,
  });

  final String? url;
  final Uint8List? bytes;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ImageProvider image = bytes != null
        ? MemoryImage(bytes!)
        : NetworkImage(url!);
    return Image(
      image: image,
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
