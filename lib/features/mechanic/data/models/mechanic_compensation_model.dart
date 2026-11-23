// Models for Mechanic Compensation, Incentives, and Payroll Adjustments (VS-15, F-016).

class MechanicCompensationProfile {
  final String mechanicId;
  final int baseSalaryCents;
  final double incentivePercentage;
  final double defaultLeadSharePercentage;
  final DateTime updatedAt;

  // Joined profile fields
  final String? mechanicName;
  final String? mechanicEmail;

  const MechanicCompensationProfile({
    required this.mechanicId,
    required this.baseSalaryCents,
    required this.incentivePercentage,
    this.defaultLeadSharePercentage = 70.0,
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

    final rawSalary = json['monthly_base_salary_cents'] ?? json['base_salary_cents'];
    final salary = (rawSalary as num?)?.toInt() ?? 5000000;

    final rawIncentive = json['standard_incentive_percent'] ?? json['incentive_percentage'];
    final incentive = rawIncentive is num ? rawIncentive.toDouble() : (double.tryParse(rawIncentive?.toString() ?? '') ?? 10.0);

    final rawSplit = json['default_lead_share_percentage'];
    final split = rawSplit is num ? rawSplit.toDouble() : (double.tryParse(rawSplit?.toString() ?? '') ?? 70.0);

    return MechanicCompensationProfile(
      mechanicId: json['mechanic_id'] as String? ?? '',
      baseSalaryCents: salary,
      incentivePercentage: incentive,
      defaultLeadSharePercentage: split,
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

    final rawSplit = json['split_percentage'] ?? json['share_percentage'];
    final splitVal = rawSplit is num ? rawSplit.toDouble() : (double.tryParse(rawSplit?.toString() ?? '') ?? 0.0);

    return MechanicEarningAllocation(
      id: json['id'] as String? ?? '',
      earningId: json['earning_id'] as String? ?? '',
      mechanicId: json['mechanic_id'] as String? ?? '',
      allocatedCents: (json['allocated_cents'] as num?)?.toInt() ?? 0,
      sharePercentage: splitVal,
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

    final rawAmount = (json['amount_cents'] as num?)?.toInt() ?? 0;
    final type = json['adjustment_type'] as String? ?? (rawAmount >= 0 ? 'bonus' : 'deduction');

    return MechanicPayrollAdjustment(
      id: json['id'] as String? ?? '',
      mechanicId: json['mechanic_id'] as String? ?? '',
      amountCents: rawAmount.abs(),
      adjustmentType: type,
      reason: json['reason'] as String? ?? '',
      authorizedBy: (json['adjusted_by'] ?? json['authorized_by']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      mechanicName: name,
    );
  }
}
