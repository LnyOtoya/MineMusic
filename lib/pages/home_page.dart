import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';

class HomePage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  
  const HomePage({super.key, required this.api, required this.playerService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _randomSongsFuture;
  
  @override
  void initState() {
    super.initState();
    _randomSongsFuture = widget.api.getRandomSongs(count: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          children: [

            // _buildMaterialYouTest(context),
            // 欢迎区域
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '发现新音乐',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            
            // 快速访问区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '快速访问',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            // 横向滚动的功能卡片列表
            Container(
              height: 130, // 固定高度以限制卡片区域
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal, // 横向滚动
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 1. 按时间推荐
                  _buildFeatureCard(
                    context,
                    '按时间推荐',
                    Icons.access_time,
                    Theme.of(context).colorScheme.primary,
                    // Colors.blue,
                    width: 190,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('查看按时间推荐')),
                      );
                    },
                  ),
                  const SizedBox(width: 16), // 卡片间距

                  // 2. 每日推荐
                  _buildFeatureCard(
                    context,
                    '每日推荐',
                    Icons.calendar_today,
                    Theme.of(context).colorScheme.primary,
                    // Colors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('查看每日推荐')),
                      );
                    },
                  ),
                  const SizedBox(width: 16),

                  // 3. 最近播放
                  _buildFeatureCard(
                    context,
                    '最近播放',
                    Icons.history,
                    // Colors.orange,
                    Theme.of(context).colorScheme.primary,
                    onTap: _viewRecentPlays, // 复用原方法
                  ),
                  const SizedBox(width: 16),

                  // 4. 最近添加
                  _buildFeatureCard(
                    context,
                    '最近添加',
                    Icons.add,
                    // Colors.purple,
                    Theme.of(context).colorScheme.primary,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('查看最近添加')),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // 推荐歌曲区域
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Text(
                    '推荐歌曲',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshRandomSongs,
                    tooltip: '刷新推荐',
                  ),
                ],
              ),
            ),
            
            // 随机歌曲列表
            _buildRandomSongsList(),
          ],
        ),
      ),
    );
  }




  Widget _buildRandomSongsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _randomSongsFuture,
      builder: (context, snapshot) {
        // 加载中状态（保持不变）
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 380,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        // 错误状态（保持不变）
        if (snapshot.hasError) {
          return Container(
            height: 380,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '加载失败',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _refreshRandomSongs,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }
        
        final songs = snapshot.data ?? [];
        
        // 空状态（保持不变）
        if (songs.isEmpty) {
          return Container(
            height: 380,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '暂无推荐歌曲',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        
        // 网格布局主体（核心修改处）
        return Container(
          // 增加底部margin，为悬浮播放器预留空间（通常播放器高度在60-80之间）
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 80), 
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 18,
              mainAxisSpacing: 20,
              childAspectRatio: 0.65,
            ),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return InkWell(
                onTap: () => _playSong(song),
                borderRadius: BorderRadius.circular(12),
                splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: _buildSongCover(song),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        (song['title'] ?? '未知标题').length > 10
                            ? '${(song['title'] ?? '未知标题').substring(0, 10)}...'
                            : song['title'] ?? '未知标题',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        song['artist'] ?? '未知艺术家',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }


  Widget _buildSongCover(Map<String, dynamic> song) {
    // 统一圆角值（与推荐区域容器圆角保持一致）
    final borderRadius = BorderRadius.circular(8);

    // 优先使用歌曲自身的封面
    if (song['coverArt'] != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          width: 40,
          height: 40,
          child: CachedNetworkImage(
            imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }
    
    // 如果歌曲没有封面，尝试使用专辑封面
    if (song['albumId'] != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          width: 40,
          height: 40,
          child: CachedNetworkImage(
            imageUrl: widget.api.getCoverArtUrl(song['albumId']),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }
    
    // 默认显示音乐图标（容器自带圆角）
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: 24,
      ),
    );
  }

  // 修改_buildFeatureCard方法，添加width参数
  Widget _buildFeatureCard(
    BuildContext context, 
    String title, 
    IconData icon, 
    Color color, {
    VoidCallback? onTap,
    double? width, // 新增宽度参数，可选
  }) {
    // 默认宽度为正方形（120），如果指定了宽度则使用指定值
    final cardWidth = width ?? 120;
    
    return SizedBox(
      width: cardWidth, // 使用指定宽度
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }


  // 获取问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '深夜好!';
    } else if (hour < 12) {
      return '早上好!';
    } else if (hour < 18) {
      return '下午茶!';
    } else {
      return '晚上好!';
    }
  }

  // 播放随机歌曲
  void _playRandomSongs() async {
    try {
      final randomSongs = await widget.api.getRandomSongs(count: 5);
      if (randomSongs.isNotEmpty) {
        widget.playerService.playSong(randomSongs.first, sourceType: 'random', playlist: randomSongs);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('开始随机播放: ${randomSongs.first['title']}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('播放失败: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // 播放单首歌曲
  void _playSong(Map<String, dynamic> song) {
    widget.playerService.playSong(
      song,
      sourceType: 'recommendation',
      playlist: [], // 可以根据需要传入完整播放列表
    );
  }

  // 查看最近播放
  void _viewRecentPlays() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('查看最近播放')),
    );
  }

  // 刷新推荐歌曲
  void _refreshRandomSongs() {
    setState(() {
      _randomSongsFuture = widget.api.getRandomSongs(count: 9);
    });
  }

  // 刷新所有数据
  Future<void> _refreshData() async {
    setState(() {
      _randomSongsFuture = widget.api.getRandomSongs(count: 9);
    });
  }
}
