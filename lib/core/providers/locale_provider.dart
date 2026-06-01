// Locale provider — lets the user switch between Arabic and French
// and persists the choice in SharedPreferences (deferred to Step 4).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported locales for the application.
final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('ar'); // Default to Arabic
});
