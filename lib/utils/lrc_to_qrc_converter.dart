import 'dart:math';

class LrcToQrcConverter {
  static bool isQrcFormat(String lyrics) {
    if (lyrics.trim().isEmpty) return false;

    final qrcPattern = RegExp(r'\[\d+,\d+\].*?\(\d+,\d+\)');
    return qrcPattern.hasMatch(lyrics);
  }

  static String convertLrcToQrc(String lrcText) {
    if (lrcText.trim().isEmpty) return '';

    if (isQrcFormat(lrcText)) {
      return lrcText;
    }

    final lines = lrcText.split('\n');
    final qrcLines = <String>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      final parsedLine = _parseLrcLine(trimmedLine);
      if (parsedLine != null) {
        final qrcLine = _convertLineToQrc(parsedLine);
        if (qrcLine.isNotEmpty) {
          qrcLines.add(qrcLine);
        }
      }
    }

    return qrcLines.join('\n');
  }

  static LrcLine? _parseLrcLine(String line) {
    final timeRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');
    final match = timeRegex.firstMatch(line);

    if (match == null) return null;

    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final millisecondsStr = match.group(3)!;
    final milliseconds = millisecondsStr.length == 2
        ? int.parse(millisecondsStr) * 10
        : int.parse(millisecondsStr);

    final startTime = Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );

    final text = line.replaceFirst(timeRegex, '').trim();

    return LrcLine(startTime: startTime, text: text);
  }

  static String _convertLineToQrc(LrcLine line) {
    if (line.text.isEmpty) return '';

    final startTimeMs = line.startTime.inMilliseconds;
    final text = line.text;

    final totalDuration = _estimateLineDuration(text);
    final wordsWithTiming = <String>[];

    var currentOffset = 0;
    var currentIndex = 0;

    while (currentIndex < text.length) {
      final char = text[currentIndex];

      if (char == ' ') {
        wordsWithTiming.add(' ');
        currentOffset += 50;
        currentIndex++;
        continue;
      }

      if (_isChinese(char)) {
        final charDuration = _estimateCharDuration(char, totalDuration);
        wordsWithTiming.add('$char($currentOffset,$charDuration)');
        currentOffset += charDuration;
        currentIndex++;
      } else {
        final wordEnd = _findWordEnd(text, currentIndex);
        final word = text.substring(currentIndex, wordEnd);
        final wordDuration = _estimateWordDuration(word, totalDuration);
        wordsWithTiming.add('$word($currentOffset,$wordDuration)');
        currentOffset += wordDuration;
        currentIndex = wordEnd;
      }
    }

    return '[$startTimeMs,$totalDuration]${wordsWithTiming.join('')}';
  }

  static bool _isChinese(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x4e00 && code <= 0x9fa5;
  }

  static int _findWordEnd(String text, int startIndex) {
    var index = startIndex;
    while (index < text.length) {
      final char = text[index];
      if (char == ' ' || _isChinese(char)) {
        break;
      }
      index++;
    }
    return index;
  }

  static int _estimateLineDuration(String text) {
    final charCount = text.replaceAll(' ', '').length;
    final chineseCount = text.split('').where(_isChinese).length;

    final baseDuration = 3000;
    final charFactor = charCount * 80;
    final chineseFactor = chineseCount * 100;

    return min(baseDuration + charFactor + chineseFactor, 10000);
  }

  static int _estimateCharDuration(String char, int totalDuration) {
    return max(150, min(400, totalDuration ~/ 5));
  }

  static int _estimateWordDuration(String word, int totalDuration) {
    final charCount = word.length;
    if (charCount == 0) return 100;

    final baseDuration = 200;
    final charFactor = charCount * 80;

    return min(baseDuration + charFactor, totalDuration ~/ 2);
  }

  static String convertLrcToQrcWithTranslation(
    String lrcText,
    String? translationText,
  ) {
    final qrcLyrics = convertLrcToQrc(lrcText);

    return qrcLyrics;
  }
}

class LrcLine {
  final Duration startTime;
  final String text;

  LrcLine({required this.startTime, required this.text});
}
