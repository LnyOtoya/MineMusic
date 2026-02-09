import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 加密服务类，用于密码的加密和解密
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keyKey = 'encryption_key';
  static const String _ivKey = 'encryption_iv';

  // 生成随机密钥
  String _generateRandomKey(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Encode(values);
  }

  // 获取或生成加密密钥
  Future<Key> _getKey() async {
    try {
      String? keyString = await _storage.read(key: _keyKey);
      if (keyString == null) {
        // 生成新密钥并存储
        keyString = _generateRandomKey(32);
        await _storage.write(key: _keyKey, value: keyString);
      }
      final keyBytes = base64Decode(keyString);
      return Key(keyBytes.length >= 32 ? keyBytes.sublist(0, 32) : keyBytes);
    } catch (e) {
      print('获取密钥失败: $e');
      // 降级方案：使用默认密钥
      return Key.fromUtf8('MineMusicEncryptionKey1234567890123456789012'.padRight(32).substring(0, 32));
    }
  }

  // 获取或生成初始化向量
  Future<IV> _getIV() async {
    try {
      String? ivString = await _storage.read(key: _ivKey);
      if (ivString == null) {
        // 生成新IV并存储
        ivString = _generateRandomKey(16);
        await _storage.write(key: _ivKey, value: ivString);
      }
      final ivBytes = base64Decode(ivString);
      return IV(ivBytes.length >= 16 ? ivBytes.sublist(0, 16) : ivBytes);
    } catch (e) {
      print('获取IV失败: $e');
      // 降级方案：使用默认IV
      return IV.fromUtf8('MineMusicIV12345678'.padRight(16).substring(0, 16));
    }
  }

  // 获取加密器
  Future<Encrypter> _getEncrypter() async {
    final key = await _getKey();
    final iv = await _getIV();
    return Encrypter(AES(key, mode: AESMode.cbc));
  }

  // 加密密码
  Future<String> encryptPassword(String password) async {
    try {
      final encrypter = await _getEncrypter();
      final iv = await _getIV();
      final encrypted = encrypter.encrypt(password, iv: iv);
      return encrypted.base64;
    } catch (e) {
      print('加密密码失败: $e');
      return password; // 加密失败时返回原始密码
    }
  }

  // 解密密码
  Future<String> decryptPassword(String encryptedPassword) async {
    try {
      final encrypter = await _getEncrypter();
      final iv = await _getIV();
      final decrypted = encrypter.decrypt64(encryptedPassword, iv: iv);
      return decrypted;
    } catch (e) {
      print('解密密码失败: $e');
      return encryptedPassword; // 解密失败时返回加密的密码
    }
  }

  // 检查密码是否已加密
  bool isPasswordEncrypted(String password) {
    // 简单检查：如果密码是base64格式且长度合理，则认为已加密
    try {
      final decoded = base64Decode(password);
      return decoded.length > 0;
    } catch (_) {
      return false;
    }
  }
}
