// Supabase configuration — singleton initialization.
//
// This file provides a single point of Supabase client access
// throughout the application. The client is initialized once at
// app startup and reused by all repositories.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env.dart';

/// Exception thrown when Supabase configuration is invalid.
class SupabaseConfigException implements Exception {
  final String message;
  const SupabaseConfigException(this.message);

  @override
  String toString() => 'SupabaseConfigException: $message';
}

/// Validates that Supabase credentials are properly configured.
///
/// Returns an error message if configuration is invalid, or null if valid.
String? validateSupabaseConfig() {
  final url = Env.supabaseUrl;
  final anonKey = Env.supabaseAnonKey;

  if (url == 'https://placeholder.supabase.co' || url.isEmpty) {
    return 'Supabase URL is not configured in .env file';
  }

  if (anonKey == 'placeholder-anon-key' || anonKey.isEmpty) {
    return 'Supabase anon key is not configured in .env file';
  }

  if (!url.startsWith('https://')) {
    return 'Supabase URL must start with https://';
  }

  return null;
}

/// Initializes the Supabase client for the application.
///
/// Must be called once during app startup (before `runApp`) with
/// a valid [FlutterBinding] already ensured. This function reads
/// the Supabase URL and anon key from [Env] and configures the
/// client with default settings suitable for the MVP.
///
/// Throws [SupabaseConfigException] if credentials are invalid.
/// Throws [Exception] if initialization fails.
Future<void> initializeSupabase() async {
  // Validate configuration before attempting initialization
  final validationError = validateSupabaseConfig();
  if (validationError != null) {
    debugPrint('[Supabase] Configuration error: $validationError');
    throw SupabaseConfigException(validationError);
  }

  try {
    debugPrint('[Supabase] Initializing with URL: ${Env.supabaseUrl}');

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      // Enable debug logging in development only.
      debug: kDebugMode,
    );

    debugPrint('[Supabase] Initialization successful');
  } catch (e) {
    debugPrint('[Supabase] Initialization failed: $e');
    throw Exception('Failed to initialize Supabase: $e');
  }
}

/// Provides access to the initialized Supabase client.
///
/// This is a convenience accessor that returns the singleton
/// [Supabase.instance.client]. The client must have been
/// initialized via [initializeSupabase] before this is called.
SupabaseClient get supabaseClient => Supabase.instance.client;
