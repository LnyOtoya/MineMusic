enum LyricsApiType { disabled, subsonic, customApi }

extension LyricsApiTypeExtension on LyricsApiType {
  String get displayName {
    switch (this) {
      case LyricsApiType.disabled:
        return '关闭歌词';
      case LyricsApiType.subsonic:
        return 'Subsonic/Navidrome';
      case LyricsApiType.customApi:
        return '自建API';
    }
  }

  String get storageKey {
    switch (this) {
      case LyricsApiType.disabled:
        return 'disabled';
      case LyricsApiType.subsonic:
        return 'subsonic';
      case LyricsApiType.customApi:
        return 'customApi';
    }
  }

  static LyricsApiType fromString(String value) {
    switch (value) {
      case 'disabled':
        return LyricsApiType.disabled;
      case 'subsonic':
        return LyricsApiType.subsonic;
      case 'customApi':
        return LyricsApiType.customApi;
      default:
        return LyricsApiType.disabled;
    }
  }
}
