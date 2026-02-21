class LastFMConfig {
  static const String apiKey = String.fromEnvironment('LASTFM_API_KEY', defaultValue: '');
  static const String sharedSecret = String.fromEnvironment('LASTFM_SHARED_SECRET', defaultValue: '');

  static bool get isConfigured => apiKey.isNotEmpty && sharedSecret.isNotEmpty;
}
