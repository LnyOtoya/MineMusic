enum LyricsApiType {
  disabled,
  subsonic,
  thirdParty,
}

extension LyricsApiTypeExtension on LyricsApiType {
  String get displayName {
    switch (this) {
      case LyricsApiType.disabled:
        return '关闭歌词';
      case LyricsApiType.subsonic:
        return 'Subsonic/Navidrome';
      case LyricsApiType.thirdParty:
        return '第三方API';
    }
  }

  String get storageKey {
    switch (this) {
      case LyricsApiType.disabled:
        return 'disabled';
      case LyricsApiType.subsonic:
        return 'subsonic';
      case LyricsApiType.thirdParty:
        return 'thirdParty';
    }
  }

  static LyricsApiType fromString(String value) {
    switch (value) {
      case 'disabled':
        return LyricsApiType.disabled;
      case 'subsonic':
        return LyricsApiType.subsonic;
      case 'thirdParty':
        return LyricsApiType.thirdParty;
      default:
        return LyricsApiType.disabled;
    }
  }
}
