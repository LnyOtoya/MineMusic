import 'package:flutter/material.dart';

class ErrorHandlerService {
  // 单例模式
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  // 错误统计
  final Map<String, int> _errorCounts = {};

  // 处理错误并显示错误信息
  void handleError(BuildContext context, dynamic error, {
    String defaultMessage = '操作失败',
    bool showSnackBar = true,
    String? errorType,
    bool showDialog = false,
    String? dialogTitle,
  }) {
    // 记录错误
    _logError(error, errorType);
    // 统计错误
    _trackError(errorType ?? 'General');

    // 生成用户友好的错误信息
    String userFriendlyMessage = _getUserFriendlyMessage(error, defaultMessage);

    // 显示错误信息
    if (context.mounted) {
      if (showDialog) {
        _showErrorDialog(context, dialogTitle ?? '错误', userFriendlyMessage);
      } else if (showSnackBar) {
        _showErrorSnackBar(context, userFriendlyMessage);
      }
    }
  }

  // 记录错误信息到控制台
  void _logError(dynamic error, String? errorType) {
    String errorMessage = error.toString();
    String timestamp = DateTime.now().toString();
    String formattedTimestamp = timestamp.substring(0, 19); // 只显示到秒
    
    print('''
[ERROR] $formattedTimestamp
Type: ${errorType ?? 'General'}
Error: $errorMessage
Stack Trace: ${error is Error ? error.stackTrace : 'No stack trace available'}
''');
  }

  // 统计错误
  void _trackError(String errorType) {
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
  }

  // 获取错误统计信息
  Map<String, int> get errorCounts => _errorCounts;

  // 生成用户友好的错误信息
  String _getUserFriendlyMessage(dynamic error, String defaultMessage) {
    if (error == null) return defaultMessage;

    String errorMessage = error.toString().toLowerCase();

    // 根据错误类型返回不同的错误信息
    if (errorMessage.contains('timeout') || errorMessage.contains('timed out')) {
      return '网络连接超时，请检查网络设置';
    } else if (errorMessage.contains('socket') || errorMessage.contains('connection')) {
      return '网络连接失败，请检查网络设置';
    } else if (errorMessage.contains('401') || errorMessage.contains('unauthorized')) {
      return '登录失败，请检查用户名和密码';
    } else if (errorMessage.contains('403') || errorMessage.contains('forbidden')) {
      return '没有权限执行此操作';
    } else if (errorMessage.contains('404') || errorMessage.contains('not found')) {
      return '请求的资源不存在';
    } else if (errorMessage.contains('500') || errorMessage.contains('internal server error')) {
      return '服务器内部错误，请稍后重试';
    } else if (errorMessage.contains('502') || errorMessage.contains('bad gateway')) {
      return '服务器网关错误，请稍后重试';
    } else if (errorMessage.contains('503') || errorMessage.contains('service unavailable')) {
      return '服务器暂时不可用，请稍后重试';
    } else if (errorMessage.contains('xml') || errorMessage.contains('parse')) {
      return '数据解析失败，请稍后重试';
    } else if (errorMessage.contains('json') || errorMessage.contains('decode')) {
      return '数据解码失败，请稍后重试';
    } else if (errorMessage.contains('password') || errorMessage.contains('credential')) {
      return '密码错误，请检查输入';
    } else if (errorMessage.contains('network') || errorMessage.contains('internet')) {
      return '网络连接问题，请检查网络设置';
    } else if (errorMessage.contains('storage') || errorMessage.contains('disk')) {
      return '存储空间不足，请清理空间后重试';
    } else if (errorMessage.contains('permission') || errorMessage.contains('denied')) {
      return '权限不足，请检查应用权限设置';
    } else if (errorMessage.contains('file') || errorMessage.contains('not exist')) {
      return '文件不存在，请检查文件路径';
    } else if (errorMessage.contains('format') || errorMessage.contains('invalid')) {
      return '格式无效，请检查输入内容';
    }

    // 默认错误信息
    return defaultMessage;
  }

  // 显示错误 SnackBar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // 显示错误对话框
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
          contentTextStyle: Theme.of(context).textTheme.bodyMedium,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 处理 API 错误
  void handleApiError(BuildContext context, dynamic error, String endpoint) {
    handleError(
      context,
      error,
      defaultMessage: 'API 请求失败',
      errorType: 'API Error - $endpoint',
    );
  }

  // 处理网络错误
  void handleNetworkError(BuildContext context, dynamic error) {
    handleError(
      context,
      error,
      defaultMessage: '网络连接失败',
      errorType: 'Network Error',
    );
  }

  // 处理播放错误
  void handlePlaybackError(BuildContext context, dynamic error) {
    handleError(
      context,
      error,
      defaultMessage: '播放失败',
      errorType: 'Playback Error',
    );
  }

  // 处理登录错误
  void handleLoginError(BuildContext context, dynamic error) {
    handleError(
      context,
      error,
      defaultMessage: '登录失败',
      errorType: 'Login Error',
      showDialog: true,
      dialogTitle: '登录失败',
    );
  }

  // 处理文件错误
  void handleFileError(BuildContext context, dynamic error) {
    handleError(
      context,
      error,
      defaultMessage: '文件操作失败',
      errorType: 'File Error',
    );
  }

  // 处理权限错误
  void handlePermissionError(BuildContext context, dynamic error) {
    handleError(
      context,
      error,
      defaultMessage: '权限不足',
      errorType: 'Permission Error',
      showDialog: true,
      dialogTitle: '权限不足',
    );
  }

  // 清除错误统计
  void clearErrorCounts() {
    _errorCounts.clear();
  }
}

