import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';

/// FR-102: email-or-username + password. `must_change_password` is
/// persisted by `AuthNotifier.login()` (API.md §2 — only `Token` responses
/// carry it; `GET /auth/me` never does).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailOrUsernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your email/username and password');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).login(
            emailOrUsername: _emailOrUsernameController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TriptelScaffold(
      key: const ValueKey('login-screen'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Sign in', style: AppTypography.title()),
          const SizedBox(height: 24),
          TextField(
            key: const ValueKey('login-email-or-username'),
            controller: _emailOrUsernameController,
            decoration: const InputDecoration(labelText: 'Email or username'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('login-password'),
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: AppTypography.caption(color: AppColors.danger)),
          ],
          const SizedBox(height: 24),
          PillButton(
            key: const ValueKey('login-submit'),
            label: _submitting ? 'Signing in…' : 'Sign in',
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: 12),
          PillButton(
            label: 'Create an account instead',
            variant: PillButtonVariant.text,
            onPressed: () => context.go('/register'),
          ),
        ],
      ),
    );
  }
}
