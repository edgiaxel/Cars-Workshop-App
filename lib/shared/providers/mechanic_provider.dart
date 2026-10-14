import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mechanic_remote_datasource.dart';
import '../../data/models/mechanic.dart';
import '../../data/repositories/mechanic_repository.dart';
import 'auth_provider.dart';
import 'supabase_provider.dart';

/// Provider for [MechanicRemoteDataSource].
final mechanicRemoteDataSourceProvider = Provider<MechanicRemoteDataSource?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseMechanicRemoteDataSource(client);
});

/// Provider for [MechanicRepository].
final mechanicRepositoryProvider = Provider<MechanicRepository?>((ref) {
  final dataSource = ref.watch(mechanicRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseMechanicRepository(dataSource);
});

/// AsyncNotifier managing Mechanics roster and operations.
class MechanicsNotifier extends AsyncNotifier<List<Mechanic>> {
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  @override
  Future<List<Mechanic>> build() async {
    final repository = ref.watch(mechanicRepositoryProvider);
    if (repository == null) {
      return const [];
    }
    return repository.getMechanics(searchQuery: _searchQuery);
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(mechanicRepositoryProvider);
      if (repository == null) return const [];
      return repository.getMechanics(searchQuery: _searchQuery);
    });
  }

  Future<Mechanic> updateMechanic({
    required String id,
    String? employeeCode,
    String? specialization,
    double? hourlyRate,
    double? compensationPercentage,
    DateTime? hireDate,
    String? fullName,
    String? phone,
  }) async {
    final repository = ref.read(mechanicRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase mechanic repository is unconfigured.');
    }

    final updated = await repository.updateMechanic(
      id: id,
      employeeCode: employeeCode,
      specialization: specialization,
      hourlyRate: hourlyRate,
      compensationPercentage: compensationPercentage,
      hireDate: hireDate,
      fullName: fullName,
      phone: phone,
    );

    ref.invalidateSelf();
    return updated;
  }

  Future<Mechanic> createMechanic({
    required String profileId,
    required String employeeCode,
    String? specialization,
    double hourlyRate = 0,
    double compensationPercentage = 30,
    DateTime? hireDate,
  }) async {
    final repository = ref.read(mechanicRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase mechanic repository is unconfigured.');
    }

    final created = await repository.createMechanic(
      profileId: profileId,
      employeeCode: employeeCode,
      specialization: specialization,
      hourlyRate: hourlyRate,
      compensationPercentage: compensationPercentage,
      hireDate: hireDate,
    );

    ref.invalidateSelf();
    return created;
  }

  Future<void> deleteMechanic(String id) async {
    final repository = ref.read(mechanicRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase mechanic repository is unconfigured.');
    }

    await repository.deleteMechanic(id);
    ref.invalidateSelf();
  }
}

/// Provider exposing mechanics roster.
final mechanicsProvider =
    AsyncNotifierProvider<MechanicsNotifier, List<Mechanic>>(
      MechanicsNotifier.new,
    );

/// Provider for the currently authenticated mechanic's profile.
final currentMechanicProvider = FutureProvider<Mechanic?>((ref) async {
  final authState = ref.watch(authSessionProvider);
  if (!authState.isAuthenticated || authState.userId == null) {
    return null;
  }
  final repository = ref.watch(mechanicRepositoryProvider);
  if (repository == null) return null;
  return repository.getMechanicByProfileId(authState.userId!);
});
