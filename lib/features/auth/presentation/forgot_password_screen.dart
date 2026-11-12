import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';
import '../application/register_validation.dart';

/// FR-104: request a password-reset link in-app. The backend always
/// returns the same generic success, whether or not the email exists
/// (API.md §2 — never enumerate). The emailed link opens the **web** reset
/// page; this app has no deep link for it, so say so on screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  String? _error;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(authApiProvider)
          .forgotPassword(email: _emailController.text.trim());
      if (mounted) setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('forgot-password-screen'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Reset your password', style: AppTypography.title()),
          const SizedBox(height: 12),
          if (_submitted)
            Text(
              key: const ValueKey('forgot-password-success'),
              "If an account exists for that email, we've sent a reset link. "
              "Open it on your phone or computer's browser to finish — "
              'the link opens on the web, not in this app.',
              style: AppTypography.body(color: AppColors.inkMuted),
            )
          else ...[
            Text(
              "Enter your account email and we'll send a reset link to it.",
              style: AppTypography.body(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 24),
            TextField(
              key: const ValueKey('forgot-password-email'),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: AppTypography.caption(color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
            PillButton(
              key: const ValueKey('forgot-password-submit'),
              label: _submitting ? 'Sending…' : 'Send reset link',
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ],
      ),
    );
  }
}
