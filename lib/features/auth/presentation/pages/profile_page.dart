import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/theme_state.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _headerOffset = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _headerOffset.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    // Cap the offset at 120 which is the height we'll collapse
    if (offset < 0) {
      if (_headerOffset.value != 0) _headerOffset.value = 0;
    } else if (offset <= 120) {
      _headerOffset.value = offset;
    } else if (_headerOffset.value != 120) {
      _headerOffset.value = 120;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow gradient to show
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            context.go('/login');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;
            return Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // ── Animated Header (Nav + User Info) ──
                    ValueListenableBuilder<double>(
                      valueListenable: _headerOffset,
                      builder: (context, offset, _) {
                        final double opacity = (1.0 - (offset / 100)).clamp(
                          0.0,
                          1.0,
                        );
                        final double userInfoHeight = (180 - offset).clamp(
                          0.0,
                          180.0,
                        );

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            children: [
                              // Nav Bar (Always visible)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => context.pop(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Profile',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),

                              // Shrinking User Info section
                              SizedBox(
                                height: userInfoHeight,
                                child: Opacity(
                                  opacity: opacity,
                                  child: SingleChildScrollView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 12),
                                        // User Avatar
                                        Hero(
                                          tag: 'profile_btn',
                                          child: Material(
                                            type: MaterialType.transparency,
                                            child: CircleAvatar(
                                              radius: 44,
                                              backgroundColor: Colors.white
                                                  .withAlpha(50),
                                              child: CircleAvatar(
                                                radius: 40,
                                                backgroundColor: Colors.white,
                                                child: Text(
                                                  user
                                                              .displayName
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? user.displayName![0]
                                                            .toUpperCase()
                                                      : user.email[0]
                                                            .toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          user.displayName ?? 'User',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.email,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: Colors.white.withAlpha(
                                                  200,
                                                ),
                                              ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // ── Floating Sheet (Settings) ──
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(24),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // ── Appearance ──
                            const _SectionHeader(title: 'Appearance'),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 0,
                              color: theme.cardTheme.color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: theme.dividerColor.withAlpha(20),
                                ),
                              ),
                              child: BlocBuilder<ThemeCubit, ThemeState>(
                                builder: (context, themeState) {
                                  return RadioGroup<AppThemeMode>(
                                    groupValue: themeState.themeMode,
                                    onChanged: (val) {
                                      if (val != null) {
                                        context.read<ThemeCubit>().updateTheme(
                                          val,
                                        );
                                      }
                                    },
                                    child: Column(
                                      children: [
                                        _SettingsTile(
                                          icon: Icons.light_mode_rounded,
                                          title: 'Light Mode',
                                          trailing: const Radio<AppThemeMode>(
                                            value: AppThemeMode.light,
                                          ),
                                          onTap: () => context
                                              .read<ThemeCubit>()
                                              .updateTheme(AppThemeMode.light),
                                        ),
                                        Divider(
                                          height: 1,
                                          indent: 56,
                                          color: theme.dividerColor.withAlpha(
                                            20,
                                          ),
                                        ),
                                        _SettingsTile(
                                          icon: Icons.dark_mode_rounded,
                                          title: 'Dark Mode',
                                          trailing: const Radio<AppThemeMode>(
                                            value: AppThemeMode.dark,
                                          ),
                                          onTap: () => context
                                              .read<ThemeCubit>()
                                              .updateTheme(AppThemeMode.dark),
                                        ),
                                        Divider(
                                          height: 1,
                                          indent: 56,
                                          color: theme.dividerColor.withAlpha(
                                            20,
                                          ),
                                        ),
                                        _SettingsTile(
                                          icon: Icons.brightness_auto_rounded,
                                          title: 'System Default',
                                          trailing: const Radio<AppThemeMode>(
                                            value: AppThemeMode.system,
                                          ),
                                          onTap: () => context
                                              .read<ThemeCubit>()
                                              .updateTheme(AppThemeMode.system),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Account Settings ──
                            const _SectionHeader(title: 'Account'),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 0,
                              color: theme.cardTheme.color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: theme.dividerColor.withAlpha(20),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _SettingsTile(
                                    icon: Icons.edit_rounded,
                                    title: 'Edit Name',
                                    onTap: () => _showEditNameDialog(
                                      context,
                                      user.displayName,
                                    ),
                                  ),
                                  Divider(
                                    height: 1,
                                    indent: 56,
                                    color: theme.dividerColor.withAlpha(20),
                                  ),
                                  _SettingsTile(
                                    icon: Icons.lock_rounded,
                                    title: 'Change Password',
                                    onTap: () =>
                                        _showChangePasswordDialog(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Notifications ──
                            const _SectionHeader(title: 'Notifications'),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 0,
                              color: theme.cardTheme.color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: theme.dividerColor.withAlpha(20),
                                ),
                              ),
                              child: BlocBuilder<SettingsCubit, SettingsState>(
                                builder: (context, settingsState) {
                                  return _SettingsTile(
                                    icon: Icons.notifications_active_rounded,
                                    title: 'Task Reminders',
                                    trailing: Switch(
                                      value: settingsState.notificationsEnabled,
                                      onChanged: (val) {
                                        context
                                            .read<SettingsCubit>()
                                            .toggleNotifications(val);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 40),

                            // ── Sign Out ──
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.read<AuthBloc>().add(
                                    SignOutRequested(),
                                  );
                                },
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Sign Out'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(
                                    color: AppTheme.errorColor.withAlpha(100),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: Text(
                                'Version 1.0.0',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    100,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, String? currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AuthBloc>().add(
                UpdateProfileRequested(controller.text),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AuthBloc>().add(
                ChangePasswordRequested(
                  currentPassword: currentController.text,
                  newPassword: newController.text,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
