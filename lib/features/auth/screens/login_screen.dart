// Login screen — email/password authentication with Supabase.
//
// Provides form validation, password visibility toggle, and
// role-based auto-navigation on successful login.
// Admin users are redirected to /admin, customers to /.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/brand_name.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // ── Form controllers ──────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── State ─────────────────────────────────────────────────
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────
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
    return null;
  }

  // ── Login handler ─────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(authNotifierProvider.notifier);

    final success = await notifier.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Login succeeded — redirect based on user role.
      final user = ref.read(currentUserProvider);
      if (!mounted) return;

      // Tell the platform that the autofill context is complete so the
      // browser/OS can save these credentials under the right fields.
      TextInput.finishAutofillContext();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.login_success),
          backgroundColor: Colors.green,
        ),
      );

      // Admin users go to the admin dashboard, everyone else to home.
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

  /// Resolves a localization key to its translated string value.
  String _resolveL10n(AppLocalizations l10n, String key) {
    return switch (key) {
      'email_already_exists' => l10n.email_already_exists,
      'invalid_credentials' => l10n.invalid_credentials,
      'network_error' => l10n.network_error,
      'password_too_short' => l10n.password_too_short,
      'something_went_wrong' => l10n.something_went_wrong,
      'session_expired' => l10n.session_expired,
      'invalid_email' => l10n.invalid_email,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
      body: LoadingOverlay.wrap(
        isLoading: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // AutofillGroup keeps email and password paired so the
          // browser/platform never misroutes the saved password into
          // the email field (or vice versa).
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  const BrandName(fontSize: 28),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcome,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),

                  // ── Email field ─────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
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
                    autofillHints: const [AutofillHints.password],
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
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 8),

                  // ── Forgot password ─────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/password-reset'),
                      child: Text(l10n.forgot_password),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Login button ────────────────────────────
                  FilledButton(
                    onPressed: isLoading ? null : _handleLogin,
                    child: Text(l10n.login),
                  ),
                  const SizedBox(height: 16),

                  // ── Link to register ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.dont_have_account),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text(l10n.register),
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
}
