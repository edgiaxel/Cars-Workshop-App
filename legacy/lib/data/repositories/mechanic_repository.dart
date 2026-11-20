import '../datasources/mechanic_remote_datasource.dart';
import '../models/mechanic.dart';

/// Repository interface for Mechanic operations.
abstract class MechanicRepository {
  Future<List<Mechanic>> getMechanics({String? searchQuery});
  Future<Mechanic> getMechanicById(String id);
  Future<Mechanic?> getMechanicByProfileId(String profileId);
  Future<Mechanic> updateMechanic({
    required String id,
    String? employeeCode,
    String? specialization,
    double? hourlyRate,
    double? compensationPercentage,
    DateTime? hireDate,
    String? fullName,
    String? phone,
  });
  Future<Mechanic> createMechanic({
    required String profileId,
    required String employeeCode,
    String? specialization,
    double hourlyRate = 0,
    double compensationPercentage = 30,
    DateTime? hireDate,
  });
  Future<void> deleteMechanic(String id);
}

/// Supabase implementation for [MechanicRepository].
class SupabaseMechanicRepository implements MechanicRepository {
  const SupabaseMechanicRepository(this._remoteDataSource);

  final MechanicRemoteDataSource _remoteDataSource;

  @override
  Future<List<Mechanic>> getMechanics({String? searchQuery}) {
    return _remoteDataSource.fetchMechanics(searchQuery: searchQuery);
  }

  @override
  Future<Mechanic> getMechanicById(String id) {
    return _remoteDataSource.getMechanicById(id);
  }

  @override
  Future<Mechanic?> getMechanicByProfileId(String profileId) {
    return _remoteDataSource.getMechanicByProfileId(profileId);
  }

  @override
  Future<Mechanic> updateMechanic({
    required String id,
    String? employeeCode,
    String? specialization,
    double? hourlyRate,
    double? compensationPercentage,
    DateTime? hireDate,
    String? fullName,
    String? phone,
  }) {
    return _remoteDataSource.updateMechanic(
      id: id,
      employeeCode: employeeCode,
      specialization: specialization,
      hourlyRate: hourlyRate,
      compensationPercentage: compensationPercentage,
      hireDate: hireDate,
      fullName: fullName,
      phone: phone,
    );
  }

  @override
  Future<Mechanic> createMechanic({
    required String profileId,
    required String employeeCode,
    String? specialization,
    double hourlyRate = 0,
    double compensationPercentage = 30,
    DateTime? hireDate,
  }) {
    return _remoteDataSource.createMechanic(
      profileId: profileId,
      employeeCode: employeeCode,
      specialization: specialization,
      hourlyRate: hourlyRate,
      compensationPercentage: compensationPercentage,
      hireDate: hireDate,
    );
  }

  @override
  Future<void> deleteMechanic(String id) {
    return _remoteDataSource.deleteMechanic(id);
  }
}
