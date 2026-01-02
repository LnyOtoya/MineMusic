import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'random_songs_page.dart';

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
          const SizedBox(height: 16),

          _buildWelcomeSection(),

          const SizedBox(height: 16),

          _buildQuickAccess(),

          const SizedBox(height: 24),

          _buildRandomSongs(),

          const SizedBox(height: 24),

          _buildRecentlyPlayed(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '发现好音乐',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildQuickAccessCard(
            '推荐歌单',
            Icons.playlist_play_rounded,
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.onPrimaryContainer,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('查看推荐歌单')),
              );
            },
          ),
          const SizedBox(width: 16),
          _buildQuickAccessCard(
            '随机歌曲',
            Icons.shuffle_rounded,
            Theme.of(context).colorScheme.secondaryContainer,
            Theme.of(context).colorScheme.onSecondaryContainer,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RandomSongsPage(
                    api: widget.api,
                    playerService: widget.playerService,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          _buildQuickAccessCard(
            '最近常听',
            Icons.history_rounded,
            Theme.of(context).colorScheme.tertiaryContainer,
            Theme.of(context).colorScheme.onTertiaryContainer,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('查看最近常听')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
    String title,
    IconData icon,
    Color containerColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Card(
        elevation: 0,
        color: containerColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: iconColor,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRandomSongs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Text(
                '随机歌曲',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
        _buildRandomSongsList(),
      ],
    );
  }

  Widget _buildRecentlyPlayed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Text(
                '最近常听',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('查看播放历史')),
                  );
                },
                child: Text(
                  '查看全部',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 80),
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  '暂无播放记录',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRandomSongsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.randomSongsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
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
                ],
              ),
            ),
          );
        }

        final songs = snapshot.data ?? [];
        if (songs.isEmpty) {
          return Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
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

        return Container(
          height: 200,
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == songs.length - 1 ? 0 : 12,
                ),
                child: _buildSongCard(song),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSongCard(Map<String, dynamic> song) {
    return InkWell(
      onTap: () => _playSong(song),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: _buildSongCover(song),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['title'] ?? '未知标题',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song['artist'] ?? '未知艺术家',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
