import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../injection_container.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadTwoFactorStatus();
  }

  void _loadTwoFactorStatus() {
    final prefs = sl<SharedPreferences>();
    setState(() {
      _twoFactorEnabled =
          prefs.getBool(AppConstants.keyTwoFactorEnabled) ?? false;
    });
  }

  Future<void> _openTwoFactor() async {
    await context.push(AppRoutes.twoFactor);
    if (mounted) _loadTwoFactorStatus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Cài đặt tài khoản',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Bảo mật', textTheme, colorScheme),
            _buildListTile(
              context,
              icon: Icons.lock_outline,
              title: 'Đổi mật khẩu',
              subtitle: 'Xác nhận mật khẩu hiện tại để thay đổi',
              onTap: () {
                context.push(AppRoutes.changePassword);
              },
            ),
            _buildListTile(
              context,
              icon: Icons.security_outlined,
              title: 'Xác thực 2 bước',
              subtitle: _twoFactorEnabled ? 'Đang bật' : 'Đang tắt',
              onTap: _openTwoFactor,
            ),
            _buildListTile(
              context,
              icon: Icons.history,
              title: 'Lịch sử hoạt động',
              subtitle: 'Xem các thay đổi và lần đăng nhập gần đây',
              onTap: () => context.push(AppRoutes.activity),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('Giao diện', textTheme, colorScheme),
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return _buildSwitchTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Chế độ tối',
                  value: themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    context.read<ThemeCubit>().updateTheme(
                      val ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colorScheme.onSurfaceVariant),
      ),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colorScheme.onSurfaceVariant),
      ),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
