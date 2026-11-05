import 'package:flutter/material.dart';

import 'activities/activity.dart';
import 'activities/activity_detail_page.dart';
import 'activities/activity_image.dart';
import 'activities/activity_repository.dart';
import 'auth/authentication_service.dart';
import 'cart/cart_page.dart';
import 'cart/cart_repository.dart';
import 'navigation/app_bottom_navigation_bar.dart';
import 'profile/profile_page.dart';
import 'profile/profile_repository.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({
    super.key,
    this.repository,
    this.cartRepository,
    this.profileRepository,
    this.authentication,
  });

  final ActivityRepository? repository;
  final CartRepository? cartRepository;
  final ProfileRepository? profileRepository;
  final AuthenticationService? authentication;

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  late final Stream<List<Activity>> _activities;

  @override
  void initState() {
    super.initState();
    _activities = (widget.repository ?? FirestoreActivityRepository())
        .watchActivities();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Activités')),
      body: StreamBuilder<List<Activity>>(
        stream: _activities,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _StatusMessage(
              icon: Icons.wifi_off_outlined,
              message: 'Impossible de charger les activités.',
              detail: 'Vérifiez votre connexion et réessayez.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final activities = snapshot.data!;
          if (activities.isEmpty) {
            return const _StatusMessage(
              icon: Icons.explore_outlined,
              message: 'Aucune activité disponible.',
              detail: 'Revenez bientôt découvrir les activités.',
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 1,
                    child: InkWell(
                      key: Key('activity-${activity.id}'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ActivityDetailPage(
                            activity: activity,
                            cartRepository: widget.cartRepository,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 8,
                            child: ActivityImage(
                              url: activity.imageUrl,
                              description: activity.title,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.place_outlined, size: 18),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(activity.location)),
                                    const SizedBox(width: 12),
                                    Text(
                                      activity.formattedPrice,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CartPage(
                  repository: widget.cartRepository,
                  profileRepository: widget.profileRepository,
                  authentication: widget.authentication,
                  activityRepository: widget.repository,
                ),
              ),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProfilePage(
                repository: widget.profileRepository,
                authentication: widget.authentication,
                activityRepository: widget.repository,
                cartRepository: widget.cartRepository,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.message,
    required this.detail,
  });

  final IconData icon;
  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
