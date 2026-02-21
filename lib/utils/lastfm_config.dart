import 'test_config.dart';

class LastFMConfig {
  static String get apiKey => TestConfig.lastFMApiKey;
  static String get sharedSecret => TestConfig.lastFMSharedSecret;

  static bool get isConfigured => apiKey.isNotEmpty && sharedSecret.isNotEmpty;
}
