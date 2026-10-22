import 'dart:async';

import 'package:activa/activities/activity.dart';
import 'package:activa/activities/activity_detail_page.dart';
import 'package:activa/activities/activity_repository.dart';
import 'package:activa/activities_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository(this.activities);

  final Stream<List<Activity>> activities;

  @override
  Stream<List<Activity>> watchActivities() => activities;
}

void main() {
  const activity = Activity(
    id: 'walk',
    title: 'Randonnée panoramique',
    location: 'Massif des Alpes',
    price: 12,
    imageUrl: 'https://example.com/activity.jpg',
    isDemo: true,
  );

  test('lit les champs Firestore et formate le prix', () {
    final parsed = Activity.fromMap('walk', {
      'title': 'Randonnée panoramique',
      'location': 'Massif des Alpes',
      'price': 12,
      'imageUrl': 'https://example.com/activity.jpg',
      'demo': true,
    });

    expect(parsed.id, 'walk');
    expect(parsed.formattedPrice, '12,00 €');
    expect(parsed.isDemo, isTrue);
    expect(
      () => Activity.fromMap('broken', {'title': 'Sans lieu'}),
      throwsFormatException,
    );
  });

  testWidgets('affiche les activités et ouvre le détail', (tester) async {
    final controller = StreamController<List<Activity>>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivitiesPage(
          repository: FakeActivityRepository(controller.stream),
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
        location: 'Lieu ${index + 1}',
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
