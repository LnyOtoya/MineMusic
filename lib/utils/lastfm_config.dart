class LastFMConfig {
  static String get apiKey => String.fromEnvironment('LASTFM_API_KEY');
  static String get sharedSecret => String.fromEnvironment('LASTFM_SHARED_SECRET');

  static bool get isConfigured => apiKey.isNotEmpty && sharedSecret.isNotEmpty;
}
