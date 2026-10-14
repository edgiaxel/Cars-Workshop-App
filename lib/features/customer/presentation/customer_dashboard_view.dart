import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/service_order.dart';
import '../../../data/models/vehicle.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../shared/providers/reminder_provider.dart';
import '../../../shared/providers/service_order_provider.dart';
import '../../../shared/providers/vehicle_provider.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

/// Customer Garage Dashboard view connected to live Supabase data.
class CustomerDashboardView extends ConsumerWidget {
  const CustomerDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    final profile = authState.profile;

    final vehiclesAsync = ref.watch(customerVehiclesProvider(null));
    final bookingsAsync = ref.watch(customerBookingsProvider(null));
    final remindersAsync = ref.watch(customerServiceRemindersProvider);
    final ordersAsync = ref.watch(customerServiceOrdersProvider(null));

    final vehicles = vehiclesAsync.asData?.value ?? <Vehicle>[];
    final bookings = bookingsAsync.asData?.value ?? <Booking>[];
    final reminders = remindersAsync.asData?.value ?? [];
    final orders = ordersAsync.asData?.value ?? <ServiceOrder>[];

    final activeBookings = bookings
        .where(
          (b) =>
              b.status != BookingStatus.cancelled &&
              b.status != BookingStatus.completed,
        )
        .toList();
    final completedOrders = orders
        .where(
          (o) =>
              o.status == ServiceStatus.completed ||
              o.status == ServiceStatus.closed,
        )
        .toList();

    final Vehicle? primaryVehicle = vehicles.isNotEmpty ? vehicles.first : null;
    final Booking? upcomingBooking = activeBookings.isNotEmpty
        ? activeBookings.first
        : null;

    return SingleChildScrollView(
      padding: AppSpacing.paddingSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Welcome Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GARAGE PORTAL',
                      style: AppTypography.technical(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.fullName ?? 'Axel Zeed',
                      style: AppTypography.pageTitle(),
                    ),
                    Text(
                      authState.email ?? 'lexazeed@gmail.com',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusBadge(
                label: 'PRIORITY CLIENT',
                color: AppColors.primaryAccent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.section),

          // Customer Garage Telemetry Stat Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: AppSpacing.standard,
                  mainAxisSpacing: AppSpacing.standard,
                  mainAxisExtent: 150,
                ),
                children: [
                  StatCard(
                    title: 'My Vehicles',
                    value: '${vehicles.length} Cars',
                    technicalCode: 'GAR-FLEET',
                    badgeText: 'REGISTERED',
                    badgeColor: AppColors.info,
                    icon: Icons.directions_car_outlined,
                  ),
                  StatCard(
                    title: 'Active Bookings',
                    value: '${activeBookings.length} Queued',
                    technicalCode: 'BKG-ACT',
                    badgeText: activeBookings.isNotEmpty ? 'SCHEDULED' : 'NONE',
                    badgeColor: activeBookings.isNotEmpty
                        ? AppColors.warning
                        : AppColors.textMuted,
                    icon: Icons.calendar_today_outlined,
                  ),
                  StatCard(
                    title: 'Reminders',
                    value: '${reminders.length} Due',
                    technicalCode: 'REM-DUE',
                    badgeText: reminders.isNotEmpty ? 'ATTENTION' : 'CLEAR',
                    badgeColor: reminders.isNotEmpty
                        ? AppColors.primaryAccent
                        : AppColors.statusCompleted,
                    icon: Icons.alarm_outlined,
                  ),
                  StatCard(
                    title: 'Service History',
                    value: '${completedOrders.length} Records',
                    technicalCode: 'HIST-ARCH',
                    badgeText: 'COMPLETED',
                    badgeColor: AppColors.statusCompleted,
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.section),

          // Primary Vehicle Spotlight
          SectionHeader(
            title: 'PRIMARY VEHICLE STATUS',
            subtitle: 'Real-time telemetry and service tracking',
            action: TextButton.icon(
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('All Vehicles'),
              onPressed: () => context.go(RoutePaths.customerVehicles),
            ),
          ),
          PitCard(
            technicalLabel: primaryVehicle != null
                ? 'GARAGE • ${primaryVehicle.displayName.toUpperCase()} (${primaryVehicle.modelYear ?? 2024})'
                : 'GARAGE • NO REGISTERED VEHICLES',
            child: primaryVehicle == null
                ? Column(
                    children: [
                      const Icon(
                        Icons.directions_car_outlined,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No vehicles registered in your garage yet.',
                        style: AppTypography.bodyMedium(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Register Vehicle'),
                        onPressed: () =>
                            context.go(RoutePaths.customerVehicles),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: AppColors.primaryAccent,
                            size: 26,
                          ),
                          const SizedBox(width: AppSpacing.compact),
                          Expanded(
                            child: Text(
                              primaryVehicle.displayName,
                              style: AppTypography.sectionTitle(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // License plate placed BELOW car name as required to prevent overlap
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          StatusBadge(
                            label: primaryVehicle.identifierLabel,
                            color: AppColors.primaryAccent,
                          ),
                          if (primaryVehicle.color != null)
                            Text(
                              'Color: ${primaryVehicle.color}',
                              style: AppTypography.bodySmall(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          Text(
                            '•  Odometer: ${primaryVehicle.mileageKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} KM',
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      const Divider(color: AppColors.borderSubtle, height: 1),
                      const SizedBox(height: AppSpacing.compact),
                      Wrap(
                        spacing: AppSpacing.section,
                        runSpacing: AppSpacing.compact,
                        children: [
                          _buildMeta(
                            'Upcoming Service',
                            upcomingBooking?.requestedService ??
                                'Annual Inspection & Fluids',
                          ),
                          _buildMeta(
                            'Status',
                            upcomingBooking != null
                                ? 'Appointment ${upcomingBooking.status.label} (${upcomingBooking.preferredDate ?? 'Pending'})'
                                : 'No appointment pending',
                          ),
                          _buildMeta('Assigned Bay', 'Bay 1 (Master Tech)'),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.section),

          // Quick Navigation Shortcuts
          SectionHeader(
            title: 'CUSTOMER ACTIONS',
            subtitle: 'Direct links to appointments, records, and reminders',
          ),
          Wrap(
            spacing: AppSpacing.standard,
            runSpacing: AppSpacing.standard,
            children: [
              _buildQuickCard(
                context,
                title: 'My Vehicles',
                subtitle: 'Manage garage fleet',
                icon: Icons.directions_car_outlined,
                route: RoutePaths.customerVehicles,
              ),
              _buildQuickCard(
                context,
                title: 'Appointments',
                subtitle: 'View booking status',
                icon: Icons.calendar_today_outlined,
                route: RoutePaths.customerBookings,
              ),
              _buildQuickCard(
                context,
                title: 'Service History',
                subtitle: 'Invoices & records',
                icon: Icons.receipt_long_outlined,
                route: RoutePaths.customerHistory,
              ),
              _buildQuickCard(
                context,
                title: 'Maintenance Reminders',
                subtitle: 'Track scheduled upkeep',
                icon: Icons.alarm_outlined,
                route: RoutePaths.customerReminders,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTypography.technical(color: AppColors.textMuted),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodySmall(color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    return SizedBox(
      width: 220,
      child: PitCard(
        onTap: () => context.go(route),
        padding: const EdgeInsets.all(AppSpacing.standard),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.compact),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Icon(icon, color: AppColors.primaryAccent, size: 20),
            ),
            const SizedBox(width: AppSpacing.standard),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label(color: AppColors.textPrimary),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
