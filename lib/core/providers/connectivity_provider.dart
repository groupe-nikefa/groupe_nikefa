// Connectivity providers — shared connectivity state for the app.
//
// Two providers serve different use cases:
//   - `isOfflineProvider`: emits boolean with immediate connectivity check,
//     used by GoRouter redirects and catalog screen.
//   - `connectivityProvider`: emits raw ConnectivityResult list for the
//     offline banner widget.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provider that emits the current connectivity status as a boolean.
///
/// Performs an immediate check on first listen to avoid delay,
/// then listens for connectivity changes.
final isOfflineProvider = StreamProvider<bool>((ref) async* {
  final initial = await Connectivity().checkConnectivity();
  yield initial.isEmpty || initial.every((r) => r == ConnectivityResult.none);
  await for (final results in Connectivity().onConnectivityChanged) {
    yield results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }
});

/// Provider that emits raw connectivity result list.
///
/// Used by the [OfflineBanner] widget to show/hide the banner.
final connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});