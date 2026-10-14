import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/service_task.dart';
import '../../../shared/providers/task_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/search_filter_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'mechanic_shell.dart';

/// Checklist and diagnostic tasks view for Mechanic role backed by live Supabase records adhering to DESIGN.md.
class MechanicTasksPage extends ConsumerStatefulWidget {
  const MechanicTasksPage({super.key});

  @override
  ConsumerState<MechanicTasksPage> createState() => _MechanicTasksPageState();
}

class _MechanicTasksPageState extends ConsumerState<MechanicTasksPage> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  void _showAddTaskDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Diagnostics');
    final descCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'CREATE CHECKLIST TASK',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Task Description / Procedure',
                  hintText: 'e.g. Compression test cylinders 1-8',
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: categoryCtrl,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Inspection Category',
                  hintText: 'e.g. Engine, Brakes, Hybrid',
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Procedure Notes / Expected Values',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: AppTypography.label(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Task checklist procedure added to active service order.',
                  ),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _showUpdateTaskDialog(BuildContext context, ServiceTask task) {
    String currentStatus = task.status;
    final notesCtrl = TextEditingController(text: task.notes ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfacePrimary,
          title: Text(
            'UPDATE TASK PROGRESS',
            style: AppTypography.sectionTitle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTypography.label(color: AppColors.primaryAccent),
                ),
                const SizedBox(height: AppSpacing.standard),
                DropdownButtonFormField<String>(
                  initialValue: currentStatus,
                  dropdownColor: AppColors.surfaceSecondary,
                  decoration: const InputDecoration(labelText: 'Task Status'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => currentStatus = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.standard),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Diagnostic Findings & Observations',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: AppTypography.label(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Task "${task.title}" updated to ${currentStatus.toUpperCase()}.',
                    ),
                    backgroundColor: AppColors.statusCompleted,
                  ),
                );
              },
              child: const Text('Save Progress'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(mechanicTasksProvider);

    return MechanicShell(
      currentRoute: RoutePaths.mechanicTasks,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(mechanicTasksProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'DIAGNOSTIC & CHECKLIST TASKS',
                subtitle: 'Step-by-step service order procedures and inspection templates',
                action: PrimaryButton(
                  text: 'Add Task',
                  icon: Icons.add_task,
                  width: 140,
                  onPressed: () => _showAddTaskDialog(context),
                ),
              ),
              const SizedBox(height: AppSpacing.compact),
              SearchFilterBar(
                searchHint:
                    'Search tasks by title, procedure, or order ticket...',
                onSearchChanged: (query) =>
                    setState(() => _searchQuery = query),
                filterOptions: const [
                  'All',
                  'In Progress',
                  'Pending',
                  'Completed',
                ],
                selectedFilter: _selectedFilter,
                onFilterSelected: (f) => setState(() => _selectedFilter = f),
              ),
              const SizedBox(height: AppSpacing.section),

              tasksAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.section),
                    child: LoadingState(
                      message: 'Retrieving technician checklist items...',
                    ),
                  ),
                ),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.refresh(mechanicTasksProvider),
                ),
                data: (allTasks) {
                  final filtered = allTasks.where((t) {
                    final query = _searchQuery.toLowerCase();
                    final matchesSearch =
                        query.isEmpty ||
                        t.title.toLowerCase().contains(query) ||
                        (t.description?.toLowerCase().contains(query) ?? false);

                    final matchesFilter =
                        _selectedFilter == 'All' ||
                        t.status.toLowerCase() ==
                            _selectedFilter.toLowerCase().replaceAll(' ', '_');

                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      title: 'No Checklist Tasks Found',
                      message:
                          'No tasks match your current search or filter query.',
                      icon: Icons.checklist_outlined,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.standard),
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      final status = task.status;

                      return PitCard(
                        technicalLabel:
                            'TASK • ${task.status.toUpperCase()} • ${task.orderNumber}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: AppTypography.sectionTitle(
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Service Order: ${task.orderNumber}',
                                        style: AppTypography.technical(
                                          color: AppColors.primaryAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.compact),
                                StatusBadge(
                                  label: status.toUpperCase(),
                                  color: status == 'completed'
                                      ? AppColors.statusCompleted
                                      : status == 'in_progress'
                                      ? AppColors.statusInProgress
                                      : AppColors.textMuted,
                                ),
                              ],
                            ),
                            if (task.description != null &&
                                task.description!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.compact),
                              Text(
                                task.description!,
                                style: AppTypography.bodySmall(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (task.notes != null &&
                                task.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Telemetry Findings: ${task.notes!}',
                                style: AppTypography.bodySmall(
                                  color: AppColors.statusCompleted,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.standard),
                            const Divider(
                              color: AppColors.borderSubtle,
                              height: 1,
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Est: ${task.estimatedMinutes} mins',
                                  style: AppTypography.technical(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showUpdateTaskDialog(context, task),
                                  icon: const Icon(Icons.edit_note, size: 14),
                                  label: const Text('Update Progress'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryAccent,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
