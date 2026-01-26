import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import '../models/lyrics_api_type.dart';
import '../components/home_player_widget.dart';
import 'random_songs_page.dart';
import 'newest_albums_page.dart';
import 'similar_songs_page.dart';
import 'detail_page.dart';
import 'settings_page.dart';
import 'search_page.dart';
import 'player_page.dart';

//有状态组件statefulWidget,接受api实例和播放器服务
class HomePage extends StatefulWidget {
  final SubsonicApi api;

  final PlayerService playerService;

  final Future<List<Map<String, dynamic>>> randomSongsFuture;

  final Future<List<Map<String, dynamic>>> Function() onRefreshRandomSongs;

  final Function(ThemeMode)? setThemeMode;

  const HomePage({
    super.key,
    required this.api,
    required this.playerService,
    required this.randomSongsFuture,
    required this.onRefreshRandomSongs,
    this.setThemeMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _randomAlbumsFuture;
  late Future<List<Map<String, dynamic>>> _recentPlayedFuture;
  String? _currentSongId;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    if (!_isInitialized) {
      _randomAlbumsFuture = widget.api.getRandomAlbums(size: 9);
      _recentPlayedFuture = widget.playerService.getRecentSongs(count: 5);
      _currentSongId = widget.playerService.currentSong?['id'];
      widget.playerService.addListener(_onPlayerStateChanged);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    widget.playerService.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    // 只在歌曲真正改变时才刷新最近播放列表
    final newSongId = widget.playerService.currentSong?['id'];
    if (newSongId != _currentSongId) {
      _currentSongId = newSongId;
      if (mounted) {
        setState(() {
          _recentPlayedFuture = widget.playerService.getRecentSongs(count: 5);
        });
      }
    }

    // 播放状态改变时也要更新UI（用于更新播放/暂停按钮）
    if (mounted) {
      setState(() {});
    }
  }

  //构建ui (核心方法)
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 64),

        _buildWelcomeSection(),

        const SizedBox(height: 32),

        // Home Player Widget
        HomePlayerWidget(
          coverUrl: widget.playerService.currentSong?['coverArt'] != null
              ? widget.api.getCoverArtUrl(
                  widget.playerService.currentSong?['coverArt'],
                )
              : null,
          isPlaying: widget.playerService.isPlaying,
          onPlayPause: widget.playerService.togglePlayPause,
          onNext: widget.playerService.nextSong,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerPage(
                  playerService: widget.playerService,
                  api: widget.api,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 48),
        _buildQuickAccess(),

        const SizedBox(height: 24),

        _buildRandomSongs(),

        const SizedBox(height: 24),

        _buildRecentlyPlayed(),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '发现好音乐',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Material(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: const CircleBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(
                          api: widget.api,
                          playerService: widget.playerService,
                          setThemeMode: widget.setThemeMode ?? (mode) {},
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person_rounded,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(28),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchPage(
                      api: widget.api,
                      playerService: widget.playerService,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(28),
              child: IgnorePointer(
                child: SearchBar(
                  hintText: '搜索歌曲、专辑、艺人...',
                  hintStyle: WidgetStatePropertyAll(
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  elevation: WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  padding: WidgetStatePropertyAll(
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  ),
                ),
              ),
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
            '最新专辑',
            Icons.new_releases_rounded,
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.onPrimaryContainer,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewestAlbumsPage(
                    api: widget.api,
                    playerService: widget.playerService,
                  ),
                ),
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
            '推荐歌曲',
            Icons.recommend_rounded,
            Theme.of(context).colorScheme.tertiaryContainer,
            Theme.of(context).colorScheme.onTertiaryContainer,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SimilarSongsPage(
                    api: widget.api,
                    playerService: widget.playerService,
                  ),
                ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: iconColor),
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
                '随机专辑',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _refreshRandomAlbums,
                tooltip: '刷新推荐',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
        ),
        _buildRandomAlbumsList(),
      ],
    );
  }

  Widget _buildRecentlyPlayed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            '最近常听',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 0),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _recentPlayedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
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
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '加载失败',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final songs = snapshot.data ?? [];

            if (songs.isEmpty) {
              return Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
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
              );
            }

            return Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 80),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return _buildRecentSongItem(song, songs);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentSongItem(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> playlist,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: song['coverArt'] != null
            ? CachedNetworkImage(
                imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
            : Container(
                width: 56,
                height: 56,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
      ),
      title: Text(
        song['title'] ?? '未知标题',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song['artist'] ?? '未知艺术家',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _playSong(song, playlist),
    );
  }

  void _playSong(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> playlist,
  ) {
    widget.playerService.playSong(
      song,
      sourceType: 'history',
      playlist: playlist,
    );
  }

  Widget _buildRandomAlbumsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _randomAlbumsFuture,
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

        final albums = snapshot.data ?? [];
        if (albums.isEmpty) {
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
                    Icons.album_rounded,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无推荐专辑',
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
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == albums.length - 1 ? 0 : 12,
                ),
                child: _buildAlbumCard(album),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    return InkWell(
      onTap: () => _openAlbum(album),
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
                child: _buildAlbumCover(album),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album['name'] ?? '未知专辑',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album['artist'] ?? '未知艺术家',
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

  //专辑封面定义
  Widget _buildAlbumCover(Map<String, dynamic> album) {
    final borderRadius = BorderRadius.circular(16);

    if (album['coverArt'] != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: widget.api.getCoverArtUrl(album['coverArt']),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.album_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.album_rounded,
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
        Icons.album_rounded,
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

  // 打开专辑详情
  void _openAlbum(Map<String, dynamic> album) {
    if (album['id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailPage(
            api: widget.api,
            playerService: widget.playerService,
            item: album,
            type: DetailType.album,
            sourceType: 'random_album',
          ),
        ),
      );
    }
  }

  // 刷新随机专辑
  void _refreshRandomAlbums() {
    setState(() {
      _randomAlbumsFuture = widget.api.getRandomAlbums(size: 9);
    });
  }

  // 刷新所有数据
  Future<void> _refreshData() async {
    // await widget.onRefreshRandomSongs();
    if (mounted) {
      setState(() {});
    }
  }
}
