import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'activity_category_classifier.dart';
import 'activity_creation_repository.dart';
import 'activity_photo_picker.dart';

class CreateActivityPage extends StatefulWidget {
  const CreateActivityPage({
    super.key,
    required this.repository,
    this.photoPicker,
    this.classifier,
  });

  final ActivityCreationRepository repository;
  final ActivityPhotoPicker? photoPicker;
  final ActivityCategoryClassifier? classifier;

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _location = TextEditingController();
  final _maxParticipants = TextEditingController();
  final _price = TextEditingController();
  ActivityPhoto? _photo;
  bool _classifying = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _location.dispose();
    _maxParticipants.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_classifying || _saving) return;
    setState(() {
      _classifying = true;
      _error = null;
      _photo = null;
      _category.clear();
    });
    try {
      final photo = await (widget.photoPicker ?? GalleryActivityPhotoPicker())
          .pick();
      if (photo == null || !mounted) return;
      setState(() => _photo = photo);
      final category =
          await (widget.classifier ?? FirebaseAiActivityCategoryClassifier())
              .classify(photo.bytes, photo.mimeType);
      if (mounted) setState(() => _category.text = category);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible d’analyser l’image. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _classifying = false);
    }
  }

  Future<void> _save() async {
    if (_classifying || _saving) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null || _category.text.isEmpty) {
      setState(
        () => _error = 'Choisissez une image pour définir la catégorie.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.create(
        NewActivity(
          title: _title.text.trim(),
          category: _category.text,
          location: _location.text.trim(),
          maxParticipants: int.parse(_maxParticipants.text),
          price: int.parse(_price.text),
          photo: _photo!,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Impossible d’enregistrer l’activité. Réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Ce champ est obligatoire.'
      : null;

  String? _positive(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number <= 0) return 'Saisissez un entier positif.';
    return null;
  }

  String? _nonNegative(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0) return 'Saisissez un prix valide.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final busy = _classifying || _saving;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une activité')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_photo != null) ...[
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.memory(_photo!.bytes, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: busy ? null : _pickPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Choisir une image'),
                ),
                if (_classifying) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                  const Text('Analyse de l’image en cours…'),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('activity-title'),
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('activity-category'),
                  controller: _category,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    helperText: 'Définie automatiquement à partir de l’image.',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('activity-location'),
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Lieu'),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('activity-max-participants'),
                  controller: _maxParticipants,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Nombre de personnes maximum',
                  ),
                  validator: _positive,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('activity-price'),
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Prix (€)'),
                  validator: _nonNegative,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : _save,
                  child: Text(_saving ? 'Enregistrement…' : 'Valider'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
