import '../datasources/spare_part_remote_datasource.dart';
import '../models/spare_part.dart';

/// Repository interface for Spare Part management.
abstract class SparePartRepository {
  Future<List<SparePart>> getSpareParts({
    String? searchQuery,
    String? categoryFilter,
    bool? lowStockOnly,
  });
  Future<SparePart> getSparePartById(String id);
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
  });
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
  });
  Future<void> deleteSparePart(String id);
}

/// Concrete repository delegating to [SparePartRemoteDataSource].
class SupabaseSparePartRepository implements SparePartRepository {
  const SupabaseSparePartRepository(this._remoteDataSource);

  final SparePartRemoteDataSource _remoteDataSource;

  @override
  Future<List<SparePart>> getSpareParts({
    String? searchQuery,
    String? categoryFilter,
    bool? lowStockOnly,
  }) {
    return _remoteDataSource.fetchSpareParts(
      searchQuery: searchQuery,
      categoryFilter: categoryFilter,
      lowStockOnly: lowStockOnly,
    );
  }

  @override
  Future<SparePart> getSparePartById(String id) {
    return _remoteDataSource.getSparePartById(id);
  }

  @override
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
  }) {
    return _remoteDataSource.createSparePart(
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
  }

  @override
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
  }) {
    return _remoteDataSource.updateSparePart(
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
  }

  @override
  Future<void> deleteSparePart(String id) {
    return _remoteDataSource.deleteSparePart(id);
  }
}
