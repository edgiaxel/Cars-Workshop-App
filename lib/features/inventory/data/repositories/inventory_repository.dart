import 'package:pitmate/features/inventory/data/models/inventory_transaction_model.dart';
import 'package:pitmate/features/inventory/data/models/part_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository managing catalog parts, warehouse balances, and stock movement transactions.
class InventoryRepository {
  final SupabaseClient? _client;

  InventoryRepository([SupabaseClient? client]) : _client = client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Fetches all catalog parts with live balances.
  Future<List<PartModel>> fetchParts({String? categorySearch, String? query}) async {
    var req = _supabase.from('parts').select('*, inventory_balances(*)');

    if (categorySearch != null && categorySearch.isNotEmpty && categorySearch != 'all') {
      req = req.eq('category', categorySearch);
    }
    if (query != null && query.trim().isNotEmpty) {
      req = req.or('name.ilike.%$query%,sku.ilike.%$query%');
    }

    final response = await req.order('name', ascending: true);
    return (response as List).map((row) => PartModel.fromJson(row as Map<String, dynamic>)).toList();
  }

  /// Creates a new catalog part and initializes an empty balance record.
  Future<PartModel> createPart({
    required String sku,
    required String name,
    required String category,
    required String unitOfMeasurement,
    required int purchaseCostCents,
    required int sellingPriceCents,
    required int minimumStock,
  }) async {
    final response = await _supabase.from('parts').insert({
      'sku': sku.trim().toUpperCase(),
      'name': name.trim(),
      'category': category.trim().toLowerCase(),
      'unit_of_measurement': unitOfMeasurement.trim().toLowerCase(),
      'purchase_cost_cents': purchaseCostCents,
      'selling_price_cents': sellingPriceCents,
      'minimum_stock': minimumStock,
    }).select().single();

    final partId = response['id'] as String;

    // Initialize balance
    await _supabase.from('inventory_balances').insert({
      'part_id': partId,
      'quantity_on_hand': 0,
      'quantity_reserved': 0,
    });

    return PartModel.fromJson(response);
  }

  /// Updates an existing catalog part.
  Future<void> updatePart({
    required String id,
    required String sku,
    required String name,
    required String category,
    required String unitOfMeasurement,
    required int sellingPriceCents,
    required int minimumStock,
  }) async {
    await _supabase.from('parts').update({
      'sku': sku.trim().toUpperCase(),
      'name': name.trim(),
      'category': category.trim().toLowerCase(),
      'unit_of_measurement': unitOfMeasurement.trim().toLowerCase(),
      'selling_price_cents': sellingPriceCents,
      'minimum_stock': minimumStock,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Receives physical stock from a supplier, recalculating weighted-average purchase cost.
  Future<Map<String, dynamic>> receiveStock({
    required String partId,
    required int quantity,
    required int unitCostCents,
    String? supplierRef,
    String? notes,
  }) async {
    final response = await _supabase.rpc('receive_stock', params: {
      'p_part_id': partId,
      'p_quantity': quantity,
      'p_unit_cost_cents': unitCostCents,
      'p_supplier_ref': supplierRef,
      'p_notes': notes,
    });

    return (response as Map<String, dynamic>?) ?? {};
  }

  /// Adjusts stock with a compulsory audit reason.
  Future<Map<String, dynamic>> adjustStock({
    required String partId,
    required int quantityChange,
    required String reason,
  }) async {
    final response = await _supabase.rpc('adjust_stock', params: {
      'p_part_id': partId,
      'p_quantity_change': quantityChange,
      'p_reason': reason.trim(),
    });

    return (response as Map<String, dynamic>?) ?? {};
  }

  /// Fetches chronological immutable movement ledger for a given part.
  Future<List<InventoryTransactionModel>> fetchTransactionHistory(String partId) async {
    final response = await _supabase
        .from('inventory_transactions')
        .select()
        .eq('part_id', partId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => InventoryTransactionModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
