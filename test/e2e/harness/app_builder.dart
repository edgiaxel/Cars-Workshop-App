import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/config/app_config.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/router/route_paths.dart';

import 'models/e2e_user_profile.dart';
import 'models/e2e_customer.dart';
import 'models/e2e_vehicle.dart';
import 'repositories/fake_auth_repository.dart';
import 'repositories/fake_customer_repository.dart';
import 'repositories/fake_vehicle_repository.dart';
import 'test_providers.dart';

/// Test application builder for full widget tree E2E verification.
class TestAppBuilder {
  final FakeAuthRepository authRepo;
  final FakeCustomerRepository customerRepo;
  final FakeVehicleRepository vehicleRepo;
  final ThemeMode initialThemeMode;
  final String initialRoute;

  TestAppBuilder({
    required this.authRepo,
    required this.customerRepo,
    required this.vehicleRepo,
    this.initialThemeMode = ThemeMode.dark,
    this.initialRoute = RoutePaths.login,
  });

  Widget build() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        customerRepositoryProvider.overrideWithValue(customerRepo),
        vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
      ],
      child: _TestAppRoot(
        initialThemeMode: initialThemeMode,
        initialRoute: initialRoute,
      ),
    );
  }
}

class _TestAppRoot extends ConsumerStatefulWidget {
  final ThemeMode initialThemeMode;
  final String initialRoute;

  const _TestAppRoot({
    required this.initialThemeMode,
    required this.initialRoute,
  });

  @override
  ConsumerState<_TestAppRoot> createState() => _TestAppRootState();
}

