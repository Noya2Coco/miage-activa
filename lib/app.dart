import 'package:flutter/material.dart';

import 'activities/activity_repository.dart';
import 'auth/authentication_service.dart';
import 'login_page.dart';

class ActivaApp extends StatelessWidget {
  const ActivaApp({
    super.key,
    this.authentication,
    this.configurationError,
    this.activityRepository,
  });

  final AuthenticationService? authentication;
  final String? configurationError;
  final ActivityRepository? activityRepository;

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF166A67);

    return MaterialApp(
      title: 'Activa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: brandColor),
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7FAF9),
          foregroundColor: Color(0xFF123B3A),
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: LoginPage(
        authentication: authentication,
        configurationError: configurationError,
        activityRepository: activityRepository,
      ),
    );
  }
}
