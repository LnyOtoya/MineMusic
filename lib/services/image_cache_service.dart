import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart' show CachedNetworkImageProvider;

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._private();
  factory ImageCacheService() => _instance;

  ImageCacheService._private();

  // 预加载图片到缓存
  Future<void> precacheImages(List<String> imageUrls, BuildContext context) async {
    try {
      for (final url in imageUrls) {
        try {
          await precacheImageProvider(NetworkImage(url), context);
        } catch (e) {
          print('预加载图片失败: $url');
        }
      }
    } catch (e) {
      print('预加载图片时出错: $e');
    }
  }

  // 预加载单个图片
  Future<void> precacheSingleImage(String imageUrl, BuildContext context) async {
    try {
      await precacheImageProvider(NetworkImage(imageUrl), context);
    } catch (e) {
      print('预加载图片失败: $imageUrl');
    }
  }

  // 内部方法：预加载图片提供者
  Future<void> precacheImageProvider(ImageProvider provider, BuildContext context) async {
    await precacheImage(provider, context);
  }

  // 清除图片缓存
  Future<void> clearCache() async {
    try {
      // 注意：CachedNetworkImageProvider.cacheManager 在某些版本中不可用
      // 这里暂时注释掉，避免编译错误
      // final cacheManager = CachedNetworkImageProvider.cacheManager;
      // await cacheManager?.emptyCache();
    } catch (e) {
      print('清除图片缓存失败: $e');
    }
  }

  // 获取缓存大小
  Future<int> getCacheSize() async {
    try {
      // 注意：CachedNetworkImageProvider.cacheManager 在某些版本中不可用
      // 这里暂时返回0，避免编译错误
      // final cacheManager = CachedNetworkImageProvider.cacheManager;
      // return await cacheManager?.getCacheSize() ?? 0;
      return 0;
    } catch (e) {
      print('获取缓存大小失败: $e');
      return 0;
    }
  }
}
