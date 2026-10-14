import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mechanic.dart';

/// Contract for Mechanic remote data operations.
abstract class MechanicRemoteDataSource {
  Future<List<Mechanic>> fetchMechanics({String? searchQuery});
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

/// Supabase implementation for [MechanicRemoteDataSource].
class SupabaseMechanicRemoteDataSource implements MechanicRemoteDataSource {
  const SupabaseMechanicRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Mechanic?> getMechanicByProfileId(String profileId) async {
    final data = await _client
        .from('mechanics')
        .select('*, profiles(*)')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (data == null) return null;
    return Mechanic.fromJson(data);
  }

  @override
  Future<List<Mechanic>> fetchMechanics({String? searchQuery}) async {
    final data = await _client
        .from('mechanics')
        .select('*, profiles(*)')
        .order('employee_code', ascending: true);

    final mechanics = (data as List)
        .map((json) => Mechanic.fromJson(json as Map<String, dynamic>))
        .toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      return mechanics.where((m) {
        final nameMatch = m.displayName.toLowerCase().contains(q);
        final codeMatch = m.employeeCode.toLowerCase().contains(q);
        final specMatch = m.specialization?.toLowerCase().contains(q) ?? false;
        return nameMatch || codeMatch || specMatch;
      }).toList();
    }

    return mechanics;
  }

  @override
  Future<Mechanic> getMechanicById(String id) async {
    final data = await _client
        .from('mechanics')
        .select('*, profiles(*)')
        .eq('id', id)
        .single();
    return Mechanic.fromJson(data);
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
  }) async {
    final updatePayload = <String, dynamic>{};
    if (employeeCode != null) {
      updatePayload['employee_code'] = employeeCode;
    }
    if (specialization != null) {
      updatePayload['specialization'] = specialization;
    }
    if (hourlyRate != null) {
      updatePayload['hourly_rate'] = hourlyRate;
    }
    if (compensationPercentage != null) {
      updatePayload['compensation_percentage'] = compensationPercentage;
    }
    if (hireDate != null) {
      updatePayload['hire_date'] =
          "${hireDate.year.toString().padLeft(4, '0')}-${hireDate.month.toString().padLeft(2, '0')}-${hireDate.day.toString().padLeft(2, '0')}";
    }

    final mechanicData = await _client
        .from('mechanics')
        .update(updatePayload)
        .eq('id', id)
        .select('*, profiles(*)')
        .single();

    final mechanic = Mechanic.fromJson(mechanicData);

    if (fullName != null || phone != null) {
      final profilePayload = <String, dynamic>{};
      if (fullName != null && fullName.trim().isNotEmpty) {
        profilePayload['full_name'] = fullName.trim();
      }
      if (phone != null) {
        profilePayload['phone'] = phone.trim();
      }

      if (profilePayload.isNotEmpty) {
        await _client
            .from('profiles')
            .update(profilePayload)
            .eq('id', mechanic.profileId);
      }

      return getMechanicById(id);
    }

    return mechanic;
  }

  @override
  Future<Mechanic> createMechanic({
    required String profileId,
    required String employeeCode,
    String? specialization,
    double hourlyRate = 0,
    double compensationPercentage = 30,
    DateTime? hireDate,
  }) async {
    final payload = <String, dynamic>{
      'profile_id': profileId,
      'employee_code': employeeCode,
      'hourly_rate': hourlyRate,
      'compensation_percentage': compensationPercentage,
    };
    if (specialization != null) {
      payload['specialization'] = specialization;
    }
    if (hireDate != null) {
      payload['hire_date'] =
          "${hireDate.year.toString().padLeft(4, '0')}-${hireDate.month.toString().padLeft(2, '0')}-${hireDate.day.toString().padLeft(2, '0')}";
    }

    final data = await _client
        .from('mechanics')
        .insert(payload)
        .select('*, profiles(*)')
        .single();

    return Mechanic.fromJson(data);
  }

  @override
  Future<void> deleteMechanic(String id) async {
    await _client.from('mechanics').delete().eq('id', id);
  }
}
