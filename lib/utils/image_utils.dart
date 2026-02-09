// 图片工具类，用于优化图片加载和处理

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageUtils {
  // 缓存网络图片
  static Widget cachedNetworkImage(
    String url,
    {
      double? width,
      double? height,
      BoxFit fit = BoxFit.cover,
      Widget? placeholder,
      Widget? errorWidget,
      Duration fadeInDuration = const Duration(milliseconds: 300),
    }
  ) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder(width, height),
      errorWidget: (context, url, error) => errorWidget ?? _defaultErrorWidget(width, height),
      fadeInDuration: fadeInDuration,
      memCacheWidth: width != null ? width.toInt() * 2 : null, // 2x 分辨率以获得更好的清晰度
      memCacheHeight: height != null ? height.toInt() * 2 : null,
    );
  }

  // 默认占位符
  static Widget _defaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  // 默认错误占位符
  static Widget _defaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  // 预加载图片
  static Future<void> preloadImage(String url) async {
    final completer = Completer<void>();
    
    try {
      final imageProvider = CachedNetworkImageProvider(url);
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      
      final listener = ImageStreamListener(
        (info, synchronousCall) {
          // 图片加载完成
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (error, stackTrace) {
          // 图片加载失败
          if (!completer.isCompleted) {
            completer.complete(); // 即使失败也完成Future，避免阻塞
          }
        },
      );
      
      imageStream.addListener(listener);
      
      // 等待图片加载完成或失败
      await completer.future;
      
      // 移除监听器
      imageStream.removeListener(listener);
    } catch (e) {
      print('预加载图片失败: $e');
      if (!completer.isCompleted) {
        completer.complete(); // 即使发生异常也完成Future
      }
    }
  }

  // 批量预加载图片
  static Future<void> preloadImages(List<String> urls) async {
    await Future.wait(urls.map(preloadImage));
  }

  // 获取封面图片 URL
  static String getCoverArtUrl(
    String baseUrl,
    String coverArtId,
    String username,
    String password,
  ) {
    return Uri.parse('$baseUrl/rest/getCoverArt')
        .replace(
          queryParameters: {
            'u': username,
            'p': password,
            'v': '1.16.0',
            'c': 'MyMusicPlayer',
            'f': 'json',
            'id': coverArtId,
          },
        )
        .toString();
  }

  // 优化图片加载性能
  static void optimizeImageLoading() {
    // 这里可以添加全局图片加载优化配置
    // 例如：设置内存缓存大小、磁盘缓存大小等
  }
}
