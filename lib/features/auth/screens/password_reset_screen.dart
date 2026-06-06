// Password reset screen — allows users to request a password reset email.
//
// Users enter their email address and receive a reset link from Supabase.
// The link directs them to Supabase's hosted password reset page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.field_required;
    }
    final emailRegex = RegExp(r'^[\w\-\.\+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppLocalizations.of(context)!.invalid_email;
    }
    return null;
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(authNotifierProvider.notifier);

    final success = await notifier.sendPasswordReset(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() => _success = true);
    } else {
      final state = ref.read(authNotifierProvider).valueOrNull;
      final errorKey = state?.error ?? 'password_reset_failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_resolveL10n(l10n, errorKey)),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  String _resolveL10n(AppLocalizations l10n, String key) {
    return switch (key) {
      'password_reset_failed' => l10n.password_reset_failed,
      'invalid_email' => l10n.invalid_email,
      'network_error' => l10n.network_error,
      _ => l10n.something_went_wrong,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.password_reset)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.lock_reset_outlined,
                size: 64,
                color: AppColors.deepBlue,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.password_reset,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.enter_email_for_reset,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_success)
                _SuccessMessage(l10n: l10n, email: _emailController.text.trim())
              else
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _handleReset(),
                  enabled: !isLoading,
                ),
              const SizedBox(height: 24),
              if (!_success)
                FilledButton(
                  onPressed: isLoading ? null : _handleReset,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.send_reset_link),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessMessage extends StatelessWidget {
  final AppLocalizations l10n;
  final String email;

  const _SuccessMessage({required this.l10n, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.password_reset_sent,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
