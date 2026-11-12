import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';
import '../application/register_validation.dart';

/// FR-105: shown when `must_change_password` is true (after login/register)
/// or a 403 "Please set your own password…" is hit on a protected endpoint
/// (API.md §0.1). A normal, navigable screen — not a blocking modal — so it
/// never prevents viewing My eSIMs or any other tab.
class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String? _error;
  bool _submitting = false;
  bool _done = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_currentPasswordController.text.isEmpty) {
      setState(() => _error = 'Enter your current password');
      return;
    }
    final passwordError = validateRegisterPassword(_newPasswordController.text);
    if (passwordError != null) {
      setState(() => _error = passwordError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (mounted) setState(() => _done = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('set-password-screen'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Set your password', style: AppTypography.title()),
          const SizedBox(height: 12),
          if (_done)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key: const ValueKey('set-password-success'),
                  'Your password is updated.',
                  style: AppTypography.body(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 24),
                PillButton(
                    label: 'Continue', onPressed: () => context.go('/home')),
              ],
            )
          else ...[
            Text(
              'Set your own password to buy eSIMs or move money. '
              "You can still browse My eSIMs without doing this now.",
              style: AppTypography.body(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 24),
            TextField(
              key: const ValueKey('set-password-current'),
              controller: _currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('set-password-new'),
              controller: _newPasswordController,
              decoration: const InputDecoration(
                  labelText: 'New password (min 8 characters)'),
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: AppTypography.caption(color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
            PillButton(
              key: const ValueKey('set-password-submit'),
              label: _submitting ? 'Saving…' : 'Save password',
              onPressed: _submitting ? null : _submit,
            ),
            const SizedBox(height: 12),
            PillButton(
              key: const ValueKey('set-password-skip'),
              label: 'Not now — go to My eSIMs',
              variant: PillButtonVariant.text,
              onPressed: () => context.go('/my-esims'),
            ),
          ],
        ],
      ),
    );
  }
}
