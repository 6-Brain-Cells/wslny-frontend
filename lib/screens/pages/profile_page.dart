import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wslny/config/app_colors.dart';
import 'package:wslny/config/routes.dart';
import 'package:wslny/providers/auth_provider.dart';
import 'package:wslny/providers/theme_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final name = user?.fullName ?? 'Ahmed Hassan';
    final email = user?.email ?? 'ahmed.hassan@example.com';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _HeaderCard(name: name, email: email),
            const SizedBox(height: 16),
            _QuickSettingsCard(
              onLanguageTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.languageSelection,
                  arguments: true,
                );
              },
            ),
            const SizedBox(height: 16),
            const _SignOutButton(),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final String email;

  const _HeaderCard({
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSettingsCard extends StatelessWidget {
  final VoidCallback onLanguageTap;

  const _QuickSettingsCard({required this.onLanguageTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          _SettingsRow(
            icon: Icons.language_rounded,
            label: 'Language',
            onTap: onLanguageTap,
          ),
          const _SettingsRow(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            hasSwitch: true,
            initialSwitchValue: true,
          ),
          _DarkModeRow(),
          const _SettingsRow(
            icon: Icons.lock_outline,
            label: 'Privacy & Security',
          ),
          const _SettingsRow(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
          ),
          const _SettingsRow(
            icon: Icons.info_outline_rounded,
            label: 'About Wslny',
          ),
        ],
      ),
    );
  }
}

class _DarkModeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.dark_mode_outlined, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(
        'Dark Mode',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Switch(
        value: isDark,
        activeColor: theme.colorScheme.primary,
        onChanged: (v) {
          themeProvider.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
        },
      ),
    );
  }
}

class _SettingsRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool hasSwitch;
  final bool initialSwitchValue;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.hasSwitch = false,
    this.initialSwitchValue = false,
    this.onTap,
  });

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialSwitchValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: widget.onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(widget.icon, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(
        widget.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: widget.hasSwitch
          ? Switch(
              value: _value,
              activeColor: theme.colorScheme.primary,
              onChanged: (v) => setState(() => _value = v),
            )
          : Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.4)),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await context.read<AuthProvider>().signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.signIn,
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout_rounded,
            size: 18, color: AppColors.error),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

