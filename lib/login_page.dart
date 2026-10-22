import 'package:flutter/material.dart';

import 'activities/activity_repository.dart';
import 'activities_page.dart';
import 'auth/authentication_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.authentication,
    this.configurationError,
    this.activityRepository,
  });

  final AuthenticationService? authentication;
  final String? configurationError;
  final ActivityRepository? activityRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading) return;

    final login = _loginController.text.trim();
    final password = _passwordController.text;
    if (login.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Renseignez le login et le mot de passe.');
      return;
    }

    final authentication = widget.authentication;
    if (authentication == null) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await authentication.signIn(email: login, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ActivitiesPage(repository: widget.activityRepository),
        ),
      );
    } on AuthenticationException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'La connexion a échoué. Vérifiez votre réseau et réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Activa')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.directions_run_rounded,
                    color: theme.colorScheme.primary,
                    size: 52,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bienvenue sur Activa',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous pour continuer.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    key: const Key('login-field'),
                    controller: _loginController,
                    decoration: const InputDecoration(
                      labelText: 'Login',
                      hintText: 'Adresse email',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('password-field'),
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    enabled: !_isLoading,
                    onSubmitted: (_) => _signIn(),
                  ),
                  if (widget.configurationError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.configurationError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading || widget.authentication == null
                        ? null
                        : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Se connecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
