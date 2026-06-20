import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class SupabaseEnv {
  static String get url =>
      dotenv.maybeGet('VITE_SUPABASE_URL') ??
      dotenv.maybeGet('SUPABASE_URL') ??
      const String.fromEnvironment('SUPABASE_URL');

  static String get anonKey =>
      dotenv.maybeGet('VITE_SUPABASE_ANON_KEY') ??
      dotenv.maybeGet('SUPABASE_ANON_KEY') ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
