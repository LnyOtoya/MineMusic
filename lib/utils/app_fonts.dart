import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  static const String nunito = 'Nunito';
  static const String notoSansSC = 'Noto Sans SC';

  static String getFontForText(String text) {
    // 检查是否包含中文
    if (_containsChinese(text)) {
      return notoSansSC;
    }
    
    // 检查是否包含俄语、日语或韩语
    if (_containsCyrillic(text) || _containsJapanese(text) || _containsKorean(text)) {
      return notoSansSC;
    }
    
    // 默认使用 Nunito（适合英语和数字）
    return nunito;
  }

  static bool _containsChinese(String text) {
    final chineseRegex = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf\U00020000-\U0002a6df\U0002a700-\U0002b73f\U0002b740-\U0002b81f\U0002b820-\U0002ceaf\U000f900-\U000faff\U001f200-\U001f2ff]');
    return chineseRegex.hasMatch(text);
  }

  static bool _containsCyrillic(String text) {
    final cyrillicRegex = RegExp(r'[\u0400-\u04FF]');
    return cyrillicRegex.hasMatch(text);
  }

  static bool _containsJapanese(String text) {
    final japaneseRegex = RegExp(r'[\u3040-\u309f\u30a0-\u30ff\u31f0-\u31ff]');
    return japaneseRegex.hasMatch(text);
  }

  static bool _containsKorean(String text) {
    final koreanRegex = RegExp(r'[\uac00-\ud7af\U0001100-\U00011ff]');
    return koreanRegex.hasMatch(text);
  }

  static TextStyle getTextStyle({
    required String text,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final fontFamily = getFontForText(text);
    
    return GoogleFonts.getFont(
      fontFamily,
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        fontFamily: fontFamily,
      ),
    );
  }

  static TextStyle getTextStyleWithNunito({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      ),
    );
  }

  static TextStyle getTextStyleWithNotoSans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return GoogleFonts.notoSansSc(
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
