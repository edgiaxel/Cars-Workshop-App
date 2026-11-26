import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/features/service_operations/data/models/service_order_task_model.dart';
import 'package:pitmate/features/service_operations/data/repositories/service_operations_repository.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live Mechanic Home & Assigned Operations Queue.
class MechanicHomeScreen extends ConsumerStatefulWidget {
  const MechanicHomeScreen({
    super.key,
    this.initialInspections,
    this.initialTasks,
  });

  final List<Map<String, dynamic>>? initialInspections;
  final List<ServiceOrderTaskModel>? initialTasks;

  @override
  ConsumerState<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends ConsumerState<MechanicHomeScreen> {
  final _operationsRepo = ServiceOperationsRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _inspections = [];
  List<ServiceOrderTaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialInspections != null || widget.initialTasks != null) {
      _inspections = List.from(widget.initialInspections ?? const []);
      _tasks = List.from(widget.initialTasks ?? const []);
      _isLoading = false;
    } else {
      _loadWorkQueue();
    }
  }

  SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadWorkQueue() async {
    final client = _tryGetClient();
    if (client == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authNotifierProvider);
      final mechanicId = auth is AuthAuthenticated
          ? auth.userProfile.id
          : (client.auth.currentUser?.id ?? '');

      if (mechanicId.isEmpty) {
        if (mounted) {
          setState(() {
            _inspections = [];
            _tasks = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Unassigned inspections (mechanic_id IS NULL) will return service_orders=null
      // due to RLS until claimed by the mechanic, so never discard rows with null join.
      final inspFuture = client
          .from('inspections')
          .select(
            'id, service_order_id, mechanic_id, status, created_at, '
            'service_orders(id, order_number, status, assigned_bay, customer_complaint, '
            'vehicles(license_plate, make, model, year), customers(full_name))',
          )
          .inFilter('status', ['assigned', 'in_progress'])
          .or('mechanic_id.is.null,mechanic_id.eq.$mechanicId')
          .order('created_at', ascending: false);

      final tasksFuture = _operationsRepo.fetchTasksForMechanic(mechanicId);

      final results = await Future.wait<dynamic>([
        inspFuture.then((r) => r),
        tasksFuture,
      ]);
      final rawInspections = List<Map<String, dynamic>>.from(results[0] as List);
      final loadedTasks = results[1] as List<ServiceOrderTaskModel>;

      if (!mounted) return;
      setState(() {
        _inspections = rawInspections;
        _tasks = loadedTasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load work queue: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final auth = ref.watch(authNotifierProvider);
    final mechanicName =
        auth is AuthAuthenticated ? auth.userProfile.fullName : 'User';

    final assignedCount = _tasks.where((t) => !t.isCompleted).length;
    final inProgressCount = _tasks.where((t) => t.isInProgress).length;
    final completedCount = _tasks.where((t) => t.isCompleted).length;

    return ResponsiveRoleScaffold(
      roleTitle: 'Mechanic Telemetry',
      userName: mechanicName,
      userSubtitle: 'Workshop Technician',
      currentIndex: 0,
      onNavIndexChanged: (i) => RoleNavigation.navigate(
        context,
        RoleNavigation.mechanicNavItems,
        i,
        currentIndex: 0,
      ),
      navItems: RoleNavigation.mechanicNavItems,
      telemetryNotice:
          '${_inspections.length} INSPECTIONS • $assignedCount OPEN TASKS',
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        const NotificationBellButton(),
        IconButton(
          key: const Key('btn_refresh_mechanic_home'),
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Work Queue',
          onPressed: _loadWorkQueue,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: PitCard(
                      accentBorderLeft: AppColors.danger,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.danger,
                            size: 38,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium(color: textColor),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: _loadWorkQueue,
                            icon: const Icon(Icons.refresh),
                            label: const Text('RETRY'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWorkQueue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 18.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildKpiRow(
                              isDark,
                              textColor,
                              mutedColor,
                              _inspections.length,
                              assignedCount,
                              inProgressCount,
                              completedCount,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'VEHICLE INSPECTIONS (${_inspections.length})',
                              style: AppTypography.labelLarge(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildInspectionsSection(
                              isDark,
                              textColor,
                              mutedColor,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'ASSIGNED REPAIR OPERATIONS (${_tasks.length})',
                              style: AppTypography.labelLarge(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildTasksSection(
                              isDark,
                              textColor,
                              mutedColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildKpiRow(
    bool isDark,
    Color textColor,
    Color mutedColor,
    int inspectionsCount,
    int openTasksCount,
    int inProgressCount,
    int completedCount,
  ) {
    final cards = [
      ('PENDING INSPECTIONS', '$inspectionsCount', AppColors.warning),
      ('ASSIGNED TASKS', '$openTasksCount', AppColors.info),
      ('IN PROGRESS', '$inProgressCount', AppColors.accentRed),
      ('COMPLETED TASKS', '$completedCount', AppColors.success),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 640 ? 4 : 2;
        final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((c) {
            return SizedBox(
              width: width,
              child: PitCard(
                accentBorderLeft: c.$3,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.$1,
                      style: AppTypography.labelSmall(color: mutedColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.$2,
                      style: AppTypography.telemetryLarge(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInspectionsSection(
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    if (_inspections.isEmpty) {
      return PitCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.fact_check_outlined, color: mutedColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No pending vehicle inspections queued right now.',
                  style: AppTypography.bodyMedium(color: mutedColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _inspections.map((row) {
        final inspId = row['id'] as String? ?? '';
        final serviceOrderId = row['service_order_id'] as String? ?? '';
        final isUnassigned = row['mechanic_id'] == null;
        final so = row['service_orders'] as Map<String, dynamic>?;
        final vehicle = so?['vehicles'] as Map<String, dynamic>?;
        final customer = so?['customers'] as Map<String, dynamic>?;

        final titleText = so == null
            ? 'Pending Vehicle Inspection (Unassigned)'
            : '${so['order_number'] ?? 'Service Order'} • ${vehicle?['make'] ?? ''} ${vehicle?['model'] ?? ''}'
                .trim();

        final subtitleParts = <String>[
          if (vehicle?['license_plate'] != null)
            'Plate: ${vehicle!['license_plate']}',
          if (customer?['full_name'] != null)
            'Owner: ${customer!['full_name']}',
          if (so?['assigned_bay'] != null) 'Bay: ${so!['assigned_bay']}',
          if (so?['customer_complaint'] != null)
            'Complaint: ${so!['customer_complaint']}',
          if (so == null)
            'Tap Claim & Inspect to open full vehicle telemetry & diagnostic sheet.',
        ];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PitCard(
            accentBorderLeft:
                isUnassigned ? AppColors.warning : AppColors.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        titleText,
                        style: AppTypography.headlineSmall(color: textColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: isUnassigned ? 'AWAITING CLAIM' : 'IN PROGRESS',
                      type: isUnassigned
                          ? StatusBadgeType.warning
                          : StatusBadgeType.inProgress,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitleParts.join(' • '),
                  style: AppTypography.bodySmall(color: mutedColor),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  key: Key('btn_inspect_$inspId'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedSmall,
                    ),
                  ),
                  icon: Icon(
                    isUnassigned ? Icons.assignment_ind : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(
                    isUnassigned ? 'CLAIM & INSPECT' : 'CONTINUE INSPECTION',
                  ),
                  onPressed: () {
                    context.go(
                      '${RoutePaths.mechanicInspection}?orderId=$serviceOrderId&inspectionId=$inspId',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTasksSection(
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    if (_tasks.isEmpty) {
      return PitCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.build_circle_outlined, color: mutedColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No repair operations assigned to your bay yet.',
                  style: AppTypography.bodyMedium(color: mutedColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _tasks.map((task) {
        Color statusColor = AppColors.info;
        if (task.isCompleted) statusColor = AppColors.success;
        if (task.isInProgress) statusColor = AppColors.accentRed;
        if (task.isPaused) statusColor = AppColors.warning;

        final doneChecks = task.checklists.where((c) => c.isCompleted).length;
        final totalChecks = task.checklists.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PitCard(
            accentBorderLeft: statusColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: AppTypography.headlineSmall(color: textColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: task.status.label.toUpperCase(),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (task.orderNumber != null) task.orderNumber!,
                    if (task.vehiclePlate != null) task.vehiclePlate!,
                    if (task.vehicleModel != null) task.vehicleModel!,
                    'Est: ${task.estimatedDurationMinutes}m',
                    if (totalChecks > 0)
                      'Checklist: $doneChecks/$totalChecks',
                  ].join(' • '),
                  style: AppTypography.bodySmall(color: mutedColor),
                ),
                if (task.description != null &&
                    task.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: AppTypography.bodySmall(color: textColor),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  key: Key('btn_open_task_${task.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: task.isCompleted
                        ? (isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.graphitePrimary)
                        : AppColors.accentRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedSmall,
                    ),
                  ),
                  icon: const Icon(Icons.build_outlined, size: 18),
                  label: Text(
                    task.isCompleted ? 'VIEW WORKSPACE' : 'OPEN WORKSPACE',
                  ),
                  onPressed: () {
                    context.go(
                      '${RoutePaths.mechanicOperation}?taskId=${task.id}',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
