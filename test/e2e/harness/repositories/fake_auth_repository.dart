import 'dart:async';
import 'package:pitmate/core/errors/app_exception.dart';
import '../models/e2e_user_profile.dart';
import '../fixtures/seed_fixtures.dart';

/// Test fake for Supabase Auth integration.
class FakeAuthRepository {
  UserProfile? _currentUser;
  final _authStateController = StreamController<UserProfile?>.broadcast();

  FakeAuthRepository({UserProfile? initialUser}) : _currentUser = initialUser;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  Stream<UserProfile?> get authStateChanges => _authStateController.stream;

  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw const AuthException('Email and password cannot be empty.');
    }

    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    // Role-based matching from email or defaults
    final UserProfile profile;
    if (email.contains('admin')) {
      profile = SeedFixtures.adminUser.copyWith(email: email);
    } else if (email.contains('mechanic')) {
      profile = SeedFixtures.mechanicUser.copyWith(email: email);
    } else {
      profile = SeedFixtures.customerUser.copyWith(email: email);
    }

    _currentUser = profile;
    _authStateController.add(_currentUser);
    return profile;
  }

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw const ValidationException('Invalid email format.');
    }
    if (fullName.trim().isEmpty) {
      throw const ValidationException('Full name is required.');
    }
    if (password.length < 6) {
      throw const ValidationException('Password must be at least 6 characters.');
    }

    final newProfile = UserProfile(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      role: UserRole.customer, // Public signup is always customer (anti-escalation)
      fullName: fullName.trim(),
      email: email.trim(),
    );

    _currentUser = newProfile;
    _authStateController.add(_currentUser);
    return newProfile;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  void setCurrentUser(UserProfile? user) {
    _currentUser = user;
    _authStateController.add(_currentUser);
  }

  void switchRole(UserRole newRole) {
    if (_currentUser == null) {
      throw const AuthException('Cannot switch role without active session.');
    }
    _currentUser = _currentUser!.copyWith(role: newRole);
    _authStateController.add(_currentUser);
  }

  void dispose() {
    _authStateController.close();
  }
}
