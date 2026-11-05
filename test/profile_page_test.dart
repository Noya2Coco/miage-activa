import 'package:activa/activities/activity.dart';
import 'package:activa/activities/activity_repository.dart';
import 'package:activa/activities_page.dart';
import 'package:activa/auth/authentication_service.dart';
import 'package:activa/cart/cart_page.dart';
import 'package:activa/cart/cart_repository.dart';
import 'package:activa/login_page.dart';
import 'package:activa/profile/profile_page.dart';
import 'package:activa/profile/profile_repository.dart';
import 'package:activa/profile/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.profile);

  UserProfile profile;
  String? savedPassword;
  int saves = 0;
  int signOuts = 0;

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<void> save(UserProfile value, {String? newPassword}) async {
    profile = value;
    savedPassword = newPassword;
    saves++;
  }

  @override
  Future<void> signOut() async => signOuts++;
}

class FakeAuthenticationService implements AuthenticationService {
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}
}

class FakeActivityRepository implements ActivityRepository {
  @override
  Stream<List<Activity>> watchActivities() => Stream.value([]);
}

class FakeCartRepository implements CartRepository {
  @override
  Future<CartAddResult> addActivity(String activityId) async =>
      CartAddResult.added;

  @override
  Stream<List<CartEntry>> watchItems() => Stream.value([]);

  @override
  Future<void> removeActivity(String activityId) async {}
}

void main() {
  testWidgets('ouvre le profil et affiche les champs demandés', (tester) async {
    final repository = FakeProfileRepository(
      const UserProfile(
        login: 'demo1@gmail.com',
        birthday: '12/12/1993',
        address: 'Promenade des anglais',
        postalCode: '06000',
        city: 'Nice',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ActivitiesPage(
          repository: FakeActivityRepository(),
          profileRepository: repository,
          authentication: FakeAuthenticationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('demo1@gmail.com'), findsOneWidget);
    expect(find.text('12/12/1993'), findsOneWidget);
    expect(find.text('Promenade des anglais'), findsOneWidget);
    expect(find.text('06000'), findsOneWidget);
    expect(find.text('Nice'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('profile-login')),
              matching: find.byType(EditableText),
            ),
          )
          .readOnly,
      isTrue,
    );
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('profile-password')),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isTrue,
    );
    expect(find.text('Valider'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('profile-postal-code')),
              matching: find.byType(EditableText),
            ),
          )
          .keyboardType,
      TextInputType.number,
    );
    await tester.scrollUntilVisible(
      find.text('Se déconnecter'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Se déconnecter'), findsOneWidget);
  });

  testWidgets('enregistre le profil et n’accepte que les chiffres postaux', (
    tester,
  ) async {
    final repository = FakeProfileRepository(
      const UserProfile(login: 'demo1@gmail.com'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          repository: repository,
          authentication: FakeAuthenticationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile-birthday')),
      '12/12/1993',
    );
    await tester.enterText(
      find.byKey(const Key('profile-address')),
      'Promenade des anglais',
    );
    await tester.enterText(
      find.byKey(const Key('profile-postal-code')),
      '06A000',
    );
    await tester.enterText(find.byKey(const Key('profile-city')), 'Nice');
    await tester.enterText(
      find.byKey(const Key('profile-password')),
      'nouveauPassword',
    );
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(repository.profile.login, 'demo1@gmail.com');
    expect(repository.profile.birthday, '12/12/1993');
    expect(repository.profile.address, 'Promenade des anglais');
    expect(repository.profile.postalCode, '06000');
    expect(repository.profile.city, 'Nice');
    expect(repository.savedPassword, 'nouveauPassword');
    expect(repository.saves, 1);
    expect(find.text('Profil enregistré.'), findsOneWidget);
  });

  testWidgets('refuse une date invalide et permet la déconnexion', (
    tester,
  ) async {
    final repository = FakeProfileRepository(
      const UserProfile(login: 'demo2@gmail.com'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          repository: repository,
          authentication: FakeAuthenticationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile-birthday')),
      '31/02/2020',
    );
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez une date valide.'), findsOneWidget);
    expect(repository.saves, 0);

    await tester.scrollUntilVisible(
      find.text('Se déconnecter'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(repository.signOuts, 1);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('navigue du panier au profil puis aux activités', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ActivitiesPage(
          repository: FakeActivityRepository(),
          cartRepository: FakeCartRepository(),
          profileRepository: FakeProfileRepository(
            const UserProfile(login: 'demo1@gmail.com'),
          ),
          authentication: FakeAuthenticationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Panier'));
    await tester.pumpAndSettle();
    expect(find.byType(CartPage), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      2,
    );

    await tester.tap(find.text('Activités'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivitiesPage), findsOneWidget);
  });
}
