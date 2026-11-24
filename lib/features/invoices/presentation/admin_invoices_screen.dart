import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Workshop Admin Invoices & Financial Settlement Screen (F-015).
/// Features:
/// - Real Supabase queries and RPC mutations.
/// - Filter tabs (All, Issued/Unpaid, Paid).
/// - Comprehensive parts/labor breakdown, 11% PPN calculation, discounts, deposits.
/// - Payment settlement modal with cash change calculator and simulated QRIS/Card/Bank channels.
/// - Digital receipt modal with full tax invoice telemetry.
class AdminInvoicesScreen extends ConsumerStatefulWidget {
  const AdminInvoicesScreen({
    super.key,
    this.initialInvoices,
    this.repository,
  });

  final List<InvoiceModel>? initialInvoices;
  final IInvoiceRepository? repository;

  @override
  ConsumerState<AdminInvoicesScreen> createState() => _AdminInvoicesScreenState();
}

class _AdminInvoicesScreenState extends ConsumerState<AdminInvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<InvoiceModel> _invoices = [];
  String _searchQuery = '';

  IInvoiceRepository get _repo =>
      widget.repository ?? ref.read(invoiceRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.initialInvoices != null && widget.initialInvoices!.isNotEmpty) {
      _invoices = List.from(widget.initialInvoices!);
    } else {
      _loadInvoices();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repo.fetchInvoices();
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

  List<InvoiceModel> get _filteredInvoices {
    final query = _searchQuery.trim().toLowerCase();
    List<InvoiceModel> list = _invoices;

    // Filter by tab
    if (_tabController.index == 1) {
      // Issued / Unpaid / Partially Paid
      list = list.where((inv) => !inv.isPaid).toList();
    } else if (_tabController.index == 2) {
      // Settled / Paid
      list = list.where((inv) => inv.isPaid).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      list = list.where((inv) {
        final number = inv.invoiceNumber.toLowerCase();
        final cust = (inv.customerName ?? '').toLowerCase();
        final plate = (inv.vehiclePlate ?? '').toLowerCase();
        final order = (inv.orderNumber ?? '').toLowerCase();
        return number.contains(query) ||
            cust.contains(query) ||
            plate.contains(query) ||
            order.contains(query);
      }).toList();
    }

    return list;
  }

  // Summary Metrics
  int get _totalSettledRevenueCents => _invoices.fold(
      0, (sum, inv) => sum + (inv.amountPaidCents > 0 ? inv.amountPaidCents : 0));

  int get _totalOutstandingCents => _invoices.fold(
      0, (sum, inv) => sum + (inv.outstandingBalanceCents > 0 ? inv.outstandingBalanceCents : 0));

  int get _totalTaxCollectedCents => _invoices.fold(
      0, (sum, inv) => sum + (inv.isPaid ? inv.taxAmountCents : 0));

  int get _unpaidInvoicesCount => _invoices.where((inv) => !inv.isPaid).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveRoleScaffold(
      roleTitle: 'Workshop Admin',
      userName: 'Marcus T.',
      userSubtitle: 'Finance & Operations',
      currentIndex: 9,
      navItems: RoleNavigation.adminNavItems,
      onNavIndexChanged: (index) => RoleNavigation.navigate(
        context,
        RoleNavigation.adminNavItems,
        index,
        currentIndex: 9,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Invoices',
          onPressed: _loadInvoices,
        ),
        FilledButton.icon(
          key: const Key('btn_open_generate_invoice'),
          onPressed: _openGenerateInvoiceDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('GENERATE INVOICE'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentRed,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScreenHeader(isDark),
            const SizedBox(height: AppSpacing.space24),
            _buildMetricsOverview(isDark),
            const SizedBox(height: AppSpacing.space24),
            if (_errorMessage != null) ...[
              _buildErrorBanner(isDark),
              const SizedBox(height: AppSpacing.space12),
            ],
            if (_successMessage != null) ...[
              _buildSuccessBanner(isDark),
              const SizedBox(height: AppSpacing.space12),
            ],
            _buildFilterAndSearchControls(isDark),
            const SizedBox(height: AppSpacing.space12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.accentRed),
                ),
              )
            else if (_filteredInvoices.isEmpty)
              _buildEmptyState(isDark)
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
                color: AppColors.accentRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.4)),
              ),
              child: Text(
                'FINANCIAL SETTLEMENT',
                style: AppTypography.labelSmall(
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'TAX RATE: 11% PPN STANDARD',
              style: AppTypography.telemetrySmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'INVOICES & SETTLEMENT',
          style: AppTypography.headlineMedium(
            color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'Manage workshop service billing, multi-channel payment settlement, and tax receipt records.',
          style: AppTypography.bodySmall(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsOverview(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;
        final children = [
          _buildMetricCard(
            title: 'SETTLED REVENUE',
            value: CurrencyFormatter.formatIdr(_totalSettledRevenueCents),
            subtitle: 'Realized workshop turnover',
            icon: Icons.payments,
            accentColor: AppColors.success,
            isDark: isDark,
          ),
          _buildMetricCard(
            title: 'OUTSTANDING BALANCE',
            value: CurrencyFormatter.formatIdr(_totalOutstandingCents),
            subtitle: '$_unpaidInvoicesCount pending settlement',
            icon: Icons.pending_actions,
            accentColor: AppColors.warning,
            isDark: isDark,
          ),
          _buildMetricCard(
            title: '11% PPN TAX COLLECTED',
            value: CurrencyFormatter.formatIdr(_totalTaxCollectedCents),
            subtitle: 'Compliant tax withholdings',
            icon: Icons.account_balance,
            accentColor: AppColors.info,
            isDark: isDark,
          ),
          _buildMetricCard(
            title: 'TOTAL INVOICES',
            value: '${_invoices.length}',
            subtitle: '${_invoices.where((i) => i.isPaid).length} settled / ${_invoices.length}',
            icon: Icons.receipt_long,
            accentColor: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
            isDark: isDark,
          ),
        ];

        if (isMobile) {
          return Column(
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                      child: child,
                    ))
                .toList(),
          );
        }

        return Row(
          children: children
              .map((card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: card,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return PitCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelSmall(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            value,
            style: AppTypography.telemetryLarge(
              color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            subtitle,
            style: AppTypography.bodySmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchControls(bool isDark) {
    return PitCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.accentRed,
              labelColor: AppColors.accentRed,
              unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              labelStyle: AppTypography.labelMedium(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'ALL INVOICES (${_invoices.length})'),
                Tab(text: 'ISSUED & UNPAID ($_unpaidInvoicesCount)'),
                Tab(text: 'PAID & SETTLED (${_invoices.where((i) => i.isPaid).length})'),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 40,
              child: TextField(
                key: const Key('input_search_invoices'),
                onChanged: (val) => setState(() => _searchQuery = val),
                style: AppTypography.bodySmall(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  hintText: 'Search invoice, customer, plate...',
                  hintStyle: AppTypography.bodySmall(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredInvoices.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space12),
      itemBuilder: (context, index) {
        final invoice = _filteredInvoices[index];
        return _buildInvoiceCard(invoice, isDark, index);
      },
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice, bool isDark, int index) {
    final statusBadge = _buildStatusBadge(invoice.status);

    return PitCard(
      key: Key('invoice_card_${invoice.invoiceNumber}'),
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Invoice Number, Order, Status
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
                      statusBadge,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order: ${invoice.orderNumber ?? invoice.serviceOrderId.substring(0, 8)} • '
                    'Date: ${invoice.createdAt.year}-${invoice.createdAt.month.toString().padLeft(2, '0')}-${invoice.createdAt.day.toString().padLeft(2, '0')}',
                    style: AppTypography.telemetrySmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Grand Total & Outstanding Balance Highlight
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
                      'Balance: ${invoice.formattedOutstanding}',
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

          // Customer and Vehicle Telemetry + Breakdown
          LayoutBuilder(
            builder: (context, cardConstraints) {
              final isNarrow = cardConstraints.maxWidth < 650;
              final custInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CUSTOMER & VEHICLE',
                    style: AppTypography.labelSmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invoice.customerName ?? 'Walk-in Customer'} • ${invoice.customerPhone ?? 'No phone'}',
                    style: AppTypography.bodySmall(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                    ),
                  ),
                  Text(
                    '${invoice.vehiclePlate ?? 'NO PLATE'} • ${invoice.vehicleModel ?? 'Vehicle'}',
                    style: AppTypography.telemetrySmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              );

              final pills = Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildFinancialPill('LABOR', invoice.formattedLabor, isDark),
                  _buildFinancialPill('PARTS', invoice.formattedParts, isDark),
                  _buildFinancialPill('11% PPN', invoice.formattedTax, isDark),
                  if (invoice.discountCents > 0)
                    _buildFinancialPill('DISCOUNT', '-${invoice.formattedDiscount}', isDark,
                        textColor: AppColors.success),
                  if (invoice.depositAppliedCents > 0)
                    _buildFinancialPill('DEPOSIT', '-${invoice.formattedDeposit}', isDark),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    custInfo,
                    const SizedBox(height: AppSpacing.space12),
                    pills,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: custInfo),
                  const SizedBox(width: AppSpacing.space12),
                  pills,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.space12),

          // Bottom Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                key: Key('btn_breakdown_${invoice.invoiceNumber}'),
                onPressed: () => _openBreakdownModal(invoice),
                icon: const Icon(Icons.receipt, size: 16),
                label: const Text('ITEMS & BREAKDOWN'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              if (invoice.amountPaidCents > 0 || invoice.isPaid)
                OutlinedButton.icon(
                  key: Key('btn_receipt_${invoice.invoiceNumber}'),
                  onPressed: () => _openDigitalReceiptDialog(invoice),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('DIGITAL RECEIPT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                  ),
                ),
              if (invoice.outstandingBalanceCents > 0) ...[
                const SizedBox(width: AppSpacing.space8),
                FilledButton.icon(
                  key: Key('btn_record_payment_${invoice.invoiceNumber}'),
                  onPressed: () => _openPaymentModal(invoice),
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('RECORD PAYMENT'),
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

  Widget _buildFinancialPill(String label, String value, bool isDark, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: AppTypography.telemetrySmall(
              fontWeight: FontWeight.bold,
              color: textColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return StatusBadge.success(status.displayName, icon: Icons.check_circle);
      case InvoiceStatus.partiallyPaid:
        return StatusBadge.warning(status.displayName, icon: Icons.pie_chart);
      case InvoiceStatus.issued:
        return StatusBadge.info(status.displayName, icon: Icons.outbox);
      case InvoiceStatus.draft:
        return StatusBadge(label: status.displayName, type: StatusBadgeType.neutral);
      case InvoiceStatus.cancelled:
        return StatusBadge.danger(status.displayName, icon: Icons.cancel);
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return PitCard(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: AppSpacing.space12),
          Text(
            'NO INVOICES MATCHING CURRENT FILTER',
            style: AppTypography.headlineSmall(
              color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Generate a new service order invoice or adjust your search filter criteria.',
            style: AppTypography.bodySmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
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
  // ACTION: Itemized Breakdown Bottom Sheet
  // ==========================================
  void _openBreakdownModal(InvoiceModel invoice) async {
    List<InvoiceItemModel> items = invoice.items;
    if (items.isEmpty) {
      final itemsResult = await _repo.fetchInvoiceItems(invoice.id);
      if (itemsResult.isSuccess && mounted) {
        items = itemsResult.dataOrNull ?? [];
      }
    }

    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      Text(
                        'INVOICE ITEMIZED BREAKDOWN',
                        style: AppTypography.headlineSmall(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    '${invoice.invoiceNumber} • ${invoice.customerName ?? 'Customer'}',
                    style: AppTypography.telemetrySmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const Divider(height: 24),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No line items found for this invoice.',
                          style: AppTypography.bodySmall(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    )
                  else
                    ...items.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.itemType == InvoiceItemType.labor
                                    ? AppColors.info.withValues(alpha: 0.2)
                                    : AppColors.accentRed.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.itemType.displayName.toUpperCase(),
                                style: AppTypography.labelSmall(
                                  fontWeight: FontWeight.bold,
                                  color: item.itemType == InvoiceItemType.labor
                                      ? AppColors.info
                                      : AppColors.accentRed,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description,
                                    style: AppTypography.bodySmall(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity} × ${CurrencyFormatter.formatIdr(item.unitPriceCents)}',
                                    style: AppTypography.telemetrySmall(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatIdr(item.totalPriceCents),
                              style: AppTypography.telemetrySmall(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: AppSpacing.space12),
                  // Financial Summary Recap
                  PitCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildRecapRow('Labor Subtotal', invoice.formattedLabor, isDark),
                        _buildRecapRow('Parts Subtotal', invoice.formattedParts, isDark),
                        if (invoice.discountCents > 0)
                          _buildRecapRow('Discount Applied', '-${invoice.formattedDiscount}', isDark,
                              textColor: AppColors.success),
                        _buildRecapRow('Taxable Subtotal', invoice.formattedTaxableSubtotal, isDark),
                        _buildRecapRow('PPN (11%)', invoice.formattedTax, isDark),
                        if (invoice.depositAppliedCents > 0)
                          _buildRecapRow('Deposit Credited', '-${invoice.formattedDeposit}', isDark),
                        if (invoice.insuranceCoverageCents > 0)
                          _buildRecapRow('Insurance Coverage', '-${invoice.formattedInsurance}', isDark),
                        const Divider(),
                        _buildRecapRow('Total Invoice', invoice.formattedTotal, isDark, isBold: true),
                        _buildRecapRow('Total Paid', invoice.formattedAmountPaid, isDark,
                            textColor: AppColors.success),
                        _buildRecapRow('Outstanding Balance', invoice.formattedOutstanding, isDark,
                            textColor: invoice.outstandingBalanceCents > 0
                                ? AppColors.danger
                                : AppColors.success,
                            isBold: true),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecapRow(String title, String amount, bool isDark, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
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
            amount,
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

  // ==========================================
  // ACTION: Record Payment Modal with Cash Calc
  // ==========================================
  void _openPaymentModal(InvoiceModel invoice) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PaymentSettlementDialog(
        invoice: invoice,
        onPaymentRecorded: (amountCents, method, refNumber, cashTendered, change) async {
          Navigator.pop(ctx);
          setState(() => _isLoading = true);

          final result = await _repo.recordPayment(
            invoiceId: invoice.id,
            amountCents: amountCents,
            paymentMethod: method,
            referenceNumber: refNumber,
            cashTenderedCents: cashTendered,
            changeCents: change,
          );

          if (!mounted) return;
          result.when(
            success: (paymentId) async {
              setState(() {
                _successMessage = 'Payment settled successfully ($paymentId).';
              });
              await _loadInvoices();
              final updated = _invoices.firstWhere(
                (inv) => inv.id == invoice.id,
                orElse: () => invoice.copyWith(
                  status: InvoiceStatus.paid,
                  amountPaidCents: invoice.totalAmountCents,
                  outstandingBalanceCents: 0,
                ),
              );
              if (mounted) _openDigitalReceiptDialog(updated);
            },
            failure: (exception) {
              setState(() {
                _errorMessage = exception.message;
                _isLoading = false;
              });
            },
          );
        },
      ),
    );
  }

  // ==========================================
  // ACTION: Digital Receipt Modal
  // ==========================================
  void _openDigitalReceiptDialog(InvoiceModel invoice) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _DigitalReceiptDialog(invoice: invoice),
    );
  }

  // ==========================================
  // ACTION: Generate Service Order Invoice Dialog
  // ==========================================
  void _openGenerateInvoiceDialog() async {
    setState(() => _isLoading = true);
    final eligibleOrdersResult = await _repo.fetchEligibleServiceOrdersForInvoice();
    if (!mounted) return;
    setState(() => _isLoading = false);

    final eligibleOrders = eligibleOrdersResult.dataOrNull ?? [];

    showDialog<void>(
      context: context,
      builder: (ctx) => _GenerateInvoiceDialog(
        eligibleOrders: eligibleOrders,
        onGenerate: (serviceOrderId, taxPercent, discountCents, depositCents, insuranceCents) async {
          Navigator.pop(ctx);
          setState(() => _isLoading = true);

          final res = await _repo.generateInvoice(
            serviceOrderId: serviceOrderId,
            taxPercent: taxPercent,
            discountCents: discountCents,
            depositCents: depositCents,
            insuranceCents: insuranceCents,
          );

          if (!mounted) return;
          res.when(
            success: (invoiceId) {
              setState(() {
                _successMessage = 'Invoice generated successfully ($invoiceId).';
              });
              _loadInvoices();
            },
            failure: (exception) {
              setState(() {
                _errorMessage = exception.message;
                _isLoading = false;
              });
            },
          );
        },
      ),
    );
  }
}

/// Modal dialog for recording invoice payment with multi-channel and cash change calculator.
class _PaymentSettlementDialog extends StatefulWidget {
  const _PaymentSettlementDialog({
    required this.invoice,
    required this.onPaymentRecorded,
  });

  final InvoiceModel invoice;
  final Function(
    int amountCents,
    PaymentMethod method,
    String? referenceNumber,
    int? cashTenderedCents,
    int changeCents,
  ) onPaymentRecorded;

  @override
  State<_PaymentSettlementDialog> createState() => _PaymentSettlementDialogState();
}

class _PaymentSettlementDialogState extends State<_PaymentSettlementDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  late TextEditingController _amountController;
  late TextEditingController _cashTenderedController;
  late TextEditingController _refController;

  int _amountToPayCents = 0;
  int _cashTenderedCents = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountToPayCents = widget.invoice.outstandingBalanceCents > 0
        ? widget.invoice.outstandingBalanceCents
        : widget.invoice.totalAmountCents;

    _amountController = TextEditingController(
      text: CurrencyFormatter.centsToIdr(_amountToPayCents).toString(),
    );

    _cashTenderedCents = _amountToPayCents;
    _cashTenderedController = TextEditingController(
      text: CurrencyFormatter.centsToIdr(_cashTenderedCents).toString(),
    );

    _refController = TextEditingController(
      text: 'SIM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cashTenderedController.dispose();
    _refController.dispose();
    super.dispose();
  }

  int get _calculatedChangeCents =>
      InvoiceModel.calculateCashChange(_cashTenderedCents, _amountToPayCents);

  void _onAmountChanged(String val) {
    final rupiah = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _amountToPayCents = CurrencyFormatter.idrToCents(rupiah);
      _validate();
    });
  }

  void _onCashTenderedChanged(String val) {
    final rupiah = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _cashTenderedCents = CurrencyFormatter.idrToCents(rupiah);
      _validate();
    });
  }

  void _validate() {
    if (_amountToPayCents <= 0) {
      _error = 'Payment amount must be greater than zero.';
    } else if (_amountToPayCents > widget.invoice.outstandingBalanceCents &&
        widget.invoice.outstandingBalanceCents > 0) {
      _error = 'Amount exceeds outstanding balance.';
    } else if (_selectedMethod == PaymentMethod.cash &&
        _cashTenderedCents < _amountToPayCents) {
      _error = 'Cash tendered is less than amount to pay.';
    } else {
      _error = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.point_of_sale, color: AppColors.success),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FINANCIAL SETTLEMENT',
                            style: AppTypography.labelSmall(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.invoice.invoiceNumber,
                            style: AppTypography.headlineSmall(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Outstanding Balance Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Outstanding Due:',
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        widget.invoice.formattedOutstanding,
                        style: AppTypography.telemetryMedium(
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),

                // Payment Method Selector
                Text(
                  'SELECT SETTLEMENT METHOD',
                  style: AppTypography.labelSmall(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PaymentMethod.values.map((method) {
                    final isSelected = _selectedMethod == method;
                    return ChoiceChip(
                      key: Key('chip_payment_${method.name}'),
                      label: Text(method.displayName),
                      selected: isSelected,
                      selectedColor: AppColors.accentRed.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentRed : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      labelStyle: AppTypography.bodySmall(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppColors.accentRed
                            : (isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedMethod = method;
                            _validate();
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.space12),

                // Amount to settle input
                Text(
                  'AMOUNT TO SETTLE (IDR)',
                  style: AppTypography.labelSmall(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                TextField(
                  key: const Key('input_payment_amount'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _onAmountChanged,
                  style: AppTypography.telemetryMedium(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                  ),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),

                // Cash specific: Cash Tendered & Change Calculator
                if (_selectedMethod == PaymentMethod.cash) ...[
                  Text(
                    'CASH TENDERED (IDR)',
                    style: AppTypography.labelSmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  TextField(
                    key: const Key('input_cash_tendered'),
                    controller: _cashTenderedController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _onCashTenderedChanged,
                    style: AppTypography.telemetryMedium(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  // Quick cash chips
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildQuickCashChip('Exact', _amountToPayCents),
                      _buildQuickCashChip('+50k', _amountToPayCents + CurrencyFormatter.idrToCents(50000)),
                      _buildQuickCashChip('+100k', _amountToPayCents + CurrencyFormatter.idrToCents(100000)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  // Live Change Display Card
                  Container(
                    key: const Key('card_cash_change'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _calculatedChangeCents >= 0
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _calculatedChangeCents >= 0
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CHANGE TO CUSTOMER:',
                          style: AppTypography.labelSmall(
                            fontWeight: FontWeight.bold,
                            color: _calculatedChangeCents >= 0
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatIdr(_calculatedChangeCents),
                          style: AppTypography.telemetryMedium(
                            fontWeight: FontWeight.bold,
                            color: _calculatedChangeCents >= 0
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // QRIS / Card / Bank simulated details
                  Text(
                    'PAYMENT REFERENCE / TRACE NO.',
                    style: AppTypography.labelSmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  TextField(
                    key: const Key('input_payment_reference'),
                    controller: _refController,
                    style: AppTypography.telemetrySmall(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.info, size: 18),
                        const SizedBox(width: AppSpacing.space8),
                        Expanded(
                          child: Text(
                            _selectedMethod == PaymentMethod.qris
                                ? 'Simulated dynamic QRIS code generated. Scan with customer mobile banking app.'
                                : 'Simulated EDC payment gateway approved transaction.',
                            style: AppTypography.bodySmall(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    _error!,
                    style: AppTypography.bodySmall(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: AppSpacing.space16),

                // Submit Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    FilledButton.icon(
                      key: const Key('btn_confirm_payment_settlement'),
                      onPressed: _error == null && _amountToPayCents > 0
                          ? () {
                              widget.onPaymentRecorded(
                                _amountToPayCents,
                                _selectedMethod,
                                _refController.text.trim(),
                                _selectedMethod == PaymentMethod.cash ? _cashTenderedCents : null,
                                _selectedMethod == PaymentMethod.cash ? _calculatedChangeCents : 0,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('CONFIRM SETTLEMENT'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashChip(String label, int cents) {
    return ActionChip(
      label: Text(
        '$label (${CurrencyFormatter.formatIdr(cents)})',
        style: const TextStyle(fontSize: 11),
      ),
      onPressed: () {
        setState(() {
          _cashTenderedCents = cents;
          _cashTenderedController.text = CurrencyFormatter.centsToIdr(cents).toString();
          _validate();
        });
      },
    );
  }
}

/// Official printable motorsport digital receipt dialog.
class _DigitalReceiptDialog extends StatelessWidget {
  const _DigitalReceiptDialog({required this.invoice});

  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Workshop Tax Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        'PITMATE PERFORMANCE WORKSHOP',
                        style: AppTypography.headlineSmall(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                        ),
                      ),
                      Text(
                        'JL. AUTOMOTIVE NO. 42, JAKARTA SELATAN • NPWP: 01.234.567.8-012.000',
                        style: AppTypography.telemetrySmall(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Text(
                          'OFFICIAL TAX INVOICE & RECEIPT',
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

                // Invoice Telemetry
                _buildReceiptRow('Invoice Number', invoice.invoiceNumber, isDark),
                _buildReceiptRow('Service Order', invoice.orderNumber ?? invoice.serviceOrderId, isDark),
                _buildReceiptRow('Date & Time', invoice.createdAt.toLocal().toString().substring(0, 19), isDark),
                _buildReceiptRow('Customer', invoice.customerName ?? 'Walk-in Customer', isDark),
                _buildReceiptRow('Vehicle License', invoice.vehiclePlate ?? 'N/A', isDark),
                _buildReceiptRow('Vehicle Model', invoice.vehicleModel ?? 'Vehicle', isDark),
                const Divider(height: 20),

                // Financial Line Items
                Text(
                  'FINANCIAL SUMMARY',
                  style: AppTypography.labelSmall(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                _buildReceiptRow('Labor Subtotal', invoice.formattedLabor, isDark),
                _buildReceiptRow('Parts Subtotal', invoice.formattedParts, isDark),
                if (invoice.discountCents > 0)
                  _buildReceiptRow('Promotional Discount', '-${invoice.formattedDiscount}', isDark),
                _buildReceiptRow('11% PPN Tax', invoice.formattedTax, isDark),
                if (invoice.depositAppliedCents > 0)
                  _buildReceiptRow('Deposit Applied', '-${invoice.formattedDeposit}', isDark),
                const Divider(height: 16),
                _buildReceiptRow('GRAND TOTAL', invoice.formattedTotal, isDark, isBold: true),
                _buildReceiptRow('AMOUNT PAID', invoice.formattedAmountPaid, isDark, isBold: true),
                _buildReceiptRow('BALANCE DUE', invoice.formattedOutstanding, isDark,
                    isBold: true,
                    textColor: invoice.outstandingBalanceCents > 0
                        ? AppColors.danger
                        : AppColors.success),
                const SizedBox(height: AppSpacing.space16),

                // Motorsport Verification Stamp
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: AppColors.success, size: 28),
                      const SizedBox(width: AppSpacing.space8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.isPaid ? 'PAYMENT STATUS: SETTLED IN FULL' : 'PAYMENT STATUS: PARTIALLY SETTLED',
                              style: AppTypography.labelSmall(
                                fontWeight: FontWeight.bold,
                                color: invoice.isPaid ? AppColors.success : AppColors.warning,
                              ),
                            ),
                            Text(
                              'Valid electronic fiscal receipt verified by PitMate workshop ledger.',
                              style: AppTypography.bodySmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Dialog Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Simulated printing tax receipt...')),
                        );
                      },
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('PRINT'),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CLOSE'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

/// Dialog for generating a new service order invoice with 11% PPN and adjustments.
class _GenerateInvoiceDialog extends StatefulWidget {
  const _GenerateInvoiceDialog({
    required this.eligibleOrders,
    required this.onGenerate,
  });

  final List<Map<String, dynamic>> eligibleOrders;
  final Function(
    String serviceOrderId,
    double taxPercent,
    int discountCents,
    int depositCents,
    int insuranceCents,
  ) onGenerate;

  @override
  State<_GenerateInvoiceDialog> createState() => _GenerateInvoiceDialogState();
}

class _GenerateInvoiceDialogState extends State<_GenerateInvoiceDialog> {
  String? _selectedOrderId;
  final double _taxPercent = 11.0;
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _depositController = TextEditingController(text: '0');
  final TextEditingController _insuranceController = TextEditingController(text: '0');
  final TextEditingController _manualOrderIdController = TextEditingController();

  int _discountCents = 0;
  int _depositCents = 0;
  int _insuranceCents = 0;

  @override
  void initState() {
    super.initState();
    if (widget.eligibleOrders.isNotEmpty) {
      _selectedOrderId = widget.eligibleOrders.first['id'] as String?;
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _depositController.dispose();
    _insuranceController.dispose();
    _manualOrderIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt, color: AppColors.accentRed),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      'GENERATE SERVICE INVOICE',
                      style: AppTypography.headlineSmall(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),

                Text(
                  'SELECT SERVICE ORDER',
                  style: AppTypography.labelSmall(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                if (widget.eligibleOrders.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    key: const Key('dropdown_service_order'),
                    initialValue: _selectedOrderId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    items: widget.eligibleOrders.map((order) {
                      final orderNum = order['order_number'] as String? ?? 'SO-UNKNOWN';
                      final customer = (order['customers'] as Map?)?['full_name'] as String? ?? 'Customer';
                      final plate = (order['vehicles'] as Map?)?['license_plate'] as String? ?? '';
                      return DropdownMenuItem<String>(
                        value: order['id'] as String,
                        child: Text(
                          '$orderNum • $customer ($plate)',
                          style: AppTypography.bodySmall(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedOrderId = val),
                  ),
                ] else ...[
                  TextField(
                    key: const Key('input_manual_service_order_id'),
                    controller: _manualOrderIdController,
                    decoration: InputDecoration(
                      hintText: 'Enter Service Order UUID',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space12),

                // Tax percentage
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PPN TAX (%)',
                            style: AppTypography.labelSmall(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '$_taxPercent% (STANDARD)',
                                  style: AppTypography.telemetrySmall(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DISCOUNT (IDR)',
                            style: AppTypography.labelSmall(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            key: const Key('input_invoice_discount'),
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (val) {
                              final idr = int.tryParse(val) ?? 0;
                              setState(() => _discountCents = CurrencyFormatter.idrToCents(idr));
                            },
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEPOSIT CREDITED (IDR)',
                            style: AppTypography.labelSmall(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            key: const Key('input_invoice_deposit'),
                            controller: _depositController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (val) {
                              final idr = int.tryParse(val) ?? 0;
                              setState(() => _depositCents = CurrencyFormatter.idrToCents(idr));
                            },
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INSURANCE (IDR)',
                            style: AppTypography.labelSmall(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            key: const Key('input_invoice_insurance'),
                            controller: _insuranceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (val) {
                              final idr = int.tryParse(val) ?? 0;
                              setState(() => _insuranceCents = CurrencyFormatter.idrToCents(idr));
                            },
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    FilledButton.icon(
                      key: const Key('btn_confirm_generate_invoice'),
                      onPressed: () {
                        final orderId = _selectedOrderId ?? _manualOrderIdController.text.trim();
                        if (orderId.isNotEmpty) {
                          widget.onGenerate(
                            orderId,
                            _taxPercent,
                            _discountCents,
                            _depositCents,
                            _insuranceCents,
                          );
                        }
                      },
                      icon: const Icon(Icons.create, size: 18),
                      label: const Text('CREATE INVOICE'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
