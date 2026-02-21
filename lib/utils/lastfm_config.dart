class LastFMConfig {
  static String get apiKey => String.fromEnvironment('LASTFM_API_KEY', defaultValue: '');
  static String get sharedSecret => String.fromEnvironment('LASTFM_SHARED_SECRET', defaultValue: '');

  static bool get isConfigured => apiKey.isNotEmpty && sharedSecret.isNotEmpty;
}
