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
  bool _pushNotifications = true;
  bool _emailNotifications = false;
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

            const SizedBox(height: 24),

            _buildSectionHeader('Giao diện', textTheme, colorScheme),
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return _buildSwitchTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Chế độ tối (Dark Mode)',
                  value: themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    context.read<ThemeCubit>().updateTheme(val ? ThemeMode.dark : ThemeMode.light);
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('Thông báo', textTheme, colorScheme),
            _buildSwitchTile(
              context,
              icon: Icons.notifications_active_outlined,
              title: 'Thông báo đẩy',
              value: _pushNotifications,
              onChanged: (val) {
                setState(() => _pushNotifications = val);
              },
            ),
            _buildSwitchTile(
              context,
              icon: Icons.email_outlined,
              title: 'Thông báo Email',
              value: _emailNotifications,
              onChanged: (val) {
                setState(() => _emailNotifications = val);
              },
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('Liên kết tài khoản', textTheme, colorScheme),
            _buildListTile(
              context,
              icon: Icons.g_mobiledata,
              title: 'Google',
              subtitle: 'Chưa liên kết',
              onTap: () {},
            ),
            _buildListTile(
              context,
              icon: Icons.facebook,
              title: 'Facebook',
              subtitle: 'Chưa liên kết',
              onTap: () {},
            ),

            const SizedBox(height: 40),

            Center(
              child: TextButton.icon(
                onPressed: () {
                  _showDeleteAccountDialog(context);
                },
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                label: Text(
                  'Xóa tài khoản',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, TextTheme textTheme, ColorScheme colorScheme) {
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

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
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
      title: Text(title, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)) : null,
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(BuildContext context, {required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
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
      title: Text(title, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeColor: colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }



  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text('Hành động này không thể hoàn tác. Mọi dữ liệu của bạn sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Tính năng đang phát triển'), backgroundColor: Theme.of(context).colorScheme.secondary),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }
}
