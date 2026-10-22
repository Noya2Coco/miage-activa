import 'package:flutter/material.dart';

import 'activity.dart';
import 'activity_image.dart';
import '../cart/cart_repository.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({
    super.key,
    required this.activity,
    this.cartRepository,
  });

  final Activity activity;
  final CartRepository? cartRepository;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late final CartRepository _cartRepository;
  bool _isSaving = false;
  bool _isInCart = false;
  String? _statusMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _cartRepository = widget.cartRepository ?? FirestoreCartRepository();
  }

  Future<void> _addToCart() async {
    if (_isSaving || _isInCart) return;

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });
    try {
      final result = await _cartRepository.addActivity(widget.activity.id);
      if (!mounted) return;
      setState(() {
        _isInCart = true;
        _hasError = false;
        _statusMessage = result == CartAddResult.added
            ? 'Activité ajoutée au panier.'
            : 'Cette activité est déjà dans votre panier.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _statusMessage = 'Impossible d’ajouter cette activité. Réessayez.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activity = widget.activity;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l’activité')),
      body: ListView(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ActivityImage(
                      url: activity.imageUrl,
                      description: activity.title,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activity.isDemo) ...[
                          const Chip(label: Text('Activité de démonstration')),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          activity.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Chip(label: Text(activity.category)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activity.location,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.groups_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Nombre de personnes maximum : ${activity.maxParticipants}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          activity.formattedPrice,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_statusMessage != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            _statusMessage!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _hasError
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isSaving || _isInCart ? null : _addToCart,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isInCart ? 'Ajouté au panier' : 'Ajouter au panier',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
