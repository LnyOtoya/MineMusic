import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/lastfm_api.dart';
import '../utils/test_config.dart';

class LastFMTestPage extends StatefulWidget {
  const LastFMTestPage({super.key});

  @override
  State<LastFMTestPage> createState() => _LastFMTestPageState();
}

class _LastFMTestPageState extends State<LastFMTestPage> {
  final LastFMApi _api = LastFMApi();
  final List<String> _logs = [];

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _authToken;
  String? _authUrl;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _addLog('测试页面已加载');
    _addLog('API Key: ${TestConfig.lastFMApiKey.substring(0, 8)}...');
    _addLog('Shared Secret: ${TestConfig.lastFMSharedSecret.substring(0, 8)}...');
  }

  Future<void> _checkAuthStatus() async {
    final authenticated = await _api.isAuthenticated();
    setState(() {
      _isAuthenticated = authenticated;
    });
    _addLog('授权状态: ${authenticated ? "已授权" : "未授权"}');
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _testGetAuthToken() async {
    _addLog('开始测试: 获取授权Token...');
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _api.getAuthToken();
      _addLog('✅ Token获取成功: $token');
    } catch (e) {
      _addLog('❌ Token获取失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuthFlow() async {
    _addLog('开始测试: 完整授权流程...');
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _api.getAuthToken();
      _addLog('✅ 步骤1: Token获取成功');

      final authUrl = 'https://www.last.fm/api/auth/?api_key=${TestConfig.lastFMApiKey}&token=$token';
      _addLog('✅ 步骤2: 授权URL已生成');
      _addLog('📋 授权URL: $authUrl');

      setState(() {
        _authToken = token;
        _authUrl = authUrl;
      });

      _addLog('⏳ 步骤3: 点击下方"打开授权页面"按钮，在浏览器中完成授权');
    } catch (e) {
      _addLog('❌ 授权流程失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCompleteAuth() async {
    if (_authToken == null) {
      _addLog('❌ 请先运行"完整授权流程"获取token');
      return;
    }

    _addLog('开始测试: 完成授权...');
    setState(() {
      _isLoading = true;
    });

    try {
      await _api.getSessionKey(_authToken!);
      _addLog('✅ Session Key获取成功');
      await _checkAuthStatus();
      
      setState(() {
        _authToken = null;
        _authUrl = null;
      });
    } catch (e) {
      _addLog('❌ 完成授权失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetUserInfo() async {
    _addLog('开始测试: 获取用户信息...');
    setState(() {
      _isLoading = true;
    });

    try {
      final userInfo = await _api.getUserInfo();
      _addLog('✅ 用户信息获取成功');
      _addLog('   用户名: ${userInfo['name']}');
      _addLog('   总播放: ${userInfo['playcount']}');
      _addLog('   艺术家数: ${userInfo['artist_count']}');
      _addLog('   专辑数: ${userInfo['album_count']}');
      _addLog('   歌曲数: ${userInfo['track_count']}');
    } catch (e) {
      _addLog('❌ 获取用户信息失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetRecentTracks() async {
    _addLog('开始测试: 获取最近播放...');
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _api.getRecentTracks(limit: 5);
      final tracks = result['tracks'] as List<dynamic>? ?? [];
      _addLog('✅ 最近播放获取成功，共 ${tracks.length} 首');
      
      for (var i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        final isNowPlaying = track['isNowPlaying'] ?? false;
        final status = isNowPlaying ? '🎵 正在播放' : '▶️ 已播放';
        _addLog('   ${i + 1}. $status ${track['name']} - ${track['artist']}');
      }
    } catch (e) {
      _addLog('❌ 获取最近播放失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetTopArtists() async {
    _addLog('开始测试: 获取顶级艺术家...');
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _api.getTopArtists(limit: 5);
      final artists = result['artists'] as List<dynamic>? ?? [];
      _addLog('✅ 顶级艺术家获取成功，共 ${artists.length} 位');
      
      for (var i = 0; i < artists.length; i++) {
        final artist = artists[i];
        _addLog('   ${i + 1}. ${artist['name']} - 播放 ${artist['playcount']} 次');
      }
    } catch (e) {
      _addLog('❌ 获取顶级艺术家失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetTopAlbums() async {
    _addLog('开始测试: 获取顶级专辑...');
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _api.getTopAlbums(limit: 5);
      final albums = result['albums'] as List<dynamic>? ?? [];
      _addLog('✅ 顶级专辑获取成功，共 ${albums.length} 张');
      
      for (var i = 0; i < albums.length; i++) {
        final album = albums[i];
        _addLog('   ${i + 1}. ${album['name']} - ${album['artist']} - 播放 ${album['playcount']} 次');
      }
    } catch (e) {
      _addLog('❌ 获取顶级专辑失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetTopTracks() async {
    _addLog('开始测试: 获取顶级歌曲...');
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _api.getTopTracks(limit: 5);
      final tracks = result['tracks'] as List<dynamic>? ?? [];
      _addLog('✅ 顶级歌曲获取成功，共 ${tracks.length} 首');
      
      for (var i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        _addLog('   ${i + 1}. ${track['name']} - ${track['artist']} - 播放 ${track['playcount']} 次');
      }
    } catch (e) {
      _addLog('❌ 获取顶级歌曲失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogout() async {
    _addLog('开始测试: 退出登录...');
    setState(() {
      _isLoading = true;
    });

    try {
      await _api.logout();
      _addLog('✅ 退出登录成功');
      await _checkAuthStatus();
    } catch (e) {
      _addLog('❌ 退出登录失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    setState(() {
      _logs.clear();
    });
    _addLog('日志已清空');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Last.fm API 测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _clearLogs,
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isAuthenticated ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '配置状态',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            _isAuthenticated ? '已授权' : '未授权',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '授权测试',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGetAuthToken,
                      child: const Text('获取Token'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testAuthFlow,
                      child: const Text('完整授权流程'),
                    ),
                    if (_authUrl != null)
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : () async {
                          final uri = Uri.parse(_authUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            _addLog('❌ 无法打开授权页面');
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('打开授权页面'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testCompleteAuth,
                      child: const Text('完成授权'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testLogout,
                      child: const Text('退出登录'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  '数据获取测试',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGetUserInfo,
                      child: const Text('用户信息'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGetRecentTracks,
                      child: const Text('最近播放'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGetTopArtists,
                      child: const Text('顶级艺术家'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGetTopAlbums,
                      child: const Text('顶级专辑'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testGetTopTracks,
                      child: const Text('顶级歌曲'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  '测试日志',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _logs.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          _logs[index],
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
