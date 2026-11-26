import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/estimates/data/models/estimate_authorization_model.dart';
import 'package:pitmate/features/estimates/data/models/estimate_item_model.dart';
import 'package:pitmate/features/estimates/data/models/estimate_model.dart';
import 'package:pitmate/features/estimates/data/repositories/estimate_repository.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Customer Estimate Approval Screen (UI-C08).
/// Loads estimates from Supabase and records per-item authorization via
/// `authorize_estimate_items` so invoice generation computes approved items accurately.
class CustomerEstimateApprovalScreen extends ConsumerStatefulWidget {
  const CustomerEstimateApprovalScreen({
    super.key,
    this.estimateId,
    this.serviceOrderId,
    this.initialEstimate,
    this.initialItems,
    this.initialVehicleName,
    this.initialLicensePlate,
    this.initialOrderNumber,
  });

  final String? estimateId;
  final String? serviceOrderId;
  final EstimateModel? initialEstimate;
  final List<EstimateItemModel>? initialItems;
  final String? initialVehicleName;
  final String? initialLicensePlate;
  final String? initialOrderNumber;

  @override
  ConsumerState<CustomerEstimateApprovalScreen> createState() =>
      _CustomerEstimateApprovalScreenState();
}

class _CustomerEstimateApprovalScreenState
    extends ConsumerState<CustomerEstimateApprovalScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  String _vehicleName = '';
  String _licensePlate = '';
  String _orderNumber = '';
  final String _workshopName = 'PitMate Performance Workshop';

  EstimateModel? _estimate;
  List<EstimateItemModel> _items = [];
  List<EstimateAuthorizationModel> _authorizations = [];
  List<Map<String, dynamic>> _availableEstimates = [];
  String? _selectedEstimateId;
  final Set<String> _selectedOptionalItemIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialEstimate != null) {
      _estimate = widget.initialEstimate;
      _items = widget.initialItems != null ? List.from(widget.initialItems!) : [];
      _vehicleName = widget.initialVehicleName ?? '';
      _licensePlate = widget.initialLicensePlate ?? '';
      _orderNumber = widget.initialOrderNumber ?? '';
      _syncOptionalSelection();
    } else {
      _loadLiveEstimate();
    }
  }

  void _syncOptionalSelection() {
    _selectedOptionalItemIds.clear();
    for (final item in _items) {
      if (item.isOptional && item.authorizationStatus != AuthorizationStatus.rejected) {
        _selectedOptionalItemIds.add(item.id);
      }
    }
  }

  sb.SupabaseClient? _tryGetClient() {
    try {
      return sb.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadLiveEstimate({String? overrideEstimateId}) async {
    final estId = overrideEstimateId ?? widget.estimateId;
    final orderId = overrideEstimateId == null ? widget.serviceOrderId : null;
    final client = _tryGetClient();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(estimateRepositoryProvider);
      EstimateModel? loadedEstimate;
      String? resolvedOrderId = orderId;

      if (estId != null && estId.isNotEmpty) {
        final res = await repo.fetchEstimateById(estId);
        res.when(
          success: (e) {
            loadedEstimate = e;
            resolvedOrderId ??= e?.serviceOrderId;
          },
          failure: (err) => _errorMessage = err.message,
        );
      } else if (orderId != null && orderId.isNotEmpty) {
        final res = await repo.fetchEstimateByOrderId(orderId);
        res.when(
          success: (e) => loadedEstimate = e,
          failure: (err) => _errorMessage = err.message,
        );
      } else if (client != null) {
        final user = client.auth.currentUser;
        if (user != null) {
          final cust = await client
              .from('customers')
              .select('id')
              .eq('profile_id', user.id)
              .maybeSingle();

          if (cust != null) {
            final custId = cust['id'] as String;
            final rows = await client
                .from('estimates')
                .select('''
                  *,
                  service_orders!inner(
                    id, order_number, customer_id,
                    vehicles(make, model, license_plate)
                  )
                ''')
                .eq('service_orders.customer_id', custId)
                .order('updated_at', ascending: false);

            final allRows = (rows as List).cast<Map<String, dynamic>>();
            final activeRows = allRows
                .where((r) => r['status'] != 'superseded' && r['status'] != 'draft')
                .toList();
            final candidates = activeRows.isNotEmpty
                ? activeRows
                : allRows.where((r) => r['status'] != 'superseded').toList();

            // Prioritize estimates currently awaiting customer decision.
            candidates.sort((a, b) {
              final aSent = a['status'] == 'sent' ? 0 : 1;
              final bSent = b['status'] == 'sent' ? 0 : 1;
              return aSent.compareTo(bSent);
            });

            _availableEstimates = candidates;
            if (candidates.isNotEmpty) {
              final chosen = candidates.first;
              _selectedEstimateId = chosen['id'] as String;
              loadedEstimate = EstimateModel.fromJson(chosen);
              final so = chosen['service_orders'] as Map<String, dynamic>?;
              resolvedOrderId = so?['id'] as String?;
            }
          }
        }
      }

      if (resolvedOrderId != null && resolvedOrderId!.isNotEmpty) {
        final orderRes = await repo.fetchServiceOrderSummary(resolvedOrderId!);
        orderRes.when(
          success: (orderData) {
            if (orderData != null) {
              final veh = orderData['vehicles'] as Map<String, dynamic>?;
              _orderNumber = (orderData['order_number'] as String?) ?? '';
              if (veh != null) {
                _vehicleName = '${veh['make'] ?? ''} ${veh['model'] ?? ''}'.trim();
                _licensePlate = (veh['license_plate'] as String?) ?? '';
              }
            }
          },
          failure: (err) => _errorMessage ??= err.message,
        );
      }

      if (loadedEstimate != null) {
        final itemsRes = await repo.fetchEstimateItems(loadedEstimate!.id);
        final authRes = await repo.fetchAuthorizations(loadedEstimate!.id);

        if (mounted) {
          setState(() {
            _estimate = loadedEstimate;
            _selectedEstimateId = loadedEstimate!.id;
            itemsRes.when(
              success: (items) {
                _items = items;
                _syncOptionalSelection();
              },
              failure: (err) => _errorMessage ??= err.message,
            );
            authRes.when(
              success: (auths) => _authorizations = auths,
              failure: (_) {},
            );
          });
        }
      } else if (mounted) {
        setState(() {
          _estimate = null;
          _items = [];
          _authorizations = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _partsTotalCents {
    return _items
        .where((i) => i.itemType == EstimateItemType.part)
        .fold<int>(0, (sum, i) => sum + i.totalPriceCents);
  }

  int get _laborTotalCents {
    return _items
        .where((i) => i.itemType == EstimateItemType.labor)
        .fold<int>(0, (sum, i) => sum + i.totalPriceCents);
  }

  int get _packagesTotalCents {
    return _items
        .where((i) => i.itemType == EstimateItemType.package)
        .fold<int>(0, (sum, i) => sum + i.totalPriceCents);
  }

  Future<void> _handleApproveEstimate() async {
    final est = _estimate;
    if (est == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'AUTHORIZE ESTIMATE',
            style: AppTypography.headlineSmall().copyWith(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By confirming, you authorize PitMate to commence repairs as itemized for ${est.formattedTotal}.',
                style: AppTypography.bodyMedium(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: AppSpacing.p12,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your authorization will be recorded in the workshop audit ledger.',
                        style: AppTypography.bodySmall(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_dialog_approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm Authorization'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final approvedIds = <String>[];
    final rejectedIds = <String>[];
    for (final item in _items) {
      if (item.id.isEmpty) continue;
      if (!item.isOptional || _selectedOptionalItemIds.contains(item.id)) {
        approvedIds.add(item.id);
      } else {
        rejectedIds.add(item.id);
      }
    }

    try {
      final repo = ref.read(estimateRepositoryProvider);
      // Use authorizeEstimateItems so estimate_items.authorization_status is marked approved in DB.
      final result = await repo.authorizeEstimateItems(
        est.id,
        approvedItemIds: approvedIds,
        rejectedItemIds: rejectedIds,
        notes: 'Customer approved estimate via portal',
      );

      if (!mounted) return;
      await result.when(
        success: (updated) async {
          final authRes = await repo.fetchAuthorizations(updated.id);
          final itemsRes = await repo.fetchEstimateItems(updated.id);
          if (!mounted) return;
          setState(() {
            _estimate = updated;
            _successMessage = 'Estimate authorized successfully. Repair work is now queued.';
            authRes.when(success: (auths) => _authorizations = auths, failure: (_) {});
            itemsRes.when(success: (items) => _items = items, failure: (_) {});
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estimate authorized! Workshop notified.'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        failure: (err) {
          setState(() {
            _errorMessage = err.message;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err.message),
              backgroundColor: AppColors.danger,
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() => _errorMessage = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRejectEstimate() async {
    final est = _estimate;
    if (est == null) return;

    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'DECLINE WORK ESTIMATE',
            style: AppTypography.headlineSmall(
              color: AppColors.danger,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please specify the reason for declining this repair estimate so the service advisor can assist you:',
                style: AppTypography.bodyMedium(),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('field_rejection_reason'),
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Total cost exceeds budget / vehicle needed immediately...',
                  border: OutlineInputBorder(borderRadius: AppSpacing.roundedSmall),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Back'),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_dialog_reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(reasonController.text.trim()),
              child: const Text('Decline Estimate'),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final allIds = _items.map((i) => i.id).where((id) => id.isNotEmpty).toList();

    try {
      final repo = ref.read(estimateRepositoryProvider);
      final result = await repo.authorizeEstimateItems(
        est.id,
        approvedItemIds: const [],
        rejectedItemIds: allIds,
        notes: reason.isNotEmpty ? reason : 'Customer rejected repair estimate',
      );

      if (!mounted) return;
      await result.when(
        success: (updated) async {
          final authRes = await repo.fetchAuthorizations(updated.id);
          final itemsRes = await repo.fetchEstimateItems(updated.id);
          if (!mounted) return;
          setState(() {
            _estimate = updated;
            _successMessage = 'Estimate declined. Service advisor notified.';
            authRes.when(success: (auths) => _authorizations = auths, failure: (_) {});
            itemsRes.when(success: (items) => _items = items, failure: (_) {});
          });
        },
        failure: (err) {
          setState(() => _errorMessage = err.message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err.message), backgroundColor: AppColors.danger),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() => _errorMessage = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final mutedColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final auth = ref.watch(authNotifierProvider);
    final userName = auth is AuthAuthenticated ? auth.userProfile.fullName : 'User';

    return ResponsiveRoleScaffold(
      roleTitle: 'Estimate Review',
      userName: userName,
      userSubtitle: 'Customer Member',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.customerGarage);
        }
      },
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      navItems: RoleNavigation.customerNavItems,
      currentIndex: 3,
      onNavIndexChanged: (index) => RoleNavigation.navigate(
        context,
        RoleNavigation.customerNavItems,
        index,
        currentIndex: 3,
      ),
      telemetryNotice: _estimate != null
          ? 'ESTIMATE: ${_estimate!.revisionLabel.toUpperCase()}'
          : null,
      actions: [
        const NotificationBellButton(),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Estimates',
          onPressed: () => _loadLiveEstimate(overrideEstimateId: _selectedEstimateId),
        ),
      ],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                key: Key('customer_estimate_loading'),
                color: AppColors.racingRed,
              ),
            )
          : _estimate == null
              ? _buildEmptyState(context, isDark, textColor, mutedColor)
              : SingleChildScrollView(
                  padding: AppSpacing.p24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_availableEstimates.length > 1) ...[
                        DropdownButtonFormField<String>(
                          key: const Key('customer_estimate_selector'),
                          isExpanded: true,
                          initialValue: _selectedEstimateId,
                          decoration: const InputDecoration(
                            labelText: 'Select Estimate',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          items: _availableEstimates.map((row) {
                            final so = row['service_orders'] as Map<String, dynamic>?;
                            final veh = so?['vehicles'] as Map<String, dynamic>?;
                            final plate = veh?['license_plate'] ?? '';
                            final orderNum = so?['order_number'] ?? '';
                            final rev = row['revision_number'] ?? 1;
                            final status = row['status'] ?? '';
                            return DropdownMenuItem<String>(
                              value: row['id'] as String,
                              child: Text('$orderNum ($plate) - Rev $rev [$status]'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _loadLiveEstimate(overrideEstimateId: val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildHeaderCard(context, isDark, textColor, mutedColor, borderColor),
                      const SizedBox(height: 16),

                      if (_estimate!.status == EstimateStatus.approved ||
                          _estimate!.status == EstimateStatus.partiallyApproved) ...[
                        _buildApprovalSuccessCard(isDark, borderColor),
                        const SizedBox(height: 16),
                      ] else if (_estimate!.status == EstimateStatus.rejected) ...[
                        _buildRejectionBanner(isDark, borderColor),
                        const SizedBox(height: 16),
                      ],

                      if (_errorMessage != null) ...[
                        Container(
                          padding: AppSpacing.p12,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: AppSpacing.roundedSmall,
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodyMedium(color: AppColors.danger),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_successMessage != null) ...[
                        Container(
                          padding: AppSpacing.p12,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: AppSpacing.roundedSmall,
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _successMessage!,
                            style: AppTypography.bodyMedium(color: AppColors.success),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildCostBreakdownCards(context, isDark, textColor, mutedColor, borderColor),
                      const SizedBox(height: 16),
                      _buildItemizedTableCard(context, isDark, textColor, mutedColor, borderColor),
                      const SizedBox(height: 16),

                      if (_estimate!.notes != null && _estimate!.notes!.isNotEmpty) ...[
                        _buildWorkshopNotesCard(isDark, textColor, mutedColor, borderColor),
                        const SizedBox(height: 16),
                      ],

                      _buildGrandTotalCard(context, isDark, textColor, mutedColor, borderColor),
                      const SizedBox(height: 24),

                      if (_estimate!.status == EstimateStatus.sent ||
                          _estimate!.status == EstimateStatus.draft) ...[
                        _buildDecisionActionRow(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: PitCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.request_quote_outlined,
                  size: 56,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Repair Estimates Yet',
                  style: AppTypography.headlineSmall(color: textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ??
                      'When a mechanic finishes inspecting your vehicle and the workshop advisor sends a repair quote, it will appear here for your review.',
                  style: AppTypography.bodyMedium(color: mutedColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go(RoutePaths.customerTracking),
                      icon: const Icon(Icons.track_changes, size: 18),
                      label: const Text('LIVE TRACKING'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go(RoutePaths.bookService),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('BOOK SERVICE'),
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

  Widget _buildHeaderCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final est = _estimate!;
    return PitCard(
      padding: AppSpacing.p16,
      accentBorderLeft: AppColors.racingRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATE FOR SERVICE',
                      style: AppTypography.labelSmall(
                        color: AppColors.racingRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _vehicleName.isNotEmpty ? _vehicleName : 'Service Vehicle',
                      style: AppTypography.headlineMedium(color: textColor),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: est.status.displayName,
                type: est.status == EstimateStatus.approved ||
                        est.status == EstimateStatus.partiallyApproved
                    ? StatusBadgeType.success
                    : (est.status == EstimateStatus.rejected
                        ? StatusBadgeType.danger
                        : StatusBadgeType.warning),
              ),
            ],
          ),
          const Divider(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _buildHeaderItem(
                'LICENSE PLATE',
                _licensePlate.isNotEmpty ? _licensePlate : '-',
                textColor,
                isMono: true,
              ),
              _buildHeaderItem(
                'SERVICE ORDER',
                _orderNumber.isNotEmpty ? _orderNumber : est.serviceOrderId,
                textColor,
                isMono: true,
              ),
              _buildHeaderItem('REVISION', est.revisionLabel, textColor),
              _buildHeaderItem('WORKSHOP', _workshopName, textColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(String label, String value, Color textColor, {bool isMono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall(color: AppColors.textSecondaryLight)),
        const SizedBox(height: 2),
        Text(
          value,
          style: isMono
              ? AppTypography.telemetryMedium(color: textColor, fontWeight: FontWeight.w600)
              : AppTypography.bodyMedium(color: textColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildApprovalSuccessCard(bool isDark, Color borderColor) {
    final latestAuth = _authorizations.isNotEmpty ? _authorizations.first : null;

    return Container(
      key: const Key('card_approval_confirmation'),
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: AppSpacing.roundedCard,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ESTIMATE AUTHORIZED & WORK APPROVED',
                  style: AppTypography.labelLarge(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your repair authorization has been recorded. PitMate technicians have queued your vehicle for service.',
            style: AppTypography.bodyMedium(),
          ),
          if (latestAuth != null && latestAuth.signatureToken != null) ...[
            const SizedBox(height: 8),
            Text(
              'Authorization Ref: ${latestAuth.signatureToken}',
              style: AppTypography.telemetrySmall(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectionBanner(bool isDark, Color borderColor) {
    return Container(
      key: const Key('card_rejection_banner'),
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: AppSpacing.roundedCard,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: AppColors.danger, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORK ESTIMATE DECLINED',
                  style: AppTypography.labelLarge(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You declined this estimate. A workshop service advisor will contact you to discuss alternative options.',
                  style: AppTypography.bodySmall(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdownCards(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: PitCard(
            padding: AppSpacing.p12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.racingRed),
                    const SizedBox(width: 6),
                    Text('PARTS CHARGES', style: AppTypography.labelSmall(color: mutedColor)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  EstimateModel.formatIdr(_partsTotalCents),
                  key: const Key('text_parts_breakdown_total'),
                  style: AppTypography.telemetryLarge(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PitCard(
            padding: AppSpacing.p12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.engineering_outlined, size: 16, color: AppColors.info),
                    const SizedBox(width: 6),
                    Text('LABOR CHARGES', style: AppTypography.labelSmall(color: mutedColor)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  EstimateModel.formatIdr(_laborTotalCents),
                  key: const Key('text_labor_breakdown_total'),
                  style: AppTypography.telemetryLarge(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_packagesTotalCents > 0) ...[
          const SizedBox(width: 12),
          Expanded(
            child: PitCard(
              padding: AppSpacing.p12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text('PACKAGES', style: AppTypography.labelSmall(color: mutedColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    EstimateModel.formatIdr(_packagesTotalCents),
                    style: AppTypography.telemetryLarge(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemizedTableCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final canEditOptional = _estimate?.status == EstimateStatus.sent ||
        _estimate?.status == EstimateStatus.draft;

    return PitCard(
      padding: AppSpacing.p16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 18, color: AppColors.racingRed),
              const SizedBox(width: 8),
              Text(
                'ITEMIZED REPAIR BREAKDOWN',
                style: AppTypography.labelLarge(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_items.length} ITEMS',
                style: AppTypography.telemetrySmall(color: mutedColor),
              ),
            ],
          ),
          const Divider(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = _items[index];
              final isOptSelected = _selectedOptionalItemIds.contains(item.id);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.isOptional && canEditOptional)
                    Checkbox(
                      key: Key('chk_optional_item_${item.id}'),
                      value: isOptSelected,
                      activeColor: AppColors.accentRed,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedOptionalItemIds.add(item.id);
                          } else {
                            _selectedOptionalItemIds.remove(item.id);
                          }
                        });
                      },
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.itemType == EstimateItemType.part
                          ? AppColors.racingRed.withValues(alpha: 0.12)
                          : AppColors.info.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedSmall,
                      border: Border.all(
                        color: item.itemType == EstimateItemType.part
                            ? AppColors.racingRed.withValues(alpha: 0.35)
                            : AppColors.info.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      item.itemType.displayName.toUpperCase(),
                      style: AppTypography.telemetrySmall(
                        color: item.itemType == EstimateItemType.part
                            ? AppColors.racingRed
                            : AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: AppTypography.labelLarge(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.quantity} × ${item.formattedUnitPrice}',
                          style: AppTypography.telemetrySmall(color: mutedColor),
                        ),
                        if (item.isOptional) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: AppSpacing.roundedSmall,
                            ),
                            child: Text(
                              'OPTIONAL RECOMMENDATION',
                              style: AppTypography.telemetrySmall(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ).copyWith(fontSize: 9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.formattedTotalPrice,
                    style: AppTypography.telemetryMedium(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkshopNotesCard(
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    return PitCard(
      padding: AppSpacing.p16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_alt_outlined, size: 16, color: AppColors.racingRed),
              const SizedBox(width: 6),
              Text(
                'WORKSHOP ADVISOR NOTES',
                style: AppTypography.labelMedium(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _estimate!.notes!,
            style: AppTypography.bodyMedium(color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final est = _estimate!;
    return PitCard(
      padding: const EdgeInsets.all(20),
      accentBorderTop: AppColors.racingRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryLine('SUBTOTAL (PARTS + LABOR)', est.formattedSubtotal, mutedColor, textColor),
          if (est.discountCents > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryLine(
              'WORKSHOP DISCOUNT',
              '-${est.formattedDiscount}',
              mutedColor,
              AppColors.success,
            ),
          ],
          const SizedBox(height: 8),
          _buildSummaryLine(
            'PPN (11% TAX)',
            est.formattedTax,
            mutedColor,
            isDark ? AppColors.infoDark : AppColors.info,
          ),
          const Divider(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL ESTIMATE',
                    style: AppTypography.headlineSmall(
                      color: textColor,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Includes all itemized parts, labor, and PPN',
                    style: AppTypography.bodySmall(color: mutedColor),
                  ),
                ],
              ),
              Text(
                est.formattedTotal,
                key: const Key('customer_grand_total_text'),
                style: AppTypography.telemetryLarge(
                  color: AppColors.racingRed,
                  fontWeight: FontWeight.w700,
                ).copyWith(fontSize: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium(color: labelColor)),
        Text(
          value,
          style: AppTypography.telemetryMedium(color: valueColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDecisionActionRow() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            key: const Key('btn_customer_reject_work'),
            onPressed: _isLoading ? null : _handleRejectEstimate,
            icon: const Icon(Icons.close, size: 20, color: AppColors.danger),
            label: const Text('Decline Work'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 52),
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            key: const Key('btn_customer_approve_work'),
            onPressed: _isLoading ? null : _handleApproveEstimate,
            icon: const Icon(Icons.check_circle_outline, size: 22),
            label: const Text('Authorize & Approve Estimate'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(180, 52),
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
