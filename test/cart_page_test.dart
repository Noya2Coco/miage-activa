import 'dart:async';

import 'package:activa/activities/activity.dart';
import 'package:activa/activities/activity_repository.dart';
import 'package:activa/activities_page.dart';
import 'package:activa/cart/cart_page.dart';
import 'package:activa/cart/cart_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestCartRepository implements CartRepository {
  TestCartRepository(this.items, {Future<void> Function(String)? onRemove})
    : _onRemove = onRemove ?? ((_) async {});

  final Stream<List<CartEntry>> items;
  final Future<void> Function(String) _onRemove;

  @override
  Future<CartAddResult> addActivity(String activityId) async =>
      CartAddResult.added;

  @override
  Stream<List<CartEntry>> watchItems() => items;

  @override
  Future<void> removeActivity(String activityId) => _onRemove(activityId);
}

class TestActivityRepository implements ActivityRepository {
  TestActivityRepository(this.activities);

  final List<Activity> activities;

  @override
  Stream<List<Activity>> watchActivities() => Stream.value(activities);
}

void main() {
  const walk = Activity(
    id: 'walk',
    title: 'Randonnée panoramique',
    category: 'Sport',
    location: 'Massif des Alpes',
    maxParticipants: 12,
    price: 12,
    imageUrl: 'https://example.com/walk.jpg',
  );
  const cycling = Activity(
    id: 'cycling',
    title: 'Sortie cycliste en groupe',
    category: 'Sport',
    location: 'Annecy',
    maxParticipants: 16,
    price: 18,
    imageUrl: 'https://example.com/cycling.jpg',
  );

  testWidgets('ouvre le panier depuis la navigation et revient aux activités', (
    tester,
  ) async {
    final cart = TestCartRepository(Stream.value([]));
    await tester.pumpWidget(
      MaterialApp(
        home: ActivitiesPage(
          repository: TestActivityRepository([walk]),
          cartRepository: cart,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Panier'));
    await tester.pumpAndSettle();
    expect(find.byType(CartPage), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      1,
    );

    await tester.tap(find.text('Activités'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivitiesPage), findsOneWidget);
  });

  testWidgets('affiche le contenu, retire une activité et recalcule le total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = StreamController<List<CartEntry>>();
    addTearDown(controller.close);
    final cart = TestCartRepository(
      controller.stream,
      onRemove: (id) async {
        expect(id, 'walk');
        controller.add([
          const CartEntry(activityId: 'cycling', activity: cycling),
        ]);
      },
    );
    await tester.pumpWidget(MaterialApp(home: CartPage(repository: cart)));
    controller.add([
      const CartEntry(activityId: 'walk', activity: walk),
      const CartEntry(activityId: 'cycling', activity: cycling),
    ]);
    await tester.pumpAndSettle();

    expect(find.text(walk.title), findsOneWidget);
    expect(find.text(walk.location), findsOneWidget);
    expect(find.text(cycling.title), findsOneWidget);
    expect(find.text(cycling.location), findsOneWidget);
    expect(find.text('12,00 €'), findsOneWidget);
    expect(find.text('18,00 €'), findsOneWidget);
    expect(find.text('30,00 €'), findsOneWidget);
    expect(find.text('Total général'), findsOneWidget);
    expect(find.textContaining('Payer'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('remove-walk')));
    await tester.pumpAndSettle();
    expect(find.text(walk.title), findsNothing);
    expect(find.text(cycling.title), findsOneWidget);
    expect(find.text('18,00 €'), findsNWidgets(2));
  });

  testWidgets('affiche un total nul quand le panier est vide', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CartPage(repository: TestCartRepository(Stream.value([]))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Votre panier est vide.'), findsOneWidget);
    expect(find.text('0,00 €'), findsOneWidget);
  });

  testWidgets('conserve une activité si le retrait échoue', (tester) async {
    final cart = TestCartRepository(
      Stream.value([const CartEntry(activityId: 'walk', activity: walk)]),
      onRemove: (_) async => throw StateError('Réseau indisponible'),
    );
    await tester.pumpWidget(MaterialApp(home: CartPage(repository: cart)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('remove-walk')));
    await tester.pumpAndSettle();
    expect(find.text(walk.title), findsOneWidget);
    expect(find.text('Impossible de retirer cette activité.'), findsOneWidget);
  });
}
