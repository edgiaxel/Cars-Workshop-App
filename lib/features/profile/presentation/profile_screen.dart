import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/domain/user_profile.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Universal Profile Screen for PitMate allowing profile editing,
/// email update with verification dispatch, and password changes.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _personalFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();

  final _newEmailController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _isLoadingProfile = true;
  bool _isSavingPersonal = false;
  bool _isUpdatingEmail = false;
  bool _isUpdatingPassword = false;

  String? _statusMessage;
  bool _isStatusError = false;

  UserProfile? _currentProfile;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _newEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoadingProfile = true;
      _statusMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) context.go(RoutePaths.login);
        return;
      }

      _currentEmail = user.email;

      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (res != null) {
        _currentProfile = UserProfile.fromJson(res);
      } else {
        _currentProfile = UserProfile(
          id: user.id,
          role: UserRole.fromString(user.userMetadata?['role'] as String?),
          fullName: (user.userMetadata?['full_name'] ?? user.email?.split('@').first) as String? ?? 'User',
          phoneNumber: user.userMetadata?['phone'] as String?,
          isEmailVerified: user.emailConfirmedAt != null,
        );
      }

      _nameController.text = _currentProfile?.fullName ?? '';
      _phoneController.text = _currentProfile?.phoneNumber ?? '';
      _companyController.text = _currentProfile?.companyName ?? '';
    } catch (e) {
      _statusMessage = 'Failed to load profile: $e';
      _isStatusError = true;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _savePersonalInfo() async {
    if (!(_personalFormKey.currentState?.validate() ?? false)) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSavingPersonal = true;
      _statusMessage = null;
    });

    try {
      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();
      final newCompany = _companyController.text.trim();

      // Update auth user metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': newName,
            if (newPhone.isNotEmpty) 'phone': newPhone,
            if (newCompany.isNotEmpty) 'company_name': newCompany,
          },
        ),
      );

      // Update public.profiles
      await Supabase.instance.client.from('profiles').update({
        'full_name': newName,
        'phone_number': newPhone.isNotEmpty ? newPhone : null,
        if (newCompany.isNotEmpty) 'company_name': newCompany,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Update public.customers if user is a customer
      if (_currentProfile?.role == UserRole.customer) {
        await Supabase.instance.client.from('customers').update({
          'full_name': newName,
          'phone_number': newPhone.isNotEmpty ? newPhone : null,
          if (newCompany.isNotEmpty) 'company_name': newCompany,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('profile_id', user.id);
      }

      ref.read(authNotifierProvider.notifier).checkAuthStatus();

      if (mounted) {
        setState(() {
          _currentProfile = _currentProfile?.copyWith(
            fullName: newName,
            phoneNumber: newPhone.isNotEmpty ? newPhone : null,
            companyName: newCompany.isNotEmpty ? newCompany : null,
          );
          _statusMessage = 'Profile information saved successfully.';
          _isStatusError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error updating profile: $e';
          _isStatusError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPersonal = false;
        });
      }
    }
  }

  Future<void> _updateEmail() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    final newEmail = _newEmailController.text.trim();
    if (newEmail.toLowerCase() == _currentEmail?.toLowerCase()) {
      setState(() {
        _statusMessage = 'New email address matches your current registered email.';
        _isStatusError = true;
      });
      return;
    }

    setState(() {
      _isUpdatingEmail = true;
      _statusMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      if (mounted) {
        setState(() {
          _statusMessage = 'Verification link dispatched to $newEmail. Please open the confirmation link in your email to finalize the address update.';
          _isStatusError = false;
          _newEmailController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to request email update: $e';
          _isStatusError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingEmail = false;
        });
      }
    }
  }

  Future<void> _updatePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isUpdatingPassword = true;
      _statusMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );
      if (mounted) {
        setState(() {
          _statusMessage = 'Password changed successfully.';
          _isStatusError = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to change password: $e';
          _isStatusError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userProfile = authState is AuthAuthenticated
        ? authState.userProfile
        : (_currentProfile ?? const UserProfile(id: '', role: UserRole.customer, fullName: 'User'));

    final role = userProfile.role;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    final roleTitle = switch (role) {
      UserRole.admin => 'Workshop Administration',
      UserRole.mechanic => 'Mechanic Operations',
      UserRole.customer => 'Customer Account',
    };

    final navItems = switch (role) {
      UserRole.admin => RoleNavigation.adminNavItems,
      UserRole.mechanic => RoleNavigation.mechanicNavItems,
      UserRole.customer => RoleNavigation.customerNavItems,
    };

    return ResponsiveRoleScaffold(
      roleTitle: roleTitle,
      userName: userProfile.fullName.isNotEmpty ? userProfile.fullName : 'Account',
      userSubtitle: role.displayName,
      navItems: navItems,
      currentIndex: -1,
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          switch (role) {
            case UserRole.admin:
              context.go(RoutePaths.admin);
            case UserRole.mechanic:
              context.go(RoutePaths.mechanic);
            case UserRole.customer:
              context.go(RoutePaths.customerGarage);
          }
        }
      },
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: AppColors.racingRed))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card with Avatar and Role Status
                      _buildHeaderCard(userProfile, textColor, isDark),
                      const SizedBox(height: AppSpacing.space16),

                      // Status Notification Banner
                      if (_statusMessage != null) ...[
                        _buildStatusBanner(),
                        const SizedBox(height: AppSpacing.space16),
                      ],

                      // Personal Information Section
                      _buildPersonalInfoCard(textColor, isDark),
                      const SizedBox(height: AppSpacing.space16),

                      // Email Management & Verification Section
                      _buildEmailCard(textColor, isDark),
                      const SizedBox(height: AppSpacing.space16),

                      // Security & Password Section
                      _buildSecurityCard(textColor, isDark),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(UserProfile profile, Color textColor, bool isDark) {
    return PitCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.racingRed,
              child: Text(
                profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: AppSpacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.space8,
                    runSpacing: 4,
                    children: [
                      Text(
                        profile.fullName.isNotEmpty ? profile.fullName : 'Account Profile',
                        style: AppTypography.headlineSmall(color: textColor).copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      StatusBadge(
                        label: profile.role.displayName.toUpperCase(),
                        color: AppColors.racingRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    _currentEmail ?? 'No email associated',
                    style: AppTypography.bodyMedium(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final color = _isStatusError ? AppColors.danger : AppColors.success;
    final icon = _isStatusError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedSmall,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              _statusMessage!,
              style: AppTypography.bodyMedium(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(Color textColor, bool isDark) {
    return PitCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Form(
          key: _personalFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Personal Information',
                style: AppTypography.headlineSmall(color: textColor).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Full Name
              TextFormField(
                key: const Key('profile_name_field'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              // Phone Number
              TextFormField(
                key: const Key('profile_phone_field'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              if (_currentProfile?.role == UserRole.customer) ...[
                const SizedBox(height: AppSpacing.space16),
                TextFormField(
                  key: const Key('profile_company_field'),
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name (Optional)',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.space16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  key: const Key('profile_save_personal_button'),
                  onPressed: _isSavingPersonal ? null : _savePersonalInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.racingRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: _isSavingPersonal
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailCard(Color textColor, bool isDark) {
    final isVerified = _currentProfile?.isEmailVerified ?? false;

    return PitCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Form(
          key: _emailFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.space8,
                runSpacing: AppSpacing.space8,
                children: [
                  Text(
                    'Email Address & Verification',
                    style: AppTypography.headlineSmall(color: textColor).copyWith(fontWeight: FontWeight.bold),
                  ),
                  StatusBadge(
                    label: isVerified ? 'VERIFIED' : 'UNVERIFIED',
                    color: isVerified ? AppColors.success : AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'Current: ${_currentEmail ?? "Not available"}',
                style: AppTypography.bodyMedium(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              TextFormField(
                key: const Key('profile_new_email_field'),
                controller: _newEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'New Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'A verification link will be sent to confirm your new email.',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a new email address';
                  }
                  if (!RegExp(r'^[\w\-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(val.trim())) {
                    return 'Please enter a valid email format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  key: const Key('profile_update_email_button'),
                  onPressed: _isUpdatingEmail ? null : _updateEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.graphitePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: _isUpdatingEmail
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Send Verification Link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityCard(Color textColor, bool isDark) {
    return PitCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Security & Password',
                style: AppTypography.headlineSmall(color: textColor).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.space16),

              TextFormField(
                key: const Key('profile_new_password_field'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              TextFormField(
                key: const Key('profile_confirm_password_field'),
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  key: const Key('profile_change_password_button'),
                  onPressed: _isUpdatingPassword ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.racingRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: _isUpdatingPassword
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.lock_reset, size: 18),
                  label: const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
