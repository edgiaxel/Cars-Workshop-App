import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Semantic status badge adhering strictly to DESIGN.md sections 4.3, 5, and 8.
///
/// Features a colored dot, dark elevated container with subtle border, and uppercase text.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  /// Factory mapping service order status strings to semantic status badges.
  factory StatusBadge.forServiceStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'requested':
      case 'approved':
      case 'scheduled':
        return StatusBadge(label: status, color: AppColors.statusRequested);
      case 'inspection':
      case 'diagnosis':
      case 'waiting_for_approval':
      case 'waiting_for_parts':
        return StatusBadge(
          label: status.replaceAll('_', ' '),
          color: AppColors.statusInspection,
        );
      case 'in_progress':
        return const StatusBadge(
          label: 'IN PROGRESS',
          color: AppColors.statusInProgress,
        );
      case 'completion_review':
        return const StatusBadge(
          label: 'COMPLETION REVIEW',
          color: AppColors.statusCompletionReview,
        );
      case 'completed':
      case 'payment':
        return StatusBadge(
          label: status.toUpperCase(),
          color: AppColors.statusCompleted,
        );
      case 'closed':
        return const StatusBadge(
          label: 'CLOSED',
          color: AppColors.statusClosed,
        );
      case 'cancelled':
      case 'rejected':
        return StatusBadge(
          label: status.toUpperCase(),
          color: AppColors.statusCancelled,
        );
      default:
        return StatusBadge(
          label: status.toUpperCase(),
          color: AppColors.neutral,
        );
    }
  }

  /// Factory mapping task status strings to semantic status badges.
  factory StatusBadge.forTaskStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return const StatusBadge(
          label: 'PENDING',
          color: AppColors.taskPending,
        );
      case 'in_progress':
        return const StatusBadge(
          label: 'IN PROGRESS',
          color: AppColors.taskInProgress,
        );
      case 'completed':
        return const StatusBadge(
          label: 'COMPLETED',
          color: AppColors.taskCompleted,
        );
      case 'blocked':
        return const StatusBadge(
          label: 'BLOCKED',
          color: AppColors.taskBlocked,
        );
      case 'cancelled':
        return const StatusBadge(
          label: 'CANCELLED',
          color: AppColors.taskCancelled,
        );
      default:
        return StatusBadge(
          label: status.toUpperCase(),
          color: AppColors.neutral,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: AppSpacing.micro),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.technical(color: color)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
