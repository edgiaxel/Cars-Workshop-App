import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../data/models/booking.dart';
import '../../data/models/service_order.dart';

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

  /// Factory mapping service order status strings or enums to semantic status badges.
  /// Uses [ServiceStatus] as the single source of truth for both label and color.
  factory StatusBadge.forServiceStatus(dynamic status) {
    final ServiceStatus s;
    if (status is ServiceStatus) {
      s = status;
    } else if (status is String) {
      s = ServiceStatus.fromString(status);
    } else {
      s = ServiceStatus.requested;
    }

    return StatusBadge(
      label: s.label.toUpperCase(),
      color: s.color,
    );
  }

  /// Factory mapping booking status strings or enums to semantic status badges.
  /// Uses [BookingStatus] as the single source of truth for both label and color.
  factory StatusBadge.forBookingStatus(dynamic status) {
    final BookingStatus b;
    if (status is BookingStatus) {
      b = status;
    } else if (status is String) {
      b = BookingStatus.fromString(status);
    } else {
      b = BookingStatus.requested;
    }

    return StatusBadge(
      label: b.label.toUpperCase(),
      color: b.color,
    );
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
