enum LyricsApiType { disabled, subsonic, thirdParty, txmusic2, customApi }

extension LyricsApiTypeExtension on LyricsApiType {
  String get displayName {
    switch (this) {
      case LyricsApiType.disabled:
        return '关闭歌词';
      case LyricsApiType.subsonic:
        return 'Subsonic/Navidrome';
      case LyricsApiType.thirdParty:
        return 'txmusic1';
      case LyricsApiType.txmusic2:
        return 'txmusic2';
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
      case LyricsApiType.thirdParty:
        return 'thirdParty';
      case LyricsApiType.txmusic2:
        return 'txmusic2';
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
      case 'thirdParty':
        return LyricsApiType.thirdParty;
      case 'txmusic2':
        return LyricsApiType.txmusic2;
      case 'customApi':
        return LyricsApiType.customApi;
      default:
        return LyricsApiType.disabled;
    }
  }
}
