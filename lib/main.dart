// GROUPE NIKEFA — Medical Supply Marketplace
// Entry point: initializes Riverpod, Supabase, localization,
// routing, and connectivity.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/offline_banner.dart';
import 'core/widgets/startup_validation.dart';
import 'core/providers/locale_provider.dart';
import 'core/constants/app_colors.dart';
import 'core/hive/hive_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Hive.initFlutter();
  await initHiveAdapters();

  // Initialize Supabase.
  // Note: StartupValidation handles Supabase initialization to show
  // a user-friendly error screen with retry if it fails.
  // await initializeSupabase();

  // Lock orientation to portrait for a consistent mobile experience.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set the status bar style to match the golden yellow AppBar.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.goldenYellow,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: NikefaApp()));
}

/// Root widget of the GROUPE NIKEFA application.
///
/// Sets up:
/// - Riverpod ProviderScope (state management)
/// - GoRouter (declarative routing with auth guards)
/// - Localization (Arabic default, French; RTL/LTR auto-detection)
/// - Theme (brand colors)
/// - Offline banner (global connectivity listener)
class NikefaApp extends ConsumerWidget {
  const NikefaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the current locale from the locale provider.
    final locale = ref.watch(localeProvider);

    // Build the GoRouter instance (cached to avoid duplicate GlobalKey instances).
    final router = createRouter();

    return MaterialApp.router(
      // ── App metadata ────────────────────────────────────────
      title: 'GROUPE NIKEFA',
      debugShowCheckedModeBanner: false,

      // ── Theme ───────────────────────────────────────────────
      theme: getAppTheme(),

      // ── Localization ────────────────────────────────────────
      locale: locale,
      supportedLocales: const [
        Locale('ar'), // Arabic (RTL)
        Locale('fr'), // French (LTR)
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Router ──────────────────────────────────────────────
      routerConfig: router,

      // ── Builder wrapper: inject offline banner & startup validation globally ─────
      builder: (context, child) {
        return StartupValidation(
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}
