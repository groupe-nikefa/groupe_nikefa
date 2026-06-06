// Register screen — collects email, password, phone, and account type.
//
// Provides full form validation, password strength feedback, and
// submits to Supabase Auth via the Riverpod auth notifier.
// On success, the user is auto-logged in and redirected based on role.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/brand_name.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/password_strength_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/account_type.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // ── Form controllers ──────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // ── State ─────────────────────────────────────────────────
  AccountType _selectedAccountType = AccountType.individual;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.email;
    }
    // Basic email check — regex allows plus-addressing (user+tag@gmail.com).
    final emailRegex = RegExp(r'^[\w\-\.\+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppLocalizations.of(context)!.invalid_email;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.password;
    }
    if (value.length < 6) {
      return AppLocalizations.of(context)!.password_too_short;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.confirm_password;
    }
    if (value != _passwordController.text) {
      return AppLocalizations.of(context)!.passwords_dont_match;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.phone_required;
    }
    // Phone must contain only digits, +, -, spaces, or ().
    final phoneRegex = RegExp(r'^[\d\+\-\(\)\s]{6,20}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return AppLocalizations.of(context)!.phone_invalid;
    }
    return null;
  }

  // ── Submit handler ────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(authNotifierProvider.notifier);

    final success = await notifier.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      accountType: _selectedAccountType,
    );

    if (!mounted) return;

    if (success) {
      // Registration succeeded — user is auto-logged in.
      // Read the user to determine redirect destination.
      final user = ref.read(currentUserProvider);
      if (!mounted) return;

      // Tell the platform that the autofill context is complete so the
      // browser/OS can save the new credentials under the right fields.
      TextInput.finishAutofillContext();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.registration_success),
          backgroundColor: Colors.green,
        ),
      );

      // Redirect based on role.
      if (user?.isAdmin ?? false) {
        context.go('/admin');
      } else {
        context.go('/');
      }
    } else {
      // Show error from the notifier state.
      final state = ref.read(authNotifierProvider).valueOrNull;
      final errorKey = state?.error ?? 'something_went_wrong';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_resolveL10n(l10n, errorKey)),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  /// Resolves a localization key to its string value.
  ///
  /// This helper maps l10n keys to actual translated strings.
  /// For keys not covered by the generated AppLocalizations class,
  /// the key itself is returned as a fallback.
  String _resolveL10n(AppLocalizations l10n, String key) {
    // Map known auth-related l10n keys.
    return switch (key) {
      'email_already_exists' => l10n.email_already_exists,
      'invalid_credentials' => l10n.invalid_credentials,
      'network_error' => l10n.network_error,
      'password_too_short' => l10n.password_too_short,
      'something_went_wrong' => l10n.something_went_wrong,
      'session_expired' => l10n.session_expired,
      'invalid_email' => l10n.invalid_email,
      _ => key, // Fallback: show the key itself.
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.register)),
      body: LoadingOverlay.wrap(
        isLoading: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // AutofillGroup tells the platform that all the form fields
          // below belong together — preventing the browser from piping
          // the email value into the password field (or vice versa).
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const BrandName(fontSize: 28),
                  const SizedBox(height: 8),
                  Text(
                    l10n.no_account_yet,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // ── Email field ─────────────────────────────
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
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 16),

                  // ── Password field ──────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: _validatePassword,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    onChanged: (_) => setState(() {}), // Refresh strength bar.
                  ),
                  const SizedBox(height: 8),

                  // ── Password strength indicator ─────────────
                  PasswordStrengthIndicator(
                    password: _passwordController.text,
                  ),
                  const SizedBox(height: 16),

                  // ── Confirm password field ──────────────────
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    autofillHints: const [AutofillHints.newPassword],
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: l10n.confirm_password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () =>
                              _obscureConfirmPassword = !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    validator: _validateConfirmPassword,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 16),

                  // ── Phone field ─────────────────────────────
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: l10n.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: _validatePhone,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 16),

                  // ── Account type dropdown ───────────────────
                  DropdownButtonFormField<AccountType>(
                    initialValue: _selectedAccountType,
                    decoration: InputDecoration(
                      labelText: l10n.account_type,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    items: AccountType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 20),
                            const SizedBox(width: 8),
                            Text(_accountTypeLabel(l10n, type)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedAccountType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Register button ─────────────────────────
                  FilledButton(
                    onPressed: isLoading ? null : _handleRegister,
                    child: Text(l10n.register),
                  ),
                  const SizedBox(height: 16),

                  // ── Link to login ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.already_have_account),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(l10n.login),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the localized label for an account type.
  String _accountTypeLabel(AppLocalizations l10n, AccountType type) {
    return switch (type) {
      AccountType.individual => l10n.account_type_individual,
      AccountType.hospital => l10n.account_type_hospital,
      AccountType.laboratory => l10n.account_type_laboratory,
    };
  }
}
