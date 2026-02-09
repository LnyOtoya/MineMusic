import 'dart:io';
import 'dart:convert'; // 必须保留，utf8 常量来自该库

void main() async {
  // 1. 配置转换目录（默认：脚本运行所在目录，可修改为绝对路径）
  final String targetDir = Directory.current.path;
  print("=== 开始执行 YRC 转 QRC 批量转换 ===");
  print("转换目录：$targetDir");
  print("====================================\n");

  try {
    // 2. 获取目录下所有 .yrc 后缀文件
    final Directory directory = Directory(targetDir);
    final List<File> yrcFiles = directory
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.yrc'))
        .cast<File>()
        .toList();

    if (yrcFiles.isEmpty) {
      print("未在当前目录找到任何 .yrc 文件，请确认文件存在！");
      return;
    }

    print("找到 ${yrcFiles.length} 个 .yrc 文件，开始逐个转换...\n");

    // 3. 遍历每个 YRC 文件，执行转换
    for (int i = 0; i < yrcFiles.length; i++) {
      final File yrcFile = yrcFiles[i];
      final String yrcFilePath = yrcFile.path;
      // 构造对应的 QRC 文件路径（替换后缀为 .qrc）
      final String qrcFilePath = yrcFilePath.replaceAll('.yrc', '.qrc');

      try {
        print("正在处理第 ${i + 1}/${yrcFiles.length} 个文件：");
        print("源文件：${yrcFile.path.split(Platform.pathSeparator).last}");

        // 3.1 读取 YRC 文件内容（使用 utf8 常量，替代 Encoding.getByName('utf-8')）
        final String yrcContent = await yrcFile.readAsString(encoding: utf8);

        // 3.2 执行 YRC 转 QRC 核心逻辑
        final String qrcContent = _convertYrcToQrcCore(yrcContent);

        // 3.3 写入 QRC 文件（同样使用 utf8 常量，保证无乱码）
        final File qrcFile = File(qrcFilePath);
        await qrcFile.writeAsString(qrcContent, encoding: utf8);

        print("转换成功！生成文件：${qrcFile.path.split(Platform.pathSeparator).last}\n");
      } catch (e) {
        print("处理文件 $yrcFilePath 失败：$e\n");
        continue;
      }
    }

    print("=== 批量转换完成！===");
    print("总计处理 ${yrcFiles.length} 个文件，成功生成对应 .qrc 文件（失败文件已标注）");
  } catch (e) {
    print("批量转换异常：$e");
  }
}

/// 核心转换逻辑：将 YRC 内容转为 QRC XML 格式
String _convertYrcToQrcCore(String yrcContent) {
  // 1. 生成当前 Unix 时间戳（QRC SaveTime 字段要求）
  final int saveTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // 2. XML 特殊字符转义（避免 <、>、" 等导致 XML 解析错误）
  final String escapedYrcContent = _escapeXmlSpecialChars(yrcContent);

  // 3. 组装 QRC 标准 XML 结构（严格匹配 QRC 样本格式）
  final String qrcXml =
      '''<?xml version="1.0" encoding="utf-8"?>
<QrcInfos>
<QrcHeadInfo SaveTime="$saveTime" Version="100"/>
<LyricInfo LyricCount="1">
<Lyric_1 LyricType="1" LyricContent="$escapedYrcContent"/>
</LyricInfo>
</QrcInfos>''';

  return qrcXml;
}

/// XML 特殊字符转义工具（保证 XML 格式合规）
String _escapeXmlSpecialChars(String content) {
  if (content.isEmpty) return "";
  return content
      .replaceAll('&', '&amp;') // 第一个转义 &，避免其他转义字符被二次转换
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
