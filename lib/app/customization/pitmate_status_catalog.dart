import 'package:flutter/material.dart';

import 'pitmate_palette.dart';

/// Specification of status presentation properties (label, colors, icon, description).
class StatusDescriptor {
  const StatusDescriptor({
    required this.code,
    required this.label,
    required this.color,
    required this.icon,
    this.description,
  });

  final String code;
  final String label;
  final Color color;
  final IconData icon;
  final String? description;
}

/// PitMate Canonical Status Catalog adhering to DESIGN.md and CUSTOMIZATION.md.
///
/// Maps persisted database statuses to user-visible labels, semantic colors, and icons.
abstract class PitmateStatusCatalog {
  // Service Order Statuses
  static const Map<String, StatusDescriptor> serviceStatuses = {
    'requested': StatusDescriptor(
      code: 'requested',
      label: 'Requested',
      color: PitmatePalette.statusRequested,
      icon: Icons.assignment_outlined,
      description: 'Customer requested service; awaiting workshop review',
    ),
    'approved': StatusDescriptor(
      code: 'approved',
      label: 'Approved',
      color: PitmatePalette.statusApproved,
      icon: Icons.check_circle_outline,
      description: 'Service request accepted by workshop administration',
    ),
    'scheduled': StatusDescriptor(
      code: 'scheduled',
      label: 'Scheduled',
      color: PitmatePalette.statusScheduled,
      icon: Icons.event_outlined,
      description: 'Appointment confirmed; vehicle awaiting physical arrival',
    ),
    'inspection': StatusDescriptor(
      code: 'inspection',
      label: 'Inspection',
      color: PitmatePalette.statusInspection,
      icon: Icons.search_outlined,
      description: 'Vehicle received; undergoing preliminary diagnostic inspection',
    ),
    'diagnosis': StatusDescriptor(
      code: 'diagnosis',
      label: 'Diagnosis',
      color: PitmatePalette.statusDiagnosis,
      icon: Icons.troubleshoot_outlined,
      description: 'Technician analyzing diagnostic codes and root causes',
    ),
    'waiting_for_approval': StatusDescriptor(
      code: 'waiting_for_approval',
      label: 'Waiting For Approval',
      color: PitmatePalette.statusWaitingApproval,
      icon: Icons.pending_actions_outlined,
      description: 'Estimate sent; waiting for customer authorization to proceed',
    ),
    'waiting_for_parts': StatusDescriptor(
      code: 'waiting_for_parts',
      label: 'Waiting For Parts',
      color: PitmatePalette.statusWaitingParts,
      icon: Icons.pause_circle_outline,
      description: 'Service on hold; required spare parts pending delivery',
    ),
    'in_progress': StatusDescriptor(
      code: 'in_progress',
      label: 'In Progress',
      color: PitmatePalette.statusInProgress,
      icon: Icons.speed,
      description: 'Vehicle actively being serviced in technician bay',
    ),
    'completion_review': StatusDescriptor(
      code: 'completion_review',
      label: 'Completion Review',
      color: PitmatePalette.statusCompletionReview,
      icon: Icons.rate_review_outlined,
      description: 'Service completed; quality control and supervisor inspection',
    ),
    'completed': StatusDescriptor(
      code: 'completed',
      label: 'Completed',
      color: PitmatePalette.statusCompleted,
      icon: Icons.task_alt,
      description: 'Work verified complete; ready for customer pickup and billing',
    ),
    'payment': StatusDescriptor(
      code: 'payment',
      label: 'Payment',
      color: PitmatePalette.statusPayment,
      icon: Icons.payment_outlined,
      description: 'Invoice issued; awaiting payment settlement',
    ),
    'closed': StatusDescriptor(
      code: 'closed',
      label: 'Closed',
      color: PitmatePalette.statusClosed,
      icon: Icons.lock_outline,
      description: 'Order fully settled and archived',
    ),
    'cancelled': StatusDescriptor(
      code: 'cancelled',
      label: 'Cancelled',
      color: PitmatePalette.statusCancelled,
      icon: Icons.cancel_outlined,
      description: 'Service cancelled by customer or administration',
    ),
  };

  // Booking Statuses
  static const Map<String, StatusDescriptor> bookingStatuses = {
    'requested': StatusDescriptor(
      code: 'requested',
      label: 'Requested',
      color: PitmatePalette.info,
      icon: Icons.calendar_today_outlined,
    ),
    'approved': StatusDescriptor(
      code: 'approved',
      label: 'Approved',
      color: PitmatePalette.info,
      icon: Icons.event_available_outlined,
    ),
    'scheduled': StatusDescriptor(
      code: 'scheduled',
      label: 'Scheduled',
      color: PitmatePalette.info,
      icon: Icons.schedule_outlined,
    ),
    'checked_in': StatusDescriptor(
      code: 'checked_in',
      label: 'Checked In',
      color: PitmatePalette.primaryAccent,
      icon: Icons.how_to_reg_outlined,
    ),
    'rejected': StatusDescriptor(
      code: 'rejected',
      label: 'Rejected',
      color: PitmatePalette.error,
      icon: Icons.highlight_off_outlined,
    ),
    'cancelled': StatusDescriptor(
      code: 'cancelled',
      label: 'Cancelled',
      color: PitmatePalette.error,
      icon: Icons.cancel_outlined,
    ),
    'completed': StatusDescriptor(
      code: 'completed',
      label: 'Completed',
      color: PitmatePalette.success,
      icon: Icons.check_circle_outline,
    ),
  };

  // Task Statuses
  static const Map<String, StatusDescriptor> taskStatuses = {
    'pending': StatusDescriptor(
      code: 'pending',
      label: 'Pending',
      color: PitmatePalette.taskPending,
      icon: Icons.hourglass_empty,
    ),
    'in_progress': StatusDescriptor(
      code: 'in_progress',
      label: 'In Progress',
      color: PitmatePalette.taskInProgress,
      icon: Icons.play_arrow,
    ),
    'completed': StatusDescriptor(
      code: 'completed',
      label: 'Completed',
      color: PitmatePalette.taskCompleted,
      icon: Icons.check,
    ),
    'blocked': StatusDescriptor(
      code: 'blocked',
      label: 'Blocked',
      color: PitmatePalette.taskBlocked,
      icon: Icons.block,
    ),
    'cancelled': StatusDescriptor(
      code: 'cancelled',
      label: 'Cancelled',
      color: PitmatePalette.taskCancelled,
      icon: Icons.close,
    ),
  };

  static StatusDescriptor descriptorForService(String code) {
    final normalized = code.toLowerCase().replaceAll(' ', '_');
    return serviceStatuses[normalized] ??
        StatusDescriptor(
          code: code,
          label: code.toUpperCase(),
          color: PitmatePalette.neutral,
          icon: Icons.info_outline,
        );
  }

  static StatusDescriptor descriptorForBooking(String code) {
    final normalized = code.toLowerCase().replaceAll(' ', '_');
    return bookingStatuses[normalized] ??
        StatusDescriptor(
          code: code,
          label: code.toUpperCase(),
          color: PitmatePalette.neutral,
          icon: Icons.info_outline,
        );
  }

  static StatusDescriptor descriptorForTask(String code) {
    final normalized = code.toLowerCase().replaceAll(' ', '_');
    return taskStatuses[normalized] ??
        StatusDescriptor(
          code: code,
          label: code.toUpperCase(),
          color: PitmatePalette.neutral,
          icon: Icons.info_outline,
        );
  }
}
