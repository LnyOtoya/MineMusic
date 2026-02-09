// 安全存储服务类，用于存储敏感信息

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // 存储键值对
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print('写入安全存储失败: $e');
      rethrow;
    }
  }

  // 读取值
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print('读取安全存储失败: $e');
      return null;
    }
  }

  // 删除键值对
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print('删除安全存储失败: $e');
      rethrow;
    }
  }

  // 删除所有键值对
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('删除所有安全存储失败: $e');
      rethrow;
    }
  }

  // 读取所有键
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      print('读取所有安全存储失败: $e');
      return {};
    }
  }

  // 检查键是否存在
  Future<bool> containsKey({required String key}) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      print('检查安全存储键失败: $e');
      return false;
    }
  }

  // 存储凭据
  Future<void> saveCredentials({
    required String baseUrl,
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      await write(key: 'baseUrl', value: baseUrl);
      await write(key: 'username', value: username);
      await write(key: 'password', value: password);
      await write(key: 'rememberMe', value: rememberMe.toString());
    } catch (e) {
      print('保存凭据失败: $e');
      rethrow;
    }
  }

  // 加载凭据
  Future<Map<String, dynamic>?> loadCredentials() async {
    try {
      final baseUrl = await read(key: 'baseUrl');
      final username = await read(key: 'username');
      final password = await read(key: 'password');
      final rememberMeStr = await read(key: 'rememberMe');

      if (baseUrl == null || username == null || password == null) {
        return null;
      }

      return {
        'baseUrl': baseUrl,
        'username': username,
        'password': password,
        'rememberMe': rememberMeStr?.toLowerCase() == 'true',
      };
    } catch (e) {
      print('加载凭据失败: $e');
      return null;
    }
  }

  // 清除凭据
  Future<void> clearCredentials() async {
    try {
      await delete(key: 'baseUrl');
      await delete(key: 'username');
      await delete(key: 'password');
      await delete(key: 'rememberMe');
    } catch (e) {
      print('清除凭据失败: $e');
      rethrow;
    }
  }
}
