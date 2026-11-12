import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/deeplink/deep_link_providers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_providers.dart';
import '../application/register_validation.dart';

/// FR-101: email/username/password (+ optional phone/full name/referral
/// code, pre-filled from a `?ref=` link via FR-007) → signed in.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _referralController = TextEditingController();

  String? _error;
  bool _submitting = false;
  bool _prefilledReferral = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = validateEmail(_emailController.text);
    final usernameError = validateUsername(_usernameController.text);
    final passwordError = validateRegisterPassword(_passwordController.text);
    final firstError = emailError ?? usernameError ?? passwordError;
    if (firstError != null) {
      setState(() => _error = firstError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).register(
            email: _emailController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            fullName: _fullNameController.text.trim().isEmpty
                ? null
                : _fullNameController.text.trim(),
            referralCode: _referralController.text.trim().isEmpty
                ? null
                : _referralController.text.trim(),
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
    final pendingReferral = ref.watch(pendingReferralProvider);
    pendingReferral.whenData((code) {
      if (code != null &&
          !_prefilledReferral &&
          _referralController.text.isEmpty) {
        _referralController.text = code;
        _prefilledReferral = true;
      }
    });

    return TriptelScaffold(
      key: const ValueKey('register-screen'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Create your account', style: AppTypography.title()),
          const SizedBox(height: 24),
          TextField(
            key: const ValueKey('register-email'),
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('register-username'),
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('register-password'),
            controller: _passwordController,
            decoration:
                const InputDecoration(labelText: 'Password (min 8 characters)'),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('register-phone'),
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone (optional)'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('register-full-name'),
            controller: _fullNameController,
            decoration:
                const InputDecoration(labelText: 'Full name (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('register-referral'),
            controller: _referralController,
            decoration:
                const InputDecoration(labelText: 'Referral code (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: AppTypography.caption(color: AppColors.danger)),
          ],
          const SizedBox(height: 24),
          PillButton(
            label: _submitting ? 'Creating account…' : 'Create account',
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
