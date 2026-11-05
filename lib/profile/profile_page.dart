import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../activities/activity_repository.dart';
import '../auth/authentication_service.dart';
import '../cart/cart_page.dart';
import '../cart/cart_repository.dart';
import '../login_page.dart';
import '../navigation/app_bottom_navigation_bar.dart';
import 'profile_repository.dart';
import 'user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.repository,
    this.authentication,
    this.activityRepository,
    this.cartRepository,
  });

  final ProfileRepository? repository;
  final AuthenticationService? authentication;
  final ActivityRepository? activityRepository;
  final CartRepository? cartRepository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  late final ProfileRepository _repository;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSigningOut = false;
  String? _errorMessage;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreProfileRepository();
    _load();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _repository.load();
      if (!mounted) return;
      _loginController.text = profile.login;
      _birthdayController.text = profile.birthday;
      _addressController.text = profile.address;
      _postalCodeController.text = profile.postalCode;
      _cityController.text = profile.city;
      setState(() => _profile = profile);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Impossible de charger le profil. Réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateBirthday(String? value) {
    if (value == null || value.isEmpty) return null;
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
    if (match == null) return 'Saisissez une date au format JJ/MM/AAAA.';
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    if (year < 1 ||
        date.day != day ||
        date.month != month ||
        date.year != year) {
      return 'Saisissez une date valide.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_isSaving || _isSigningOut || _profile == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final profile = UserProfile(
      login: _profile!.login,
      birthday: _birthdayController.text.trim(),
      address: _addressController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      city: _cityController.text.trim(),
    );
    try {
      await _repository.save(
        profile,
        newPassword: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
      );
      if (!mounted) return;
      _passwordController.clear();
      setState(() => _profile = profile);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil enregistré.')));
    } on ProfileException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Impossible d’enregistrer le profil.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut || _isSaving) return;
    setState(() {
      _isSigningOut = true;
      _errorMessage = null;
    });
    try {
      await _repository.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginPage(
            authentication:
                widget.authentication ?? FirebaseAuthenticationService(),
            activityRepository: widget.activityRepository,
            cartRepository: widget.cartRepository,
            profileRepository: widget.repository,
          ),
        ),
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Impossible de se déconnecter.');
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (_profile != null)
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              key: const Key('profile-login'),
                              controller: _loginController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Login',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('profile-password'),
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                helperText:
                                    'Laisser vide pour conserver le mot de passe.',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('profile-birthday'),
                              controller: _birthdayController,
                              keyboardType: TextInputType.datetime,
                              decoration: const InputDecoration(
                                labelText: 'Anniversaire',
                                hintText: 'JJ/MM/AAAA',
                              ),
                              validator: _validateBirthday,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('profile-address'),
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Adresse',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('profile-postal-code'),
                              controller: _postalCodeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Code Postal',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('profile-city'),
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'Ville',
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _isSaving || _isSigningOut
                                  ? null
                                  : _save,
                              child: const Text('Valider'),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    if (_profile == null)
                      TextButton(
                        onPressed: _load,
                        child: const Text('Réessayer'),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _isSigningOut || _isSaving ? null : _signOut,
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => CartPage(
                  repository: widget.cartRepository,
                  profileRepository: widget.repository,
                  authentication: widget.authentication,
                  activityRepository: widget.activityRepository,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
