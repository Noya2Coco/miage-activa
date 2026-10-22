import 'dart:async';

import 'package:activa/activities/activity.dart';
import 'package:activa/activities/activity_detail_page.dart';
import 'package:activa/activities/activity_repository.dart';
import 'package:activa/activities_page.dart';
import 'package:activa/cart/cart_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository(this.activities);

  final Stream<List<Activity>> activities;

  @override
  Stream<List<Activity>> watchActivities() => activities;
}

class FakeCartRepository implements CartRepository {
  FakeCartRepository(this.result);

  final Future<CartAddResult> Function(String activityId) result;
  int calls = 0;

  @override
  Future<CartAddResult> addActivity(String activityId) {
    calls++;
    return result(activityId);
  }
}

void main() {
  const activity = Activity(
    id: 'walk',
    title: 'Randonnée panoramique',
    category: 'Sport',
    location: 'Massif des Alpes',
    maxParticipants: 12,
    price: 12,
    imageUrl: 'https://example.com/activity.jpg',
    isDemo: true,
  );

  test('lit les champs Firestore et formate le prix', () {
    final parsed = Activity.fromMap('walk', {
      'title': 'Randonnée panoramique',
      'category': 'Sport',
      'location': 'Massif des Alpes',
      'maxParticipants': 12,
      'price': 12,
      'imageUrl': 'https://example.com/activity.jpg',
      'demo': true,
    });

    expect(parsed.id, 'walk');
    expect(parsed.category, 'Sport');
    expect(parsed.maxParticipants, 12);
    expect(parsed.formattedPrice, '12,00 €');
    expect(parsed.isDemo, isTrue);
    expect(
      () => Activity.fromMap('broken', {'title': 'Sans lieu'}),
      throwsFormatException,
    );
  });

  testWidgets('affiche les activités et ouvre le détail', (tester) async {
    final controller = StreamController<List<Activity>>();
    final cart = FakeCartRepository((_) async => CartAddResult.added);
    addTearDown(controller.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivitiesPage(
          repository: FakeActivityRepository(controller.stream),
          cartRepository: cart,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    controller.add([activity]);
    await tester.pumpAndSettle();

    expect(find.text(activity.title), findsOneWidget);
    expect(find.text(activity.location), findsOneWidget);
    expect(find.text('12,00 €'), findsOneWidget);
    expect(find.text('DÉMONSTRATION'), findsOneWidget);
    expect(find.text('Activités'), findsNWidgets(2));
    expect(find.text('Panier'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      0,
    );

    await tester.tap(find.byKey(const Key('activity-walk')));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityDetailPage), findsOneWidget);
    expect(find.text(activity.title), findsOneWidget);
    expect(find.text(activity.location), findsOneWidget);
    expect(find.text('12,00 €'), findsOneWidget);
    expect(find.text('Sport'), findsOneWidget);
    expect(find.text('Nombre de personnes maximum : 12'), findsOneWidget);

    await tester.tap(find.text('Ajouter au panier'));
    await tester.pumpAndSettle();
    expect(cart.calls, 1);
    expect(find.text('Activité ajoutée au panier.'), findsOneWidget);
    expect(find.text('Ajouté au panier'), findsOneWidget);

    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivitiesPage), findsOneWidget);
  });

  testWidgets('reconnaît une activité déjà dans le panier', (tester) async {
    final cart = FakeCartRepository((_) async => CartAddResult.alreadyPresent);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailPage(activity: activity, cartRepository: cart),
      ),
    );

    await tester.tap(find.text('Ajouter au panier'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cette activité est déjà dans votre panier.'),
      findsOneWidget,
    );
    expect(cart.calls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('permet de réessayer si l’ajout échoue', (tester) async {
    final pending = Completer<CartAddResult>();
    final cart = FakeCartRepository((_) => pending.future);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailPage(activity: activity, cartRepository: cart),
      ),
    );

    await tester.tap(find.text('Ajouter au panier'));
    await tester.pump();
    expect(cart.calls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    pending.completeError(StateError('Réseau indisponible'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Impossible d’ajouter'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('garde les actions accessibles sur un petit téléphone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailPage(
          activity: activity,
          cartRepository: FakeCartRepository((_) async => CartAddResult.added),
        ),
      ),
    );

    expect(find.text('Retour'), findsOneWidget);
    expect(find.text('Ajouter au panier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signale une liste vide', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ActivitiesPage(
          repository: FakeActivityRepository(Stream.value([])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucune activité disponible.'), findsOneWidget);
  });

  testWidgets('permet de parcourir toute la liste sur téléphone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final activities = List.generate(
      3,
      (index) => Activity(
        id: 'activity-$index',
        title: 'Activité ${index + 1}',
        category: 'Sport',
        location: 'Lieu ${index + 1}',
        maxParticipants: 10,
        price: 10 + index.toDouble(),
        imageUrl: 'https://example.com/activity.jpg',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ActivitiesPage(
          repository: FakeActivityRepository(Stream.value(activities)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activité 1'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Activité 3'), 400);
    expect(find.text('Activité 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signale une erreur Firestore', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ActivitiesPage(
          repository: FakeActivityRepository(
            Stream.error(StateError('Firestore')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Impossible de charger les activités.'), findsOneWidget);
  });
}
