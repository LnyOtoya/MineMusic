import 'package:http/http.dart' as http;
import 'dart:convert';
import '../subsonic/subsonic_api_base.dart';

// 歌手头像相关API
class SubsonicArtistAvatar extends SubsonicApiBase {
  SubsonicArtistAvatar({
    required super.baseUrl,
    required super.username,
    required super.password,
  });

  // 获取歌手头像
  Future<String?> getArtistAvatar(
    String artistName, {
    String? artistId,
    String? songTitle,
  }) async {
    try {
      // 构建搜索请求，使用歌曲名+歌手名作为关键词，这样更准确
      final searchKeyword = songTitle != null && songTitle.isNotEmpty
          ? '$songTitle+$artistName'
          : artistName;
      final searchUrl = Uri.parse(
        'http://192.168.2.3:4555/search/search_by_type',
      );
      final searchParams = {'keyword': searchKeyword, 'searchtype': 'singer'};
      final searchRequestUrl = searchUrl.replace(queryParameters: searchParams);
      print('🔍 搜索歌手: $searchKeyword');
      print('📡 搜索URL: $searchRequestUrl');

      // 发送搜索请求
      final searchResponse = await http.get(searchRequestUrl);
      print('📡 搜索响应状态: ${searchResponse.statusCode}');

      if (searchResponse.statusCode == 200) {
        // 解析搜索响应
        final searchData = json.decode(searchResponse.body);
        print('📄 搜索响应数据: ${json.encode(searchData)}');

        // 检查搜索结果
        if (searchData['code'] == 200 &&
            searchData['data'] is List &&
            searchData['data'].isNotEmpty) {
          // 遍历搜索结果，找到与歌手名完全匹配的结果
          for (final result in searchData['data']) {
            // 检查是否有singer字段
            if (result['singer'] is List && result['singer'].isNotEmpty) {
              // 遍历歌手列表，找到与歌手名完全匹配的歌手
              for (final singerInfo in result['singer']) {
                final singerName = singerInfo['name'] as String?;
                print('🔍 搜索到歌手: $singerName');
                // 检查歌手名是否与目标歌手名完全匹配（忽略大小写）
                if (singerName != null &&
                    singerName.toLowerCase() == artistName.toLowerCase()) {
                  // 提取歌手的mid
                  final singerMid = singerInfo['mid'] as String?;
                  if (singerMid != null && singerMid.isNotEmpty) {
                    print('✅ 找到匹配的歌手mid: $singerMid');

                    // 使用歌手mid调用歌手API获取头像
                    final singerUrl = Uri.parse(
                      'http://192.168.2.3:4555/singer/get_info',
                    );
                    final singerParams = {'mid': singerMid};
                    final singerRequestUrl = singerUrl.replace(
                      queryParameters: singerParams,
                    );
                    print('📡 歌手API URL: $singerRequestUrl');

                    // 发送歌手API请求
                    final singerResponse = await http.get(singerRequestUrl);
                    print('📡 歌手API响应状态: ${singerResponse.statusCode}');

                    if (singerResponse.statusCode == 200) {
                      // 解析歌手API响应
                      final singerData = json.decode(singerResponse.body);
                      print('📄 歌手API响应数据: ${json.encode(singerData)}');

                      // 检查歌手API响应
                      if (singerData['code'] == 200 &&
                          singerData['data'] != null) {
                        final data = singerData['data'];
                        // 提取头像URL（优先使用BackgroundImage字段）
                        if (data['Info'] != null &&
                            data['Info']['BaseInfo'] != null) {
                          final baseInfo = data['Info']['BaseInfo'];
                          final avatarUrl = 
                              baseInfo['BackgroundImage'] as String?;
                          if (avatarUrl != null && avatarUrl.isNotEmpty) {
                            print('✅ 从BackgroundImage获取到歌手头像: $avatarUrl');
                            return avatarUrl;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          // 如果没有找到完全匹配的结果，使用第一个搜索结果
          print('⚠️ 没有找到完全匹配的歌手，使用第一个搜索结果');
          final firstResult = searchData['data'][0];
          if (firstResult['singer'] is List &&
              firstResult['singer'].isNotEmpty) {
            final singerInfo = firstResult['singer'][0];
            final singerMid = singerInfo['mid'] as String?;
            if (singerMid != null && singerMid.isNotEmpty) {
              print('✅ 使用第一个搜索结果的歌手mid: $singerMid');

              // 使用歌手mid调用歌手API获取头像
              final singerUrl = Uri.parse(
                'http://192.168.2.3:4555/singer/get_info',
              );
              final singerParams = {'mid': singerMid};
              final singerRequestUrl = singerUrl.replace(
                queryParameters: singerParams,
              );
              print('📡 歌手API URL: $singerRequestUrl');

              // 发送歌手API请求
              final singerResponse = await http.get(singerRequestUrl);
              print('📡 歌手API响应状态: ${singerResponse.statusCode}');

              if (singerResponse.statusCode == 200) {
                // 解析歌手API响应
                final singerData = json.decode(singerResponse.body);
                print('📄 歌手API响应数据: ${json.encode(singerData)}');

                // 检查歌手API响应
                if (singerData['code'] == 200 && singerData['data'] != null) {
                  final data = singerData['data'];
                  // 提取头像URL（优先使用BackgroundImage字段）
                  if (data['Info'] != null &&
                      data['Info']['BaseInfo'] != null) {
                    final baseInfo = data['Info']['BaseInfo'];
                    final avatarUrl = baseInfo['BackgroundImage'] as String?;
                    if (avatarUrl != null && avatarUrl.isNotEmpty) {
                      print('✅ 从BackgroundImage获取到歌手头像: $avatarUrl');
                      return avatarUrl;
                    }
                  }
                }
              }
            }
          }
        }
      }

      // 如果没有找到头像，返回固定的头像链接
      return 'http://y.gtimg.cn/music/photo_new/T001R800x800M000002hhhmu0fwrK5_3.jpg';
    } catch (e) {
      print('获取歌手头像失败: $e');
      return null;
    }
  }
}
