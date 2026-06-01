// Offline banner widget — displayed at the top of the screen
// when the device loses internet connectivity.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../providers/connectivity_provider.dart';

/// Dismissible banner shown when the device is offline.
///
/// Listens to [connectivityProvider] and renders a yellow banner
/// with a warning message when no viable connection is detected.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (results) {
        final isOffline = _isDisconnected(results);
        if (!isOffline) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context)!;
        return Material(
          color: AppColors.goldenYellow,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.offline_warning,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Determines whether the device should be considered disconnected.
  bool _isDisconnected(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }
}
