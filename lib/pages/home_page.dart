import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';

//有状态组件statefulWidget,接受api实例和播放器服务
class HomePage extends StatefulWidget {
  //网络请求
  final SubsonicApi api;

  //播放控制
  final PlayerService playerService;

  final Future<List<Map<String, dynamic>>> randomSongsFuture;

  final Future<List<Map<String, dynamic>>> Function() onRefreshRandomSongs;

  final ScrollController? scrollController;

  const HomePage({
    super.key,
    required this.api,
    required this.playerService,
    required this.randomSongsFuture,
    required this.onRefreshRandomSongs,
    this.scrollController,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 储存随机歌曲的future对象
  late Future<List<Map<String, dynamic>>> _randomSongsFuture;

  @override
  void initState() {
    super.initState();

    // 初始化时加载歌曲的数量(在initState中调用getRandomSongs加载歌曲)
    _randomSongsFuture = widget.api.getRandomSongs(count: 9);
  }

  //构建ui (核心方法)
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      onRefresh: _refreshData,
      child: ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        children: [
          // _buildMaterialYouTest(context),

          // 欢迎区域
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '发现新音乐',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 快速访问区域
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Text(
              '快速访问',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // 快速访问区域--横向滚动的功能卡片列表
          //使用MD3的FilledCard实现更好的视觉效果
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildFeatureCard(
                  context,
                  '按时间推荐',
                  Icons.access_time_rounded,
                  Theme.of(context).colorScheme.primaryContainer,
                  width: 160,
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('查看按时间推荐')));
                  },
                ),
                const SizedBox(width: 12),
                _buildFeatureCard(
                  context,
                  '每日推荐',
                  Icons.calendar_today_rounded,
                  Theme.of(context).colorScheme.secondaryContainer,
                  width: 160,
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('查看每日推荐')));
                  },
                ),
                const SizedBox(width: 12),
                _buildFeatureCard(
                  context,
                  '最近播放',
                  Icons.history_rounded,
                  Theme.of(context).colorScheme.tertiaryContainer,
                  width: 160,
                  onTap: _viewRecentPlays,
                ),
                const SizedBox(width: 12),
                _buildFeatureCard(
                  context,
                  '最近添加',
                  Icons.add_circle_rounded,
                  Theme.of(context).colorScheme.primaryContainer,
                  width: 160,
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('查看最近添加')));
                  },
                ),
              ],
            ),
          ),

          // 推荐歌曲区域
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                Text(
                  '推荐歌曲',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton.filled(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _refreshRandomSongs,
                  tooltip: '刷新推荐',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),

          // 随机歌曲列表
          _buildRandomSongsList(),
        ],
      ),
    );
  }

  //随机歌曲列表
  Widget _buildRandomSongsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      // future: _randomSongsFuture,
      future: widget.randomSongsFuture,
      builder: (context, snapshot) {
        // 加载中状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            constraints: const BoxConstraints(minHeight: 380),
            margin: const EdgeInsets.fromLTRB(24, 8, 24, 80),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // 错误状态
        if (snapshot.hasError) {
          return Container(
            constraints: const BoxConstraints(minHeight: 380),
            margin: const EdgeInsets.fromLTRB(24, 8, 24, 80),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text('加载失败', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _refreshRandomSongs,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }

        final songs = snapshot.data ?? [];
        // 空状态
        if (songs.isEmpty) {
          return Container(
            constraints: const BoxConstraints(minHeight: 380),
            margin: const EdgeInsets.fromLTRB(24, 8, 24, 80),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无推荐歌曲',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        //成功状态：歌曲网格
        return Container(
          margin: const EdgeInsets.fromLTRB(24, 8, 24, 80),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: 0.78,
            ),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];

              return InkWell(
                onTap: () => _playSong(song),
                borderRadius: BorderRadius.circular(16),
                splashColor: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        child: _buildSongCover(song),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        song['title'] ?? '未知标题',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        song['artist'] ?? '未知艺术家',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          height: 1.1,
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

  //歌曲封面定义
  Widget _buildSongCover(Map<String, dynamic> song) {
    final borderRadius = BorderRadius.circular(16);

    if (song['coverArt'] != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
        ),
      );
    }

    if (song['albumId'] != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: widget.api.getCoverArtUrl(song['albumId']),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }

  //快速访问卡片定义
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    double? width,
  }) {
    final cardWidth = width ?? 120;

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.2),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
        widget.playerService.playSong(
          randomSongs.first,
          sourceType: 'random',
          playlist: randomSongs,
        );

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
    // 获取当前推荐歌曲列表
    widget.randomSongsFuture.then((songs) {
      widget.playerService.playSong(
        song,
        sourceType: 'recommendation',
        playlist: songs, // 传入完整推荐列表作为播放列表
      );
    });
  }

  // 查看最近播放
  void _viewRecentPlays() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('查看最近播放')));
  }

  // 刷新推荐歌曲
  void _refreshRandomSongs() {
    // 调用父组件的刷新回调并等待结果，然后触发UI更新
    widget.onRefreshRandomSongs().then((_) {
      if (mounted) {
        setState(() {}); // 强制重建UI以显示新数据
      }
    });
  }

  // 刷新所有数据
  Future<void> _refreshData() async {
    await widget.onRefreshRandomSongs();
    if (mounted) {
      setState(() {});
    }
    // setState(() {
    //   _randomSongsFuture = widget.api.getRandomSongs(count: 9);
    // });
  }
}
