import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../injection_container.dart';
import '../cubit/two_factor_cubit.dart';
import '../widgets/auth_text_field.dart';

class TwoFactorPage extends StatelessWidget {
  const TwoFactorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TwoFactorCubit>()..loadStatus(),
      child: const _TwoFactorView(),
    );
  }
}

class _TwoFactorView extends StatefulWidget {
  const _TwoFactorView();

  @override
  State<_TwoFactorView> createState() => _TwoFactorViewState();
}

class _TwoFactorViewState extends State<_TwoFactorView> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<TwoFactorCubit, TwoFactorState>(
      listener: (context, state) {
        if (state is TwoFactorSuccess) {
          _codeController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.primary,
            ),
          );
        } else if (state is TwoFactorFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is TwoFactorLoading;
        final isEnabled = state.isEnabled;
        final setup = state.pendingSetup;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            title: Text(
              'Xác thực 2 bước',
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusCard(isEnabled: isEnabled),
                const SizedBox(height: 24),
                Text(
                  'Dùng ứng dụng Authenticator (Google Authenticator, Authy, Microsoft Authenticator…) để quét mã QR hoặc nhập khóa bí mật, rồi nhập mã 6 số để bật hoặc tắt.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (!isEnabled && setup == null) ...[
                  FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => context.read<TwoFactorCubit>().startSetup(),
                    icon: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.qr_code_2),
                    label: Text(
                      isLoading ? 'Đang tạo mã…' : 'Bắt đầu thiết lập 2FA',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
                if (setup != null) ...[
                  _SetupCard(
                    secret: setup.secret,
                    otpauthUrl: setup.otpauthUrl,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nhập mã 6 số để xác nhận bật',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _codeController,
                    hintText: 'Mã 6 số',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: isLoading
                        ? null
                        : () => context.read<TwoFactorCubit>().enable(
                            _codeController.text,
                          ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Xác nhận bật 2FA'),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            _codeController.clear();
                            context.read<TwoFactorCubit>().resetToIdle();
                          },
                    child: const Text('Hủy thiết lập'),
                  ),
                ],
                if (isEnabled && setup == null) ...[
                  Text(
                    'Nhập mã 6 số hiện tại để tắt 2FA',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _codeController,
                    hintText: 'Mã 6 số',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => context.read<TwoFactorCubit>().disable(
                            _codeController.text,
                          ),
                    icon: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.error,
                            ),
                          )
                        : Icon(Icons.lock_open, color: colorScheme.error),
                    label: Text(
                      isLoading ? 'Đang tắt…' : 'Tắt xác thực 2 bước',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isEnabled;

  const _StatusCard({required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bg = isEnabled
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;
    final fg = isEnabled
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.verified_user : Icons.gpp_bad_outlined,
            color: fg,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnabled ? 'Đang bật' : 'Đang tắt',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? 'Tài khoản được bảo vệ bằng TOTP khi đăng nhập.'
                      : 'Bật 2FA để tăng bảo mật khi đăng nhập.',
                  style: textTheme.bodySmall?.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final String secret;
  final String otpauthUrl;

  const _SetupCard({required this.secret, required this.otpauthUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Quét mã QR',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (otpauthUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: otpauthUrl,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Hoặc nhập khóa bí mật thủ công',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    secret,
                    style: textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sao chép',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: secret));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép khóa bí mật'),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.copy, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