class _TestAppRootState extends ConsumerState<_TestAppRoot> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: widget.initialRoute,
      redirect: (context, state) {
        final authState = ref.read(authControllerProvider);
        final user = authState.asData?.value;
        final isAuthenticated = user != null;
        final path = state.matchedLocation;

        final isAuthPath =
            path == RoutePaths.login || path == RoutePaths.register;

        if (!isAuthenticated) {
          return isAuthPath ? null : RoutePaths.login;
        }

        // Role-based protection
        if (isAuthPath || path == RoutePaths.initial) {
          return switch (user.role) {
            UserRole.admin => RoutePaths.admin,
            UserRole.mechanic => RoutePaths.mechanic,
            UserRole.customer => RoutePaths.customer,
          };
        }

        // Restrict role workspaces
        if (path.startsWith(RoutePaths.admin) && user.role != UserRole.admin) {
          return '/unauthorized';
        }
        if (path.startsWith(RoutePaths.mechanic) &&
            user.role != UserRole.mechanic) {
          return '/unauthorized';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RoutePaths.initial,
          builder: (context, state) => const _LandingScreen(),
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const _LoginScreen(),
        ),
        GoRoute(
          path: RoutePaths.register,
          builder: (context, state) => const _RegisterScreen(),
        ),
        GoRoute(
          path: '/unauthorized',
          builder: (context, state) => const _UnauthorizedScreen(),
        ),

        // Admin Shell Routes
        ShellRoute(
          builder: (context, state, child) =>
              _ResponsiveShell(role: UserRole.admin, child: child),
          routes: [
            GoRoute(
              path: RoutePaths.admin,
              builder: (context, state) => const _AdminDashboardScreen(),
            ),
            GoRoute(
              path: '/admin/customers',
              builder: (context, state) => const _AdminCustomersScreen(),
            ),
            GoRoute(
              path: '/admin/vehicles',
              builder: (context, state) => const _AdminVehiclesScreen(),
            ),
          ],
        ),

        // Mechanic Shell Routes
        ShellRoute(
          builder: (context, state, child) =>
              _ResponsiveShell(role: UserRole.mechanic, child: child),
          routes: [
            GoRoute(
              path: RoutePaths.mechanic,
              builder: (context, state) => const _MechanicTasksScreen(),
            ),
            GoRoute(
              path: RoutePaths.mechanicTasks,
              builder: (context, state) => const _MechanicTasksScreen(),
            ),
          ],
        ),

        // Customer Shell Routes
        ShellRoute(
          builder: (context, state, child) =>
              _ResponsiveShell(role: UserRole.customer, child: child),
          routes: [
            GoRoute(
              path: RoutePaths.customer,
              builder: (context, state) => const _CustomerGarageScreen(),
            ),
            GoRoute(
              path: RoutePaths.customerGarage,
              builder: (context, state) => const _CustomerGarageScreen(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

// -----------------------------------------------------------------------------
// Universal Responsive Shell (Desktop Sidebar, Tablet Rail, Mobile Bottom Nav)
// -----------------------------------------------------------------------------

class _ResponsiveShell extends ConsumerWidget {
  final UserRole role;
  final Widget child;

  const _ResponsiveShell({required this.role, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final user = ref.watch(authControllerProvider).asData?.value;
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final themeMode = ref.watch(themeNotifierProvider);

    final destinations = switch (role) {
      UserRole.admin => const [
          _NavDestination(icon: Icons.dashboard, label: 'Dashboard', path: RoutePaths.admin),
          _NavDestination(icon: Icons.people, label: 'Customers', path: '/admin/customers'),
          _NavDestination(icon: Icons.directions_car, label: 'Vehicles', path: '/admin/vehicles'),
        ],
      UserRole.mechanic => const [
          _NavDestination(icon: Icons.build, label: 'Tasks', path: RoutePaths.mechanic),
          _NavDestination(icon: Icons.history, label: 'Diagnostics', path: RoutePaths.mechanicTasks),
        ],
      UserRole.customer => const [
          _NavDestination(icon: Icons.garage, label: 'Garage', path: RoutePaths.customer),
          _NavDestination(icon: Icons.calendar_month, label: 'Bookings', path: RoutePaths.customerGarage),
        ],
    };

    final isDesktop = width >= 1024;
    final isTablet = width >= 600 && width < 1024;
    final isMobile = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppConfig.appName} — ${role.name.toUpperCase()}'),
        actions: [
          IconButton(
            key: const Key('theme_toggle_button'),
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: () => themeNotifier.toggleTheme(),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  user.fullName,
                  key: const Key('user_profile_name'),
                  style: AppTypography.label(),
                ),
              ),
            ),
          IconButton(
            key: const Key('sign_out_button'),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go(RoutePaths.login);
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Desktop Permanent Sidebar
          if (isDesktop)
            Container(
              key: const Key('desktop_sidebar'),
              width: 240,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: ListView(
                children: destinations.map((d) {
                  return ListTile(
                    leading: Icon(d.icon),
                    title: Text(d.label),
                    onTap: () => context.go(d.path),
                  );
                }).toList(),
              ),
            ),

          // Tablet Navigation Rail
          if (isTablet)
            NavigationRail(
              key: const Key('tablet_nav_rail'),
              selectedIndex: 0,
              onDestinationSelected: (idx) => context.go(destinations[idx].path),
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                );
              }).toList(),
            ),

          // Main View Content
          Expanded(child: child),
        ],
      ),
      // Mobile Bottom Navigation Bar
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              key: const Key('mobile_bottom_nav'),
              currentIndex: 0,
              onTap: (idx) => context.go(destinations[idx].path),
              items: destinations.map((d) {
                return BottomNavigationBarItem(
                  icon: Icon(d.icon),
                  label: d.label,
                );
              }).toList(),
            )
          : null,
    );
  }
}

class _NavDestination {
  final IconData icon;
  final String label;
  final String path;

  const _NavDestination({
    required this.icon,
    required this.label,
    required this.path,
  });
}

// -----------------------------------------------------------------------------
// Authentication Screens
// -----------------------------------------------------------------------------

