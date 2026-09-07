import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );

  static String get url => _url;

  static bool get isConfigured => _url.isNotEmpty && _publishableKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) {
      throw const FormatException(
        'Supabase credentials are missing. Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY before enabling image uploads.',
      );
    }

    await Supabase.initialize(url: _url, publishableKey: _publishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
