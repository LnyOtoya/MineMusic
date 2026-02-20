// 依赖注入容器

import 'package:flutter/material.dart';
import './subsonic_api.dart';
import './player_service.dart';
import './error_handler_service.dart';
import './encryption_service.dart';
import './secure_storage_service.dart';
import './subsonic/subsonic_api_base.dart';

class DependencyInjection {
  static final DependencyInjection _instance = DependencyInjection._internal();
  factory DependencyInjection() => _instance;
  DependencyInjection._internal();

  // 服务实例
  SubsonicApi? _subsonicApi;
  PlayerService? _playerService;
  ErrorHandlerService? _errorHandlerService;
  EncryptionService? _encryptionService;
  SecureStorageService? _secureStorageService;

  // 初始化依赖
  Future<void> initialize({
    String? baseUrl,
    String? username,
    String? password,
  }) async {
    // 初始化缓存
    await SubsonicApiBase.initializeCache();

    // 初始化服务
    if (baseUrl != null && username != null && password != null) {
      _subsonicApi = SubsonicApi(
        baseUrl: baseUrl,
        username: username,
        password: password,
      );
    }

    _errorHandlerService = ErrorHandlerService();
    _encryptionService = EncryptionService();
    _secureStorageService = SecureStorageService();

    // 初始化播放器服务
    _playerService = PlayerService(api: _subsonicApi);
  }

  // 获取 SubsonicApi 实例
  SubsonicApi get subsonicApi {
    if (_subsonicApi == null) {
      throw Exception('SubsonicApi 未初始化');
    }
    return _subsonicApi!;
  }

  // 获取 PlayerService 实例
  PlayerService get playerService {
    if (_playerService == null) {
      throw Exception('PlayerService 未初始化');
    }
    return _playerService!;
  }

  // 获取 ErrorHandlerService 实例
  ErrorHandlerService get errorHandlerService {
    if (_errorHandlerService == null) {
      _errorHandlerService = ErrorHandlerService();
    }
    return _errorHandlerService!;
  }

  // 获取 EncryptionService 实例
  EncryptionService get encryptionService {
    if (_encryptionService == null) {
      _encryptionService = EncryptionService();
    }
    return _encryptionService!;
  }

  // 获取 SecureStorageService 实例
  SecureStorageService get secureStorageService {
    if (_secureStorageService == null) {
      _secureStorageService = SecureStorageService();
    }
    return _secureStorageService!;
  }

  // 更新 SubsonicApi 实例
  void updateSubsonicApi({
    required String baseUrl,
    required String username,
    required String password,
  }) {
    _subsonicApi = SubsonicApi(
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
    // 更新播放器服务中的 API 实例
    if (_playerService != null) {
      _playerService!.updateApi(_subsonicApi);
    }
  }

  // 重置所有依赖
  Future<void> reset() async {
    // 清理缓存
    if (_subsonicApi != null) {
      await _subsonicApi!.clearAllCache();
    }
    _subsonicApi = null;
    _playerService = null;
  }
}

// 全局依赖注入实例
final di = DependencyInjection();
