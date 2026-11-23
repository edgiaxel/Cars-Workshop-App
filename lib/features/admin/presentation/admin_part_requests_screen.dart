import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/inventory/data/models/part_request_model.dart';
import 'package:pitmate/features/inventory/data/repositories/part_operations_repository.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/pit_error_dialog.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

/// Admin Part Requests Management Screen (UI-A13).
class AdminPartRequestsScreen extends ConsumerStatefulWidget {
  const AdminPartRequestsScreen({super.key});

  @override
  ConsumerState<AdminPartRequestsScreen> createState() => _AdminPartRequestsScreenState();
}

class _AdminPartRequestsScreenState extends ConsumerState<AdminPartRequestsScreen> {
  final PartOperationsRepository _opsRepo = PartOperationsRepository();
  bool _isLoading = true;
  List<PartRequestModel> _requests = [];
  String _statusFilter = 'pending';



  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final reqs = await _opsRepo.fetchRequests(status: _statusFilter);
      if (mounted) {
        setState(() {
          _requests = reqs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _requests = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onNavChanged(int index) {
    RoleNavigation.navigate(context, RoleNavigation.adminNavItems, index, currentIndex: 6);
  }

  Future<void> _fulfillRequest(PartRequestModel request, int qty) async {
    try {
      await _opsRepo.fulfillRequest(
        requestId: request.id,
        quantityToFulfill: qty,
      );
      _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issued $qty units of ${request.partSku ?? "part"} to floor.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showPitErrorDialog(
        context,
        title: 'FULFILLMENT FAILED',
        message: e.toString().replaceAll('Exception: ', ''),
        hint: 'Check warehouse on-hand stock and safety reserve quantities before issuing.',
      );
    }
  }

  Future<void> _openCustomFulfillDialog(PartRequestModel request) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtyController = TextEditingController(text: request.remainingQuantity.toString());

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'FULFILL PART REQUEST',
          style: AppTypography.headlineSmall().copyWith(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Part: ${request.partName ?? request.partSku ?? "Selected Item"}',
                style: AppTypography.labelLarge().copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Requested by: ${request.requestedByName ?? "Mechanic"}',
                style: AppTypography.bodySmall(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity to Issue (${request.partUnit ?? "pcs"})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              final qty = int.tryParse(qtyController.text.trim()) ?? 0;
              if (qty > 0) {
                Navigator.pop(ctx);
                _fulfillRequest(request, qty);
              }
            },
            child: const Text('CONFIRM ISSUE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingCount = _requests.where((r) => r.isPending).length;

    return ResponsiveRoleScaffold(
      roleTitle: 'Floor Part Coordination',
      userName: 'Toto Wolf',
      userSubtitle: 'Workshop Director',
      currentIndex: 6,
      onNavIndexChanged: _onNavChanged,
      navItems: RoleNavigation.adminNavItems,
      telemetryNotice: '$pendingCount PENDING FLOOR REQUESTS',
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Requests',
          onPressed: _loadRequests,
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Filter Row
                    Row(
                      children: [
                        Text('FILTER:', style: AppTypography.labelLarge().copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('PENDING'),
                          selected: _statusFilter == 'pending',
                          onSelected: (val) {
                            if (val) {
                              setState(() => _statusFilter = 'pending');
                              _loadRequests();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('ALL REQUESTS'),
                          selected: _statusFilter == 'all',
                          onSelected: (val) {
                            if (val) {
                              setState(() => _statusFilter = 'all');
                              _loadRequests();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_requests.isEmpty)
                      PitCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.done_all, size: 48, color: AppColors.success),
                                const SizedBox(height: 12),
                                Text('No pending floor requests at this time.', style: AppTypography.headlineSmall()),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _requests.map((r) => _buildRequestCard(r, isDark, isNarrow)).toList(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(PartRequestModel request, bool isDark, bool isNarrow) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: PitCard(
        accentBorderLeft: request.isPending
            ? AppColors.warning
            : request.isFulfilled
                ? AppColors.success
                : AppColors.info,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.handyman_outlined, size: 20, color: AppColors.accentRed),
                    const SizedBox(width: 8),
                    Text(
                      request.partSku ?? 'PART',
                      style: AppTypography.labelLarge(color: AppColors.accentRed).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                StatusBadge(
                  label: request.status.toUpperCase(),
                  color: request.isPending
                      ? AppColors.warning
                      : request.isFulfilled
                          ? AppColors.success
                          : AppColors.info,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              request.partName ?? 'Requested Item',
              style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Requested: ${request.quantityRequested} ${request.partUnit ?? "pcs"}', style: AppTypography.bodySmall()),
                Text('Fulfilled: ${request.quantityFulfilled} ${request.partUnit ?? "pcs"}',
                    style: AppTypography.bodySmall(color: AppColors.success)),
                Text(
                  'Remaining: ${request.remainingQuantity} ${request.partUnit ?? "pcs"}',
                  style: AppTypography.bodySmall().copyWith(fontWeight: FontWeight.w700, color: AppColors.warning),
                ),
              ],
            ),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Note: ${request.notes!}',
                style: AppTypography.bodySmall(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tech: ${request.requestedByName ?? "Assigned Tech"}',
                  style: AppTypography.bodySmall(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                if (request.isPending || request.isPartiallyFulfilled)
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _openCustomFulfillDialog(request),
                        child: const Text('CUSTOM QTY'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: () => _fulfillRequest(request, request.remainingQuantity),
                        child: Text('ISSUE ${request.remainingQuantity}'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
