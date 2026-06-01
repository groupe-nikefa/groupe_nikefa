import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/account_type.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.my_profile)),
        body: const Center(child: Text('No user data')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.my_profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFF002664),
            child: Text(
              user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          _InfoTile(label: l10n.email, value: user.email),
          _InfoTile(label: l10n.phone, value: user.phone),
          _InfoTile(
              label: l10n.account_type,
              value: _accountTypeLabel(l10n, user.accountType)),
          _InfoTile(
              label: l10n.customer_role,
              value: user.isAdmin ? 'Admin' : 'Customer'),
          _InfoTile(
            label: l10n.member_since,
            value:
                '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.edit_profile),
          ),
        ],
      ),
    );
  }

  String _accountTypeLabel(AppLocalizations l10n, AccountType type) {
    return switch (type) {
      AccountType.individual => l10n.account_type_individual,
      AccountType.hospital => l10n.account_type_hospital,
      AccountType.laboratory => l10n.account_type_laboratory,
    };
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600])),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
