class LyricLine {
  final int startTime;
  final String text;

  LyricLine({
    required this.startTime,
    required this.text,
  });

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      startTime: json['start'] as int? ?? 0,
      text: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': startTime,
      'value': text,
    };
  }
}

class LyricsData {
  final String displayArtist;
  final String displayTitle;
  final String lang;
  final int offset;
  final bool synced;
  final List<LyricLine> lines;

  LyricsData({
    required this.displayArtist,
    required this.displayTitle,
    required this.lang,
    required this.offset,
    required this.synced,
    required this.lines,
  });

  factory LyricsData.fromJson(Map<String, dynamic> json) {
    final linesList = json['line'] as List<dynamic>?;
    final lines = linesList
        ?.map((line) => LyricLine.fromJson(line as Map<String, dynamic>))
        .toList() ?? [];

    return LyricsData(
      displayArtist: json['displayArtist'] as String? ?? '',
      displayTitle: json['displayTitle'] as String? ?? '',
      lang: json['lang'] as String? ?? 'und',
      offset: json['offset'] as int? ?? 0,
      synced: json['synced'] as bool? ?? false,
      lines: lines,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayArtist': displayArtist,
      'displayTitle': displayTitle,
      'lang': lang,
      'offset': offset,
      'synced': synced,
      'line': lines.map((line) => line.toJson()).toList(),
    };
  }

  bool get isEmpty => lines.isEmpty;

  String get languageName {
    switch (lang) {
      case 'zh':
      case 'zho':
        return '中文';
      case 'en':
      case 'eng':
        return 'English';
      case 'ja':
      case 'jpn':
        return '日本語';
      case 'ko':
      case 'kor':
        return '한국어';
      case 'fr':
      case 'fra':
        return 'Français';
      case 'de':
      case 'deu':
        return 'Deutsch';
      case 'es':
      case 'spa':
        return 'Español';
      case 'und':
      default:
        return '未知';
    }
  }
}
