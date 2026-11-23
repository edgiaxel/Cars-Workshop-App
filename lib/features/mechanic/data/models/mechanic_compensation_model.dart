// Models for Mechanic Compensation, Incentives, and Payroll Adjustments (VS-15, F-016).

class MechanicCompensationProfile {
  final String mechanicId;
  final int baseSalaryCents;
  final double incentivePercentage;
  final double defaultLeadSharePercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined profile fields
  final String? mechanicName;
  final String? mechanicEmail;

  const MechanicCompensationProfile({
    required this.mechanicId,
    required this.baseSalaryCents,
    required this.incentivePercentage,
    required this.defaultLeadSharePercentage,
    required this.createdAt,
    required this.updatedAt,
    this.mechanicName,
    this.mechanicEmail,
  });

  factory MechanicCompensationProfile.fromJson(Map<String, dynamic> json) {
    String? name;
    String? email;
    if (json['profiles'] is Map<String, dynamic>) {
      final p = json['profiles'] as Map<String, dynamic>;
      name = p['full_name'] as String?;
      email = p['email'] as String?;
    }

    return MechanicCompensationProfile(
      mechanicId: json['mechanic_id'] as String? ?? '',
      baseSalaryCents: (json['base_salary_cents'] as num?)?.toInt() ?? 0,
      incentivePercentage: (json['incentive_percentage'] as num?)?.toDouble() ?? 10.0,
      defaultLeadSharePercentage: (json['default_lead_share_percentage'] as num?)?.toDouble() ?? 70.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      mechanicName: name,
      mechanicEmail: email,
    );
  }
}

class MechanicEarningAllocation {
  final String id;
  final String earningId;
  final String mechanicId;
  final int allocatedCents;
  final double sharePercentage;
  final String roleInTask;
  final DateTime createdAt;

  // Joined fields from earning/task/order
  final String? taskTitle;
  final String? orderNumber;

  const MechanicEarningAllocation({
    required this.id,
    required this.earningId,
    required this.mechanicId,
    required this.allocatedCents,
    required this.sharePercentage,
    required this.roleInTask,
    required this.createdAt,
    this.taskTitle,
    this.orderNumber,
  });

  bool get isLead => roleInTask == 'lead';

  factory MechanicEarningAllocation.fromJson(Map<String, dynamic> json) {
    String? title;
    String? orderNum;

    if (json['mechanic_earnings'] is Map<String, dynamic>) {
      final e = json['mechanic_earnings'] as Map<String, dynamic>;
      if (e['service_order_tasks'] is Map<String, dynamic>) {
        title = e['service_order_tasks']['title'] as String?;
      }
      if (e['service_orders'] is Map<String, dynamic>) {
        orderNum = e['service_orders']['order_number'] as String?;
      }
    }

    return MechanicEarningAllocation(
      id: json['id'] as String? ?? '',
      earningId: json['earning_id'] as String? ?? '',
      mechanicId: json['mechanic_id'] as String? ?? '',
      allocatedCents: (json['allocated_cents'] as num?)?.toInt() ?? 0,
      sharePercentage: (json['share_percentage'] as num?)?.toDouble() ?? 0.0,
      roleInTask: json['role_in_task'] as String? ?? 'lead',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      taskTitle: title,
      orderNumber: orderNum,
    );
  }
}

class MechanicPayrollAdjustment {
  final String id;
  final String mechanicId;
  final int amountCents;
  final String adjustmentType; // 'bonus', 'deduction', 'adjustment'
  final String reason;
  final String? authorizedBy;
  final DateTime createdAt;

  final String? mechanicName;

  const MechanicPayrollAdjustment({
    required this.id,
    required this.mechanicId,
    required this.amountCents,
    required this.adjustmentType,
    required this.reason,
    this.authorizedBy,
    required this.createdAt,
    this.mechanicName,
  });

  bool get isBonus => adjustmentType == 'bonus';
  bool get isDeduction => adjustmentType == 'deduction';

  factory MechanicPayrollAdjustment.fromJson(Map<String, dynamic> json) {
    String? name;
    if (json['profiles'] is Map<String, dynamic>) {
      name = json['profiles']['full_name'] as String?;
    }

    return MechanicPayrollAdjustment(
      id: json['id'] as String? ?? '',
      mechanicId: json['mechanic_id'] as String? ?? '',
      amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
      adjustmentType: json['adjustment_type'] as String? ?? 'adjustment',
      reason: json['reason'] as String? ?? '',
      authorizedBy: json['authorized_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      mechanicName: name,
    );
  }
}
