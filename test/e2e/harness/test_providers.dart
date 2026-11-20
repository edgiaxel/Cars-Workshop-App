import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/e2e_user_profile.dart';
import 'repositories/fake_auth_repository.dart';
import 'repositories/fake_customer_repository.dart';
import 'repositories/fake_vehicle_repository.dart';

/// Provider for FakeAuthRepository
final authRepositoryProvider = Provider<FakeAuthRepository>((ref) {
  throw UnimplementedError('Override authRepositoryProvider in test scope.');
});

/// Auth controller managing active user profile
class AuthController extends Notifier<AsyncValue<UserProfile?>> {
  @override
  AsyncValue<UserProfile?> build() {
    final repo = ref.watch(authRepositoryProvider);
    return AsyncValue.data(repo.currentUser);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncValue.data(null);
  }

  void switchRole(UserRole role) {
    final repo = ref.read(authRepositoryProvider);
    repo.switchRole(role);
    state = AsyncValue.data(repo.currentUser);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<UserProfile?>>(
  AuthController.new,
);

/// Provider for FakeCustomerRepository
final customerRepositoryProvider = Provider<FakeCustomerRepository>((ref) {
  throw UnimplementedError('Override customerRepositoryProvider in test scope.');
});

/// Provider for FakeVehicleRepository
final vehicleRepositoryProvider = Provider<FakeVehicleRepository>((ref) {
  throw UnimplementedError('Override vehicleRepositoryProvider in test scope.');
});

/// Theme mode notifier for dynamic dual theming (Dark / Light)
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark; // Default to motorsport dark mode

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
