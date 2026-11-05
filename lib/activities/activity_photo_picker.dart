import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';

class ActivityPhoto {
  const ActivityPhoto({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

abstract class ActivityPhotoPicker {
  Future<ActivityPhoto?> pick();
}

class GalleryActivityPhotoPicker implements ActivityPhotoPicker {
  GalleryActivityPhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<ActivityPhoto?> pick() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 75,
    );
    if (file == null) return null;
    final mimeType = file.mimeType ?? _mimeTypeFromName(file.name);
    if (!['image/jpeg', 'image/png', 'image/webp'].contains(mimeType)) {
      throw const FormatException('Choisissez une image JPEG, PNG ou WebP.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Choisissez une image de moins de 5 Mo.');
    }
    final compressed = await compute(compressActivityPhoto, bytes);
    return ActivityPhoto(bytes: compressed, mimeType: 'image/jpeg');
  }

  String _mimeTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return '';
  }
}

Uint8List compressActivityPhoto(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Cette image est illisible.');
  }
  for (final dimension in [1000, 800, 600, 400]) {
    final maxSize = decoded.width >= decoded.height
        ? decoded.width
        : decoded.height;
    final target = dimension < maxSize ? dimension : maxSize;
    final resized = decoded.width >= decoded.height
        ? image.copyResize(decoded, width: target)
        : image.copyResize(decoded, height: target);
    for (final quality in [75, 60, 45]) {
      final encoded = image.encodeJpg(resized, quality: quality);
      if (encoded.length <= 500 * 1024) return encoded;
    }
  }
  throw const FormatException(
    'Cette image ne peut pas être réduite suffisamment.',
  );
}
