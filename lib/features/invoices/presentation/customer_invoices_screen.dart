import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/navigation/role_navigation.dart';
import '../../../../shared/widgets/pit_card.dart';
import '../../../../shared/widgets/responsive_role_scaffold.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../data/models/invoice_model.dart';
import '../data/repositories/invoice_repository.dart';

/// Customer Invoices & Payment Portal Screen (F-015).
/// Features:
/// - Connected to live Supabase backend.
/// - Outstanding balance banner with instant action.
/// - Tabbed view: Due & Pending vs Settled History.
/// - Simulated one-click payment settlement (QRIS, Card, Bank VA).
/// - Electronic fiscal receipt view.
class CustomerInvoicesScreen extends ConsumerStatefulWidget {
  const CustomerInvoicesScreen({
    super.key,
    this.initialInvoices,
    this.repository,
    this.customerId,
  });

  final List<InvoiceModel>? initialInvoices;
  final IInvoiceRepository? repository;
  final String? customerId;

  @override
  ConsumerState<CustomerInvoicesScreen> createState() =>
      _CustomerInvoicesScreenState();
}

class _CustomerInvoicesScreenState extends ConsumerState<CustomerInvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<InvoiceModel> _invoices = [];
  String? _customerRecordId;
  String _customerName = 'Alex Pratama';

  IInvoiceRepository get _repo =>
      widget.repository ?? ref.read(invoiceRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _customerRecordId = widget.customerId;
    if (widget.initialInvoices != null && widget.initialInvoices!.isNotEmpty) {
      _invoices = List.from(widget.initialInvoices!);
    } else {
      _loadCustomerInvoices();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_customerRecordId == null) {
        final user = sb.Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final custData = await sb.Supabase.instance.client
              .from('customers')
              .select('id, full_name')
              .eq('profile_id', user.id)
              .maybeSingle();
          if (custData != null) {
            _customerRecordId = custData['id'] as String?;
            if (custData['full_name'] != null) {
              _customerName = custData['full_name'] as String;
            }
          }
        }
      }
    } catch (_) {
      // Supabase uninitialized or offline
    }

    final result = await _repo.fetchInvoices(customerId: _customerRecordId);
    if (!mounted) return;

    result.when(
      success: (data) {
        setState(() {
          _invoices = data;
          _isLoading = false;
        });
      },
      failure: (exception) {
        setState(() {
          if (widget.initialInvoices != null) {
            _invoices = List.from(widget.initialInvoices!);
          } else {
            _errorMessage = exception.message;
          }
          _isLoading = false;
        });
      },
    );
  }

  List<InvoiceModel> get _dueInvoices =>
      _invoices.where((inv) => !inv.isPaid).toList();

  List<InvoiceModel> get _paidInvoices =>
      _invoices.where((inv) => inv.isPaid).toList();

  int get _totalOutstandingDueCents =>
      _dueInvoices.fold(0, (sum, inv) => sum + inv.outstandingBalanceCents);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveRoleScaffold(
      roleTitle: 'Customer Portal',
      userName: _customerName,
      userSubtitle: 'Vehicle Owner Member',
      currentIndex: 4,
      navItems: RoleNavigation.customerNavItems,
      onNavIndexChanged: (index) => RoleNavigation.navigate(
        context,
        RoleNavigation.customerNavItems,
        index,
        currentIndex: 4,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Invoices',
          onPressed: _loadCustomerInvoices,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScreenHeader(isDark),
            const SizedBox(height: AppSpacing.space24),
            _buildOutstandingDueBanner(isDark),
            const SizedBox(height: AppSpacing.space24),
            if (_errorMessage != null) ...[
              _buildErrorBanner(isDark),
              const SizedBox(height: AppSpacing.space12),
            ],
            if (_successMessage != null) ...[
              _buildSuccessBanner(isDark),
              const SizedBox(height: AppSpacing.space12),
            ],
            _buildTabBar(isDark),
            const SizedBox(height: AppSpacing.space12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.accentRed),
                ),
              )
            else
              _buildInvoicesList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: Text(
                'CUSTOMER BILLING & SETTLEMENT',
                style: AppTypography.labelSmall(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'TAX INVOICE PPN 11%',
              style: AppTypography.telemetrySmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'INVOICES & PAYMENTS',
          style: AppTypography.headlineMedium(
            color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'View itemized repair bills, complete instant online settlements, and download official receipts.',
          style: AppTypography.bodySmall(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildOutstandingDueBanner(bool isDark) {
    final hasDue = _totalOutstandingDueCents > 0;

    return PitCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (hasDue ? AppColors.danger : AppColors.success)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasDue ? Icons.error_outline : Icons.check_circle_outline,
              color: hasDue ? AppColors.danger : AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDue ? 'TOTAL OUTSTANDING BALANCE DUE' : 'ALL INVOICES SETTLED',
                  style: AppTypography.labelSmall(
                    fontWeight: FontWeight.bold,
                    color: hasDue ? AppColors.danger : AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasDue
                      ? CurrencyFormatter.formatIdr(_totalOutstandingDueCents)
                      : 'Rp 0',
                  style: AppTypography.telemetryLarge(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                  ),
                ),
                Text(
                  hasDue
                      ? '${_dueInvoices.length} invoice(s) awaiting payment before vehicle handover.'
                      : 'No pending invoices. Your account is fully settled.',
                  style: AppTypography.bodySmall(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (hasDue && _dueInvoices.isNotEmpty)
            FilledButton.icon(
              key: const Key('btn_pay_all_or_first_due'),
              onPressed: () => _openCustomerPaymentSheet(_dueInvoices.first),
              icon: const Icon(Icons.flash_on, size: 16),
              label: const Text('PAY NOW'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return PitCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accentRed,
        labelColor: AppColors.accentRed,
        unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        labelStyle: AppTypography.labelMedium(fontWeight: FontWeight.bold),
        tabs: [
          Tab(
            key: const Key('tab_customer_due'),
            text: 'PENDING SETTLEMENT (${_dueInvoices.length})',
          ),
          Tab(
            key: const Key('tab_customer_paid'),
            text: 'SETTLED HISTORY (${_paidInvoices.length})',
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(bool isDark) {
    final list = _tabController.index == 0 ? _dueInvoices : _paidInvoices;

    if (list.isEmpty) {
      return PitCard(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              _tabController.index == 0
                  ? Icons.task_alt
                  : Icons.history,
              size: 48,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              _tabController.index == 0
                  ? 'NO PENDING INVOICES'
                  : 'NO SETTLED INVOICES YET',
              style: AppTypography.headlineSmall(
                color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              _tabController.index == 0
                  ? 'All services have been paid and settled. Thank you for choosing PitMate!'
                  : 'Completed tax invoices will appear here once service orders are finalized.',
              style: AppTypography.bodySmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space12),
      itemBuilder: (context, index) {
        final invoice = list[index];
        return _buildCustomerInvoiceCard(invoice, isDark);
      },
    );
  }

  Widget _buildCustomerInvoiceCard(InvoiceModel invoice, bool isDark) {
    return PitCard(
      key: Key('customer_invoice_card_${invoice.invoiceNumber}'),
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: AppTypography.telemetryMedium(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      invoice.isPaid
                          ? StatusBadge.success('PAID', icon: Icons.check_circle)
                          : StatusBadge.warning('PAYMENT DUE', icon: Icons.schedule),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invoice.vehiclePlate ?? 'Plate'} • ${invoice.vehicleModel ?? 'Vehicle'}',
                    style: AppTypography.bodySmall(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL AMOUNT',
                    style: AppTypography.labelSmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    invoice.formattedTotal,
                    style: AppTypography.telemetryLarge(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                    ),
                  ),
                  if (invoice.outstandingBalanceCents > 0)
                    Text(
                      'Due: ${invoice.formattedOutstanding}',
                      style: AppTypography.telemetrySmall(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),

          // Parts & Labor Summary Chips
          Row(
            children: [
              _buildCostTag('Labor', invoice.formattedLabor, isDark),
              const SizedBox(width: 8),
              _buildCostTag('Parts', invoice.formattedParts, isDark),
              const SizedBox(width: 8),
              _buildCostTag('11% PPN', invoice.formattedTax, isDark),
              if (invoice.discountCents > 0) ...[
                const SizedBox(width: 8),
                _buildCostTag('Discount', '-${invoice.formattedDiscount}', isDark,
                    color: AppColors.success),
              ],
              const Spacer(),
              Text(
                'Issued: ${invoice.createdAt.year}-${invoice.createdAt.month.toString().padLeft(2, '0')}-${invoice.createdAt.day.toString().padLeft(2, '0')}',
                style: AppTypography.telemetrySmall(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                key: Key('btn_customer_view_receipt_${invoice.invoiceNumber}'),
                onPressed: () => _openCustomerReceiptDialog(invoice),
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text('VIEW TAX RECEIPT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                ),
              ),
              if (invoice.outstandingBalanceCents > 0) ...[
                const SizedBox(width: AppSpacing.space8),
                FilledButton.icon(
                  key: Key('btn_customer_pay_now_${invoice.invoiceNumber}'),
                  onPressed: () => _openCustomerPaymentSheet(invoice),
                  icon: const Icon(Icons.credit_card, size: 16),
                  label: Text('PAY ${invoice.formattedOutstanding}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostTag(String label, String value, bool isDark, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.telemetrySmall(
          fontWeight: FontWeight.w600,
          color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.danger),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall(color: AppColors.danger),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.success),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              _successMessage!,
              style: AppTypography.bodySmall(color: AppColors.success),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.success),
            onPressed: () => setState(() => _successMessage = null),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTION: Simulated One-Click Customer Payment
  // ==========================================
  void _openCustomerPaymentSheet(InvoiceModel invoice) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _CustomerPaymentSheet(
          invoice: invoice,
          onPayConfirmed: (method, refNumber) async {
            Navigator.pop(ctx);
            setState(() => _isLoading = true);

            final result = await _repo.recordPayment(
              invoiceId: invoice.id,
              amountCents: invoice.outstandingBalanceCents,
              paymentMethod: method,
              referenceNumber: refNumber,
            );

            if (!mounted) return;
            result.when(
              success: (paymentId) async {
                setState(() {
                  _successMessage = 'Payment completed! Invoice is settled in full.';
                });
                await _loadCustomerInvoices();
                final updated = _invoices.firstWhere(
                  (inv) => inv.id == invoice.id,
                  orElse: () => invoice.copyWith(
                    status: InvoiceStatus.paid,
                    amountPaidCents: invoice.totalAmountCents,
                    outstandingBalanceCents: 0,
                  ),
                );
                if (mounted) _openCustomerReceiptDialog(updated);
              },
              failure: (exception) {
                setState(() {
                  _errorMessage = exception.message;
                  _isLoading = false;
                });
              },
            );
          },
        );
      },
    );
  }

  void _openCustomerReceiptDialog(InvoiceModel invoice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'PITMATE AUTOMOTIVE WORKSHOP',
                            style: AppTypography.headlineSmall(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.success),
                            ),
                            child: Text(
                              'ELECTRONIC TAX INVOICE',
                              style: AppTypography.labelSmall(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    _buildReceiptRow('Invoice #', invoice.invoiceNumber, isDark),
                    _buildReceiptRow('Order #', invoice.orderNumber ?? invoice.serviceOrderId, isDark),
                    _buildReceiptRow('Vehicle', '${invoice.vehiclePlate ?? ''} • ${invoice.vehicleModel ?? ''}', isDark),
                    _buildReceiptRow('Date', invoice.createdAt.toLocal().toString().substring(0, 10), isDark),
                    const Divider(height: 16),
                    _buildReceiptRow('Labor Charges', invoice.formattedLabor, isDark),
                    _buildReceiptRow('Parts & Materials', invoice.formattedParts, isDark),
                    _buildReceiptRow('PPN (11%)', invoice.formattedTax, isDark),
                    if (invoice.discountCents > 0)
                      _buildReceiptRow('Discount', '-${invoice.formattedDiscount}', isDark),
                    const Divider(height: 16),
                    _buildReceiptRow('Total Amount', invoice.formattedTotal, isDark, isBold: true),
                    _buildReceiptRow('Amount Paid', invoice.formattedAmountPaid, isDark,
                        textColor: AppColors.success, isBold: true),
                    _buildReceiptRow('Remaining Due', invoice.formattedOutstanding, isDark,
                        textColor: invoice.outstandingBalanceCents > 0
                            ? AppColors.danger
                            : AppColors.success,
                        isBold: true),
                    const SizedBox(height: AppSpacing.space16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('DONE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, bool isDark, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTypography.bodySmall(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                  )
                : AppTypography.bodySmall(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
          ),
          Text(
            value,
            style: isBold
                ? AppTypography.telemetrySmall(
                    fontWeight: FontWeight.bold,
                    color: textColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary),
                  )
                : AppTypography.telemetrySmall(
                    fontWeight: FontWeight.w600,
                    color: textColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for simulated instant payment settlement from the customer side.
class _CustomerPaymentSheet extends StatefulWidget {
  const _CustomerPaymentSheet({
    required this.invoice,
    required this.onPayConfirmed,
  });

  final InvoiceModel invoice;
  final Function(PaymentMethod method, String refNumber) onPayConfirmed;

  @override
  State<_CustomerPaymentSheet> createState() => _CustomerPaymentSheetState();
}

class _CustomerPaymentSheetState extends State<_CustomerPaymentSheet> {
  PaymentMethod _channel = PaymentMethod.qris;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, size: 20, color: AppColors.success),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  'SECURE 1-CLICK SETTLEMENT',
                  style: AppTypography.labelSmall(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Pay ${widget.invoice.formattedOutstanding}',
              style: AppTypography.headlineMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
              ),
            ),
            Text(
              'Invoice: ${widget.invoice.invoiceNumber}',
              style: AppTypography.telemetrySmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const Divider(height: 24),

            Text(
              'SELECT PAYMENT CHANNEL',
              style: AppTypography.labelSmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),

            // Channel selection cards
            _buildChannelTile(
              PaymentMethod.qris,
              'QRIS Instant Payment',
              'Scan with GoPay, OVO, BCA, Mandiri, or any mobile banking app',
              Icons.qr_code_2,
              isDark,
            ),
            const SizedBox(height: 8),
            _buildChannelTile(
              PaymentMethod.card,
              'Saved Debit / Credit Card',
              'Visa / Mastercard (•••• 4242)',
              Icons.credit_card,
              isDark,
            ),
            const SizedBox(height: 8),
            _buildChannelTile(
              PaymentMethod.bankTransfer,
              'Bank Virtual Account',
              'BCA / Mandiri / BNI Virtual Account (Instant verification)',
              Icons.account_balance,
              isDark,
            ),
            const SizedBox(height: AppSpacing.space16),

            // Channel simulation details
            if (_channel == PaymentMethod.qris)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 80, color: AppColors.graphitePrimary),
                    const SizedBox(height: 8),
                    Text(
                      'Scan dynamic QR with your e-wallet or banking app',
                      style: AppTypography.bodySmall(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.space16),

            FilledButton.icon(
              key: const Key('btn_confirm_customer_settlement'),
              onPressed: () {
                final refNum = 'SIM-CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                widget.onPayConfirmed(_channel, refNum);
              },
              icon: const Icon(Icons.check, size: 18),
              label: Text('CONFIRM PAYMENT (${widget.invoice.formattedOutstanding})'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelTile(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _channel == method;

    return InkWell(
      key: Key('channel_tile_${method.name}'),
      onTap: () => setState(() => _channel = method),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentRed.withValues(alpha: 0.1)
              : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentRed : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accentRed : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.telemetrySmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.accentRed : (isDark ? AppColors.borderDark : AppColors.borderLight),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
