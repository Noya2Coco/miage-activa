import 'dart:convert';
import 'dart:typed_data';

import 'package:activa/activities/activity_category_classifier.dart';
import 'package:activa/activities/activity_creation_repository.dart';
import 'package:activa/activities/activity_photo_picker.dart';
import 'package:activa/activities/create_activity_page.dart';
import 'package:activa/profile/profile_page.dart';
import 'package:activa/profile/profile_repository.dart';
import 'package:activa/profile/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePhotoPicker implements ActivityPhotoPicker {
  @override
  Future<ActivityPhoto?> pick() async => ActivityPhoto(
    bytes: Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=',
      ),
    ),
    mimeType: 'image/png',
  );
}

class FakeClassifier implements ActivityCategoryClassifier {
  @override
  Future<String> classify(Uint8List image, String mimeType) async {
    expect(mimeType, 'image/png');
    return 'Nature';
  }
}

class FakeCreationRepository implements ActivityCreationRepository {
  NewActivity? saved;

  @override
  Future<void> create(NewActivity activity) async => saved = activity;
}

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile> load() async =>
      const UserProfile(login: 'demo1@gmail.com');

  @override
  Future<void> save(UserProfile profile, {String? newPassword}) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('catégorie automatique et enregistrement de l’activité', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeCreationRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: CreateActivityPage(
          repository: repository,
          photoPicker: FakePhotoPicker(),
          classifier: FakeClassifier(),
        ),
      ),
    );

    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('activity-category')),
              matching: find.byType(EditableText),
            ),
          )
          .readOnly,
      isTrue,
    );
    await tester.tap(find.text('Choisir une image'));
    await tester.pumpAndSettle();
    expect(find.text('Nature'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('activity-title')), 'Balade');
    await tester.enterText(find.byKey(const Key('activity-location')), 'Paris');
    await tester.enterText(
      find.byKey(const Key('activity-max-participants')),
      '12',
    );
    await tester.enterText(find.byKey(const Key('activity-price')), '15a');
    expect(find.text('15'), findsOneWidget);
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(repository.saved?.title, 'Balade');
    expect(repository.saved?.category, 'Nature');
    expect(repository.saved?.location, 'Paris');
    expect(repository.saved?.maxParticipants, 12);
    expect(repository.saved?.price, 15);
  });

  testWidgets('exige une image et des valeurs valides', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeCreationRepository();
    await tester.pumpWidget(
      MaterialApp(home: CreateActivityPage(repository: repository)),
    );
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Ce champ est obligatoire.'), findsNWidgets(2));
    expect(repository.saved, isNull);

    await tester.enterText(find.byKey(const Key('activity-title')), 'Balade');
    await tester.enterText(find.byKey(const Key('activity-location')), 'Paris');
    await tester.enterText(
      find.byKey(const Key('activity-max-participants')),
      '0',
    );
    await tester.enterText(find.byKey(const Key('activity-price')), '0');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez un entier positif.'), findsOneWidget);
    expect(repository.saved, isNull);

    await tester.enterText(
      find.byKey(const Key('activity-max-participants')),
      '2',
    );
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choisissez une image pour définir la catégorie.'),
      findsOneWidget,
    );
    expect(repository.saved, isNull);
  });

  testWidgets('ouvre le formulaire depuis le profil', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          repository: FakeProfileRepository(),
          activityCreationRepository: FakeCreationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ajouter une activité'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Ajouter une activité'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateActivityPage), findsOneWidget);
  });
}
