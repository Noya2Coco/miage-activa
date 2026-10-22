import 'package:flutter/material.dart';

import '../activities/activity.dart';
import '../activities/activity_image.dart';
import '../navigation/app_bottom_navigation_bar.dart';
import 'cart_repository.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, this.repository});

  final CartRepository? repository;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final CartRepository _repository;
  late final Stream<List<CartEntry>> _items;
  final Set<String> _removing = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreCartRepository();
    _items = _repository.watchItems();
  }

  Future<void> _remove(String activityId) async {
    if (_removing.contains(activityId)) return;
    setState(() => _removing.add(activityId));
    try {
      await _repository.removeActivity(activityId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de retirer cette activité.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _removing.remove(activityId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<CartEntry>>(
        stream: _items,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Impossible de charger le panier.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!;
          final totalCents = entries.fold<int>(
            0,
            (total, entry) =>
                total + ((entry.activity?.price ?? 0) * 100).round(),
          );

          return Column(
            children: [
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('Votre panier est vide.'))
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: entries.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              final activity = entry.activity;
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 88,
                                        height: 88,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: activity == null
                                              ? const ColoredBox(
                                                  color: Color(0xFFE2EFEC),
                                                  child: Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                  ),
                                                )
                                              : ActivityImage(
                                                  url: activity.imageUrl,
                                                  description: activity.title,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              activity?.title ??
                                                  'Activité indisponible',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              activity?.location ??
                                                  'Lieu indisponible',
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              activity?.formattedPrice ?? '—',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        key: Key('remove-${entry.activityId}'),
                                        tooltip: 'Retirer du panier',
                                        onPressed:
                                            _removing.contains(entry.activityId)
                                            ? null
                                            : () => _remove(entry.activityId),
                                        icon:
                                            _removing.contains(entry.activityId)
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 712),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Total général',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          formatPrice(totalCents / 100),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
          } else if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cette rubrique arrive bientôt.')),
            );
          }
        },
      ),
    );
  }
}
