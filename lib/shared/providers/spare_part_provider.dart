import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/spare_part_remote_datasource.dart';
import '../../data/models/spare_part.dart';
import '../../data/repositories/spare_part_repository.dart';
import 'supabase_provider.dart';

/// Provider for [SparePartRemoteDataSource].
final sparePartRemoteDataSourceProvider = Provider<SparePartRemoteDataSource?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseSparePartRemoteDataSource(client);
});

/// Provider for [SparePartRepository].
final sparePartRepositoryProvider = Provider<SparePartRepository?>((ref) {
  final dataSource = ref.watch(sparePartRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseSparePartRepository(dataSource);
});

/// AsyncNotifier managing the spare parts / inventory catalog.
class SparePartsNotifier extends AsyncNotifier<List<SparePart>> {
  String _searchQuery = '';
  String _categoryFilter = 'All';
  bool _lowStockOnly = false;

  String get searchQuery => _searchQuery;
  String get categoryFilter => _categoryFilter;
  bool get lowStockOnly => _lowStockOnly;

  @override
  Future<List<SparePart>> build() async {
    final repository = ref.watch(sparePartRepositoryProvider);
    if (repository == null) {
      return const [];
    }
    return repository.getSpareParts(
      searchQuery: _searchQuery,
      categoryFilter: _categoryFilter,
      lowStockOnly: _lowStockOnly,
    );
  }

  Future<void> setFilter({
    String? query,
    String? category,
    bool? lowStockOnly,
  }) async {
    if (query != null) _searchQuery = query;
    if (category != null) _categoryFilter = category;
    if (lowStockOnly != null) _lowStockOnly = lowStockOnly;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sparePartRepositoryProvider);
      if (repository == null) return const [];
      return repository.getSpareParts(
        searchQuery: _searchQuery,
        categoryFilter: _categoryFilter,
        lowStockOnly: _lowStockOnly,
      );
    });
  }

  Future<SparePart> createSparePart({
    required String sku,
    required String name,
    required String category,
    String? brand,
    String? description,
    String unit = 'pcs',
    required double unitCost,
    required double sellingPrice,
    int minimumStock = 0,
    bool isActive = true,
  }) async {
    final repository = ref.read(sparePartRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase spare part repository is unconfigured.');
    }

    final created = await repository.createSparePart(
      sku: sku,
      name: name,
      category: category,
      brand: brand,
      description: description,
      unit: unit,
      unitCost: unitCost,
      sellingPrice: sellingPrice,
      minimumStock: minimumStock,
      isActive: isActive,
    );

    ref.invalidateSelf();
    return created;
  }

  Future<SparePart> updateSparePart({
    required String id,
    String? sku,
    String? name,
    String? category,
    String? brand,
    String? description,
    String? unit,
    double? unitCost,
    double? sellingPrice,
    int? minimumStock,
    bool? isActive,
  }) async {
    final repository = ref.read(sparePartRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase spare part repository is unconfigured.');
    }

    final updated = await repository.updateSparePart(
      id: id,
      sku: sku,
      name: name,
      category: category,
      brand: brand,
      description: description,
      unit: unit,
      unitCost: unitCost,
      sellingPrice: sellingPrice,
      minimumStock: minimumStock,
      isActive: isActive,
    );

    ref.invalidateSelf();
    return updated;
  }

  Future<void> deleteSparePart(String id) async {
    final repository = ref.read(sparePartRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase spare part repository is unconfigured.');
    }

    await repository.deleteSparePart(id);
    ref.invalidateSelf();
  }
}

/// Provider exposing reactive inventory catalog.
final sparePartsProvider =
    AsyncNotifierProvider<SparePartsNotifier, List<SparePart>>(
      SparePartsNotifier.new,
    );
