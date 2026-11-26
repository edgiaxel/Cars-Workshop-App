import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../models/invoice_model.dart';

/// Contract for PitMate invoicing and financial settlement operations.
abstract class IInvoiceRepository {
  Future<Result<List<InvoiceModel>>> fetchInvoices({
    String? customerId,
    InvoiceStatus? statusFilter,
  });

  Future<Result<InvoiceModel?> > fetchInvoiceById(String invoiceId);

  Future<Result<InvoiceModel?> > fetchInvoiceByOrderId(String orderId);

  Future<Result<List<InvoiceItemModel>>> fetchInvoiceItems(String invoiceId);

  Future<Result<List<PaymentModel>>> fetchInvoicePayments(String invoiceId);

  Future<Result<String>> generateInvoice({
    required String serviceOrderId,
    double taxPercent = 11.0,
    int discountCents = 0,
    int depositCents = 0,
    int insuranceCents = 0,
    String? adminId,
    String? discountReason,
  });

  Future<Result<String>> recordPayment({
    required String invoiceId,
    required int amountCents,
    required PaymentMethod paymentMethod,
    String? referenceNumber,
    int? cashTenderedCents,
    int changeCents = 0,
    String? adminId,
  });

  Future<Result<String>> recordRefund({
    required String paymentId,
    required int refundAmountCents,
    required String refundReason,
  });

  Future<Result<List<Map<String, dynamic>>>> fetchEligibleServiceOrdersForInvoice();
}

/// Supabase implementation of [IInvoiceRepository].
class InvoiceRepository implements IInvoiceRepository {
  InvoiceRepository([this._clientOverride]);

  final sb.SupabaseClient? _clientOverride;

  sb.SupabaseClient get _client {
    if (_clientOverride != null) return _clientOverride;
    return sb.Supabase.instance.client;
  }

  static const String _invoiceSelectQuery = '''
    *,
    invoice_items(*),
    payments(*),
    service_orders(
      id,
      order_number,
      vehicles(
        license_plate,
        make,
        model
      )
    ),
    customers(
      id,
      full_name,
      phone_number,
      email
    )
  ''';

  @override
  Future<Result<List<InvoiceModel>>> fetchInvoices({
    String? customerId,
    InvoiceStatus? statusFilter,
  }) async {
    try {
      dynamic query = _client.from('invoices').select(_invoiceSelectQuery);

      if (customerId != null && customerId.isNotEmpty) {
        query = query.eq('customer_id', customerId);
      }

      if (statusFilter != null) {
        query = query.eq('status', statusFilter.toDbString());
      }

      final response = await query.order('created_at', ascending: false);
      final list = (response as List)
          .map((row) => InvoiceModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return Result.success(list);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch invoices: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error while fetching invoices: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error fetching invoices: $e'),
      );
    }
  }

  @override
  Future<Result<InvoiceModel?>> fetchInvoiceById(String invoiceId) async {
    try {
      final response = await _client
          .from('invoices')
          .select(_invoiceSelectQuery)
          .eq('id', invoiceId)
          .maybeSingle();

      if (response == null) {
        return const Result.success(null);
      }

      return Result.success(InvoiceModel.fromJson(response));
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch invoice $invoiceId: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Result<InvoiceModel?>> fetchInvoiceByOrderId(String orderId) async {
    try {
      final response = await _client
          .from('invoices')
          .select(_invoiceSelectQuery)
          .eq('service_order_id', orderId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return const Result.success(null);
      }

      return Result.success(InvoiceModel.fromJson(response));
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch invoice for order $orderId: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Result<List<InvoiceItemModel>>> fetchInvoiceItems(String invoiceId) async {
    try {
      final response = await _client
          .from('invoice_items')
          .select()
          .eq('invoice_id', invoiceId)
          .order('created_at', ascending: true);

      final items = (response as List)
          .map((row) => InvoiceItemModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return Result.success(items);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to load invoice items: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Result<List<PaymentModel>>> fetchInvoicePayments(String invoiceId) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('invoice_id', invoiceId)
          .order('created_at', ascending: false);

      final payments = (response as List)
          .map((row) => PaymentModel.fromJson(row as Map<String, dynamic>))
          .toList();

      return Result.success(payments);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to load invoice payments: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Result<String>> generateInvoice({
    required String serviceOrderId,
    double taxPercent = 11.0,
    int discountCents = 0,
    int depositCents = 0,
    int insuranceCents = 0,
    String? adminId,
    String? discountReason,
  }) async {
    try {
      final effectiveAdminId = adminId ?? _client.auth.currentUser?.id;

      final result = await _client.rpc(
        'generate_service_order_invoice',
        params: {
          'p_service_order_id': serviceOrderId,
          'p_tax_percent': taxPercent,
          'p_discount_cents': discountCents,
          'p_deposit_cents': depositCents,
          'p_insurance_cents': insuranceCents,
          'p_admin_id': effectiveAdminId,
          'p_discount_reason': discountReason,
        },
      );

      final invoiceId = result.toString();
      return Result.success(invoiceId);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Database error generating invoice: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error generating invoice: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to generate invoice: $e'),
      );
    }
  }

  @override
  Future<Result<String>> recordPayment({
    required String invoiceId,
    required int amountCents,
    required PaymentMethod paymentMethod,
    String? referenceNumber,
    int? cashTenderedCents,
    int changeCents = 0,
    String? adminId,
  }) async {
    try {
      final effectiveAdminId = adminId ?? _client.auth.currentUser?.id;

      final result = await _client.rpc(
        'record_invoice_payment',
        params: {
          'p_invoice_id': invoiceId,
          'p_amount_cents': amountCents,
          'p_payment_method': paymentMethod.toDbString(),
          'p_reference_number': referenceNumber,
          'p_cash_tendered_cents': cashTenderedCents,
          'p_change_cents': changeCents,
          'p_admin_id': effectiveAdminId,
        },
      );

      final paymentId = result.toString();
      return Result.success(paymentId);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Database error recording payment: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error recording payment: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to record payment: $e'),
      );
    }
  }

  @override
  Future<Result<String>> recordRefund({
    required String paymentId,
    required int refundAmountCents,
    required String refundReason,
  }) async {
    try {
      final result = await _client.rpc(
        'record_invoice_refund',
        params: {
          'p_payment_id': paymentId,
          'p_refund_amount_cents': refundAmountCents,
          'p_refund_reason': refundReason,
        },
      );

      return Result.success(result.toString());
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Database error recording refund: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error recording refund: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Failed to record refund: $e'),
      );
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> fetchEligibleServiceOrdersForInvoice() async {
    try {
      final response = await _client
          .from('service_orders')
          .select('''
            id,
            order_number,
            status,
            created_at,
            customer_id,
            customers(
              full_name,
              phone_number
            ),
            vehicles(
              license_plate,
              make,
              model
            ),
            invoices(
              id,
              status
            )
          ''')
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      final rows = (response as List).cast<Map<String, dynamic>>().where((row) {
        final existingInvoices = (row['invoices'] as List?) ?? [];
        return !existingInvoices.any((inv) => (inv as Map)['status'] != 'cancelled');
      }).toList();
      return Result.success(rows);
    } on sb.PostgrestException catch (e) {
      return Result.failure(
        DatabaseException('Failed to fetch eligible orders: ${e.message}', code: e.code),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}'),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException('Unexpected error: $e'),
      );
    }
  }
}

/// Global Riverpod provider for [IInvoiceRepository].
final invoiceRepositoryProvider = Provider<IInvoiceRepository>((ref) {
  return InvoiceRepository();
});