class _LandingScreen extends StatelessWidget {
  const _LandingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppConfig.appName, style: AppTypography.headingLarge()),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('landing_login_button'),
              onPressed: () => context.go(RoutePaths.login),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginScreen extends ConsumerStatefulWidget {
  const _LoginScreen();

  @override
  ConsumerState<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<_LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@pitmate.com');
  final _passwordController = TextEditingController(text: 'password123');
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);
    try {
      await ref.read(authControllerProvider.notifier).signIn(
            _emailController.text,
            _passwordController.text,
          );
      final user = ref.read(authControllerProvider).asData?.value;
      if (!mounted) return;
      if (user != null) {
        final target = switch (user.role) {
          UserRole.admin => RoutePaths.admin,
          UserRole.mechanic => RoutePaths.mechanic,
          UserRole.customer => RoutePaths.customer,
        };
        context.go(target);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('login_screen'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sign In to ${AppConfig.appName}',
                        style: AppTypography.headingMedium()),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Container(
                        key: const Key('login_error_message'),
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppColors.error.withValues(alpha: 0.1),
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: AppColors.error)),
                      ),
                    TextField(
                      key: const Key('login_email_input'),
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('login_password_input'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      key: const Key('login_submit_button'),
                      onPressed: _handleLogin,
                      child: const Text('Sign In'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: const Key('register_link_button'),
                      onPressed: () => context.go(RoutePaths.register),
                      child: const Text("Don't have an account? Register"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterScreen extends ConsumerStatefulWidget {
  const _RegisterScreen();

  @override
  ConsumerState<_RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<_RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);
    try {
      await ref.read(authControllerProvider.notifier).signUp(
            _emailController.text,
            _passwordController.text,
            _nameController.text,
          );
      if (!mounted) return;
      context.go(RoutePaths.customer);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('register_screen'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Create Customer Account',
                        style: AppTypography.headingMedium()),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Container(
                        key: const Key('register_error_message'),
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppColors.error.withValues(alpha: 0.1),
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: AppColors.error)),
                      ),
                    TextField(
                      key: const Key('register_name_input'),
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('register_email_input'),
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('register_password_input'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      key: const Key('register_submit_button'),
                      onPressed: _handleRegister,
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnauthorizedScreen extends ConsumerWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: const Key('unauthorized_screen'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Access Denied', style: AppTypography.headingLarge()),
            const SizedBox(height: 8),
            const Text('You do not have permission to access this workspace.'),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('unauthorized_back_button'),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(RoutePaths.login);
                }
              },
              child: const Text('Return to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Role-Specific Screen Implementations
// -----------------------------------------------------------------------------

class _AdminDashboardScreen extends StatelessWidget {
  const _AdminDashboardScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('admin_dashboard_screen'),
      body: Center(child: Text('Admin Operations Dashboard')),
    );
  }
}

class _AdminCustomersScreen extends ConsumerStatefulWidget {
  const _AdminCustomersScreen();

  @override
  ConsumerState<_AdminCustomersScreen> createState() =>
      _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<_AdminCustomersScreen> {
  final _searchController = TextEditingController();
  bool _onlyGuests = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CustomerFormDialog(
        onSaved: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerRepo = ref.watch(customerRepositoryProvider);

    return Scaffold(
      key: const Key('admin_customers_screen'),
      body: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('customer_search_field'),
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search customer name, phone, or email...',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Text('Only Guests:'),
                    Switch(
                      key: const Key('guest_filter_switch'),
                      value: _onlyGuests,
                      onChanged: (v) => setState(() => _onlyGuests = v),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  key: const Key('add_customer_button'),
                  onPressed: _openAddCustomerDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Customer'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Customer>>(
                future: customerRepo.getCustomers(
                  search: _searchController.text,
                  isGuest: _onlyGuests ? true : null,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final customers = snapshot.data ?? [];
                  if (customers.isEmpty) {
                    return const Center(
                      child: Text('No customers found.',
                          key: Key('customers_empty_state')),
                    );
                  }
                  return ListView.builder(
                    key: const Key('customer_list_view'),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final c = customers[index];
                      return Card(
                        child: ListTile(
                          title: Text(c.name),
                          subtitle: Text(
                              'Phone: ${c.phone} | ${c.isGuest ? "GUEST" : "REGISTERED"}'),
                          trailing: c.isGuest
                              ? const Chip(label: Text('Walk-In Guest'))
                              : const Chip(label: Text('Account')),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerFormDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaved;

  const _CustomerFormDialog({required this.onSaved});

  @override
  ConsumerState<_CustomerFormDialog> createState() =>
      _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<_CustomerFormDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isGuest = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    setState(() => _errorMessage = null);
    try {
      final repo = ref.read(customerRepositoryProvider);
      await repo.createCustomer(
        Customer(
          id: '',
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          isGuest: _isGuest,
        ),
      );
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('customer_form_dialog'),
      title: const Text('Add Customer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Container(
                key: const Key('customer_form_error'),
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                color: AppColors.error.withValues(alpha: 0.1),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: AppColors.error)),
              ),
            TextField(
              key: const Key('customer_name_input'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Customer Name *'),
            ),
            TextField(
              key: const Key('customer_phone_input'),
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
            ),
            TextField(
              key: const Key('customer_email_input'),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('is_guest_checkbox'),
              title: const Text('Walk-in Guest (No Account)'),
              value: _isGuest,
              onChanged: (v) => setState(() => _isGuest = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('save_customer_button'),
          onPressed: _saveCustomer,
          child: const Text('Save Customer'),
        ),
      ],
    );
  }
}

class _AdminVehiclesScreen extends ConsumerStatefulWidget {
  const _AdminVehiclesScreen();

  @override
  ConsumerState<_AdminVehiclesScreen> createState() =>
      _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends ConsumerState<_AdminVehiclesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openRegisterVehicleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _VehicleRegistrationDialog(
        onSaved: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleRepo = ref.watch(vehicleRepositoryProvider);

    return Scaffold(
      key: const Key('admin_vehicles_screen'),
      body: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('vehicle_search_field'),
                    controller: _searchController,
                    onChanged: (v) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search plate, make, model...',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  key: const Key('register_vehicle_button'),
                  onPressed: _openRegisterVehicleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Register Vehicle'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Vehicle>>(
                future: vehicleRepo.getAllVehicles(search: _searchController.text),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final vehicles = snapshot.data ?? [];
                  if (vehicles.isEmpty) {
                    return const Center(
                      child: Text('No vehicles registered.',
                          key: Key('vehicles_empty_state')),
                    );
                  }
                  return ListView.builder(
                    key: const Key('vehicle_list_view'),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final v = vehicles[index];
                      return Card(
                        child: ListTile(
                          title: Text('${v.licensePlate} — ${v.make} ${v.model}'),
                          subtitle: Text(
                              'Year: ${v.year} | Odometer: ${v.currentMileage} km | Transmission: ${v.transmission ?? "N/A"}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleRegistrationDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaved;

  const _VehicleRegistrationDialog({required this.onSaved});

  @override
  ConsumerState<_VehicleRegistrationDialog> createState() =>
      _VehicleRegistrationDialogState();
}

class _VehicleRegistrationDialogState
    extends ConsumerState<_VehicleRegistrationDialog> {
  final _customerIdController = TextEditingController(text: 'cust-001');
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController(text: '2022');
  final _mileageController = TextEditingController(text: '10000');
  final _transmissionController = TextEditingController(text: 'Automatic');
  String? _errorMessage;

  @override
  void dispose() {
    _customerIdController.dispose();
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _transmissionController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    setState(() => _errorMessage = null);
    try {
      final repo = ref.read(vehicleRepositoryProvider);
      final year = int.tryParse(_yearController.text) ?? 0;
      final mileage = int.tryParse(_mileageController.text) ?? -1;

      await repo.registerVehicle(
        Vehicle(
          id: '',
          customerId: _customerIdController.text.trim(),
          licensePlate: _plateController.text,
          make: _makeController.text,
          model: _modelController.text,
          year: year,
          currentMileage: mileage,
          transmission: _transmissionController.text,
        ),
      );
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('vehicle_registration_dialog'),
      title: const Text('Register Vehicle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Container(
                key: const Key('vehicle_form_error'),
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                color: AppColors.error.withValues(alpha: 0.1),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: AppColors.error)),
              ),
            TextField(
              key: const Key('vehicle_customer_id_input'),
              controller: _customerIdController,
              decoration: const InputDecoration(labelText: 'Customer ID *'),
            ),
            TextField(
              key: const Key('vehicle_plate_input'),
              controller: _plateController,
              decoration: const InputDecoration(labelText: 'License Plate *'),
            ),
            TextField(
              key: const Key('vehicle_make_input'),
              controller: _makeController,
              decoration: const InputDecoration(labelText: 'Make *'),
            ),
            TextField(
              key: const Key('vehicle_model_input'),
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Model *'),
            ),
            TextField(
              key: const Key('vehicle_year_input'),
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Year (1900-2100) *'),
            ),
            TextField(
              key: const Key('vehicle_mileage_input'),
              controller: _mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Current Mileage (km) *'),
            ),
            TextField(
              key: const Key('vehicle_transmission_input'),
              controller: _transmissionController,
              decoration: const InputDecoration(labelText: 'Transmission'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('save_vehicle_button'),
          onPressed: _saveVehicle,
          child: const Text('Register Vehicle'),
        ),
      ],
    );
  }
}

class _MechanicTasksScreen extends StatelessWidget {
  const _MechanicTasksScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('mechanic_tasks_screen'),
      body: Center(child: Text('Mechanic Assigned Operations Queue')),
    );
  }
}

class _CustomerGarageScreen extends ConsumerStatefulWidget {
  const _CustomerGarageScreen();

  @override
  ConsumerState<_CustomerGarageScreen> createState() => _CustomerGarageScreenState();
}

class _CustomerGarageScreenState extends ConsumerState<_CustomerGarageScreen> {
  int _refreshKey = 0;

  void _refresh() {
    setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final customerRepo = ref.watch(customerRepositoryProvider);
    final vehicleRepo = ref.watch(vehicleRepositoryProvider);

    return Scaffold(
      key: const Key('customer_garage_screen'),
      floatingActionButton: FloatingActionButton.small(
        key: const Key('garage_refresh_button'),
        onPressed: _refresh,
        child: const Icon(Icons.refresh),
      ),
      body: Padding(
        padding: AppSpacing.paddingScreen,
        child: user == null
            ? const Center(child: Text('Please log in.'))
            : FutureBuilder<Customer?>(
                key: ValueKey('cust_$_refreshKey'),
                future: customerRepo.getCustomerByProfileId(user.id),
                builder: (context, custSnapshot) {
                  if (custSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final customer = custSnapshot.data;
                  if (customer == null) {
                    return const Center(
                      child: Text('Customer profile not linked.',
                          key: Key('garage_no_profile_state')),
                    );
                  }

                  return FutureBuilder<List<Vehicle>>(
                    key: ValueKey('veh_${customer.id}_$_refreshKey'),
                    future: vehicleRepo.getVehiclesByCustomerId(customer.id),
                    builder: (context, vehSnapshot) {
                      if (vehSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final vehicles = vehSnapshot.data ?? [];
                      if (vehicles.isEmpty) {
                        return const Center(
                          child: Text(
                            'No vehicles found in garage.',
                            key: Key('garage_empty_state'),
                          ),
                        );
                      }

                      return ListView.builder(
                        key: const Key('customer_vehicles_list'),
                        itemCount: vehicles.length,
                        itemBuilder: (context, index) {
                          final v = vehicles[index];
                          return Card(
                            key: Key('garage_vehicle_${v.id}'),
                            child: ListTile(
                              leading: const Icon(Icons.directions_car),
                              title: Text('${v.licensePlate} — ${v.make} ${v.model}'),
                              subtitle: Text(
                                  'Year: ${v.year} | Mileage: ${v.currentMileage} km | Transmission: ${v.transmission ?? "N/A"}'),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
