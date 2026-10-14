import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/spare_part.dart';

/// Contract for SparePart remote data access against Supabase.
abstract class SparePartRemoteDataSource {
  Future<List<SparePart>> fetchSpareParts({
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

/// Concrete Supabase implementation for [SparePartRemoteDataSource].
class SupabaseSparePartRemoteDataSource implements SparePartRemoteDataSource {
  const SupabaseSparePartRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SparePart>> fetchSpareParts({
    String? searchQuery,
    String? categoryFilter,
    bool? lowStockOnly,
  }) async {
    var query = _client
        .from('spare_parts')
        .select('*, inventory_transactions(quantity)');

    if (categoryFilter != null &&
        categoryFilter.isNotEmpty &&
        categoryFilter.toLowerCase() != 'all') {
      query = query.eq('category', categoryFilter);
    }

    final data = await query.order('name', ascending: true);
    var parts = (data as List)
        .map((json) => SparePart.fromJson(json as Map<String, dynamic>))
        .toList();

    if (lowStockOnly == true) {
      parts = parts.where((p) => p.isLowStock).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      parts = parts.where((p) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final skuMatch = p.sku.toLowerCase().contains(q);
        final brandMatch = p.brand?.toLowerCase().contains(q) ?? false;
        final catMatch = p.category.toLowerCase().contains(q);
        return nameMatch || skuMatch || brandMatch || catMatch;
      }).toList();
    }

    return parts;
  }

  @override
  Future<SparePart> getSparePartById(String id) async {
    final data = await _client
        .from('spare_parts')
        .select('*, inventory_transactions(quantity)')
        .eq('id', id)
        .single();
    return SparePart.fromJson(data);
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
  }) async {
    final payload = <String, dynamic>{
      'sku': sku.trim().toUpperCase(),
      'name': name.trim(),
      'category': category.trim(),
      'brand': brand?.trim(),
      'description': description?.trim(),
      'unit': unit.trim(),
      'unit_cost': unitCost,
      'selling_price': sellingPrice,
      'minimum_stock': minimumStock,
      'is_active': isActive,
    };

    final data = await _client
        .from('spare_parts')
        .insert(payload)
        .select('*, inventory_transactions(quantity)')
        .single();

    return SparePart.fromJson(data);
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
  }) async {
    final payload = <String, dynamic>{};
    if (sku != null) payload['sku'] = sku.trim().toUpperCase();
    if (name != null) payload['name'] = name.trim();
    if (category != null) payload['category'] = category.trim();
    if (brand != null) payload['brand'] = brand.trim();
    if (description != null) payload['description'] = description.trim();
    if (unit != null) payload['unit'] = unit.trim();
    if (unitCost != null) payload['unit_cost'] = unitCost;
    if (sellingPrice != null) payload['selling_price'] = sellingPrice;
    if (minimumStock != null) payload['minimum_stock'] = minimumStock;
    if (isActive != null) payload['is_active'] = isActive;

    final data = await _client
        .from('spare_parts')
        .update(payload)
        .eq('id', id)
        .select('*, inventory_transactions(quantity)')
        .single();

    return SparePart.fromJson(data);
  }

  @override
  Future<void> deleteSparePart(String id) async {
    await _client.from('spare_parts').delete().eq('id', id);
  }
}
