import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Env {
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL',
          defaultValue: 'https://placeholder.supabase.co');

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: 'placeholder-anon-key');

  static String get appName =>
      dotenv.env['APP_NAME'] ??
      const String.fromEnvironment('APP_NAME', defaultValue: 'GROUPE NIKEFA');

  static String get supportEmail =>
      dotenv.env['SUPPORT_EMAIL'] ??
      const String.fromEnvironment('SUPPORT_EMAIL',
          defaultValue: 'support@nikefa.net');

  static String get privacyPolicyUrl =>
      dotenv.env['PRIVACY_POLICY_URL'] ??
      const String.fromEnvironment('PRIVACY_POLICY_URL',
          defaultValue: 'https://nikefa.net/privacy');

  static String get termsUrl =>
      dotenv.env['TERMS_URL'] ??
      const String.fromEnvironment('TERMS_URL',
          defaultValue: 'https://nikefa.net/terms');

  static bool get isValidConfig =>
      supabaseUrl != 'https://placeholder.supabase.co' &&
      supabaseAnonKey != 'placeholder-anon-key';
}
