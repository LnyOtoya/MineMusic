# 逐字高亮实现说明

## 概述

本项目已成功实现歌词逐字高亮功能，支持：
1. **自动检测歌词格式**（LRC 或 QRC）
2. **LRC 到 QRC 格式转换**，使 flutter_lyric 库能够显示逐字高亮效果
3. **直接使用 QRC 格式**，如果 API 已返回 QRC 格式歌词

## 技术方案

### 1. 格式检测

**QRC 格式特征**：
```
[0,4180]红(0,220)日(220,220) (440,220)((660,220)粤(880,220)语(1100,220))(1320,220)
```
- 包含 `[数字,数字]` 格式的行时间标签
- 包含 `(数字,数字)` 格式的字时间标签

**LRC 格式特征**：
```
[00:00.12]Doctor actor lawyer or a singer
[00:03.47]Why not president be a dreamer
```
- 包含 `[mm:ss.ms]` 格式的时间标签

**检测方法**：
```dart
static bool isQrcFormat(String lyrics) {
  final qrcPattern = RegExp(r'\[\d+,\d+\].*?\(\d+,\d+\)');
  return qrcPattern.hasMatch(lyrics);
}
```

### 2. LRC 到 QRC 格式转换

**LRC 格式**（逐行高亮）：
```
[00:00.12]Doctor actor lawyer or a singer
[00:03.47]Why not president be a dreamer
```

**QRC 格式**（逐字高亮）：
```
[120,5080]Doctor(0,680) actor(730,600) lawyer(1380,680) or(2110,360) a(2520,280) singer(2850,680)
[3470,5000]Why(0,440) not(490,440) president(980,920) be(1950,360) a(2360,280) dreamer(2690,760)
```

**格式说明**：
- `[120,5080]`：行的开始时间（毫秒）和持续时间（毫秒）
- `Doctor(0,680)`：单词/字文本 + (偏移时间, 持续时间)

### 2. 转换器实现

**文件位置**：`lib/utils/lrc_to_qrc_converter.dart`

**核心功能**：
- 解析 LRC 时间标签 `[mm:ss.ms]`
- 估算每行的持续时间
- 为每个单词/字符分配时间信息
- 支持中英文混合歌词
- 智能识别中文和英文单词

**关键算法**：
```dart
// 中文逐字处理
if (_isChinese(char)) {
  final charDuration = _estimateCharDuration(char, totalDuration);
  wordsWithTiming.add('$char($currentOffset,$charDuration)');
}

// 英文单词处理
else {
  final wordEnd = _findWordEnd(text, currentIndex);
  final word = text.substring(currentIndex, wordEnd);
  final wordDuration = _estimateWordDuration(word, totalDuration);
  wordsWithTiming.add('$word($currentOffset,$wordDuration)');
}
```

### 3. 集成到播放器

**文件位置**：`lib/pages/player_page.dart`

**修改内容**：
1. 导入转换器：`import '../utils/lrc_to_qrc_converter.dart';`
2. 在加载歌词时自动检测和转换：
   ```dart
   final isQrc = LrcToQrcConverter.isQrcFormat(lyricsText);
   final qrcLyrics = isQrc 
       ? lyricsText 
       : LrcToQrcConverter.convertLrcToQrc(lyricsText);
   
   if (isQrc) {
     print('✅ 检测到QRC格式，使用原始歌词（支持逐字高亮）');
   } else {
     print('🔄 已转换为QRC格式，支持逐字高亮');
   }
   
   _lyricController.loadLyric(qrcLyrics);
   ```

**日志输出示例**：
```
✅ 检测到QRC格式，使用原始歌词（支持逐字高亮）
```
或
```
🔄 已转换为QRC格式，支持逐字高亮
```

### 4. 时间估算策略

**行持续时间估算**：
- 基础时间：3000ms
- 每个字符：80ms
- 每个中文字符：100ms
- 最大限制：10000ms

**字符持续时间估算**：
- 范围：150ms - 400ms
- 基于行持续时间的 1/5

**单词持续时间估算**：
- 基础时间：200ms
- 每个字符：80ms
- 最大限制：行持续时间的 1/2

## 使用示例

### 测试转换器

运行测试文件：
```bash
dart lib/lrc_to_qrc_test.dart
```

### 在播放器中使用

无需额外配置，播放器会自动将 LRC 格式歌词转换为 QRC 格式并实现逐字高亮。

## 注意事项

1. **自动格式检测**：系统会自动检测歌词格式（LRC 或 QRC），无需手动配置
2. **QRC 格式优先**：如果 API 返回 QRC 格式，系统会直接使用原始歌词，保留精确的逐字时间信息
3. **LRC 格式转换**：如果 API 返回 LRC 格式，系统会自动转换为 QRC 格式，使用估算的时间信息
4. **时间估算准确性**：
   - QRC 格式：使用原始精确时间，准确性高
   - LRC 格式：使用算法估算时间，可能与实际演唱时间有偏差
5. **性能**：格式检测和转换过程在加载歌词时完成，不影响播放性能
6. **翻译歌词**：翻译歌词也会进行格式检测和转换

## 未来改进

1. 支持从音频文件中提取精确的逐字时间信息
2. 优化时间估算算法，提高准确性
3. 支持用户自定义时间调整
4. 添加逐字高亮样式配置选项

## 相关文件

- `lib/utils/lrc_to_qrc_converter.dart` - LRC 到 QRC 转换器
- `lib/pages/player_page.dart` - 播放器页面（已集成转换器）
- `lib/lrc_to_qrc_test.dart` - 转换器测试文件
- `lib/tmp/flutter_lyric-main/` - flutter_lyric 库示例代码
