// lib/models/lyric.dart
class Lyric {
  final Duration time;
  final String text;

  Lyric({required this.time, required this.text});
}

// 解析带时间戳的歌词文本
List<Lyric> parseLyrics(String lyricText) {
  final List<Lyric> lyrics = [];
  final lines = lyricText.split('\n');
  
  for (final line in lines) {
    // 跳过空行
    if (line.trim().isEmpty) continue;
    
    // 跳过元数据标签（如 [ti:标题]、[ar:歌手]、[al:专辑]、[offset:0] 等）
    if (RegExp(r'^\[(ti|ar|al|by|offset|length):.+\]$').hasMatch(line.trim())) {
      continue;
    }
    
    // 匹配 [mm:ss.xx] 格式的时间戳
    final regex = RegExp(r'\[(\d+):(\d+\.\d+)\](.+)');
    final match = regex.firstMatch(line);
    
    if (match != null) {
      final minutes = int.parse(match.group(1)!);
      final seconds = double.parse(match.group(2)!);
      final text = match.group(3)!.trim();
      
      // 跳过空歌词行
      if (text.isEmpty) continue;
      
      lyrics.add(Lyric(
        time: Duration(minutes: minutes, seconds: seconds.toInt(), milliseconds: ((seconds - seconds.toInt()) * 1000).toInt()),
        text: text,
      ));
    } else if (line.trim().isNotEmpty && !line.trim().startsWith('[')) {
      // 没有时间戳的歌词行（且不是元数据标签）
      final text = line.trim();
      if (text.isNotEmpty) {
        lyrics.add(Lyric(time: Duration.zero, text: text));
      }
    }
  }
  
  // 按时间排序
  lyrics.sort((a, b) => a.time.compareTo(b.time));
  return lyrics;
}
