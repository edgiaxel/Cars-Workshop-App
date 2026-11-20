import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/features/auth/data/auth_repository.dart';
import 'package:pitmate/features/auth/domain/auth_session_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

class AuthController extends Notifier<AuthSessionState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthSessionState build() {
    _init();
    return const AuthSessionState(isLoading: true);
  }

  Future<void> _init() async {
    try {
      final profile = await _repo.getCurrentProfile();
      state = state.copyWith(user: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }

    _repo.watchAuthState().listen((profile) {
      state = state.copyWith(user: profile, isLoading: false);
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repo.signInWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(user: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> verifyOtp(String email, String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.verifyOtp(email: email, token: token);
      final profile = await _repo.getCurrentProfile();
      state = state.copyWith(user: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthSessionState(user: null, isLoading: false);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthSessionState>(AuthController.new);
