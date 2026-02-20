import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import '../services/image_cache_service.dart';
import '../components/home_player_widget.dart';
import 'random_songs_page.dart';
import 'newest_albums_page.dart';
import 'similar_songs_page.dart';
import 'detail_page.dart';
import 'settings_page.dart';
import 'search_page.dart';
import 'full_playlist_page.dart';

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
      _preloadImages();
      _isInitialized = true;
    }
  }

  // 预加载关键图片
  void _preloadImages() {
    // 预加载当前播放歌曲的封面
    if (widget.playerService.currentSong?['coverArt'] != null && context.mounted) {
      final coverUrl = widget.api.getCoverArtUrl(
        widget.playerService.currentSong?['coverArt'],
      );
      ImageCacheService().precacheSingleImage(coverUrl, context);
    }

    // 预加载随机专辑的封面
    _randomAlbumsFuture.then((albums) {
      if (context.mounted) {
        final imageUrls = albums
            .where((album) => album['coverArt'] != null)
            .map((album) => widget.api.getCoverArtUrl(album['coverArt']))
            .toList();
        ImageCacheService().precacheImages(imageUrls, context);
      }
    }).catchError((error) {
      print('预加载专辑封面失败: $error');
    });

    // 预加载最近播放歌曲的封面
    _recentPlayedFuture.then((songs) {
      if (context.mounted) {
        final imageUrls = songs
            .where((song) => song['coverArt'] != null)
            .map((song) => widget.api.getCoverArtUrl(song['coverArt']))
            .toList();
        ImageCacheService().precacheImages(imageUrls, context);
      }
    }).catchError((error) {
      print('预加载最近播放歌曲封面失败: $error');
    });
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HomePlayerWidget(
            coverUrl: widget.playerService.currentSong?['coverArt'] != null
                ? widget.api.getCoverArtUrl(
                    widget.playerService.currentSong?['coverArt'],
                  )
                : null,
            isPlaying: widget.playerService.isPlaying,
            onPlayPause: widget.playerService.togglePlayPause,
            onNext: widget.playerService.nextSong,
          ),
        ),

        const SizedBox(height: 48),

        // 当前播放列表
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildRecentlyPlayed(),
        ),

        const SizedBox(height: 40),
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
    final playlist = widget.playerService.currentPlaylist;
    final currentIndex = widget.playerService.currentIndex;
    final currentSong = widget.playerService.currentSong;

    // 构建显示列表：当前播放的歌曲 + 接下来的2首歌曲
    List<Map<String, dynamic>> displayList = [];
    
    if (currentSong != null) {
      displayList.add(currentSong);
      
      // 添加接下来的歌曲
      if (playlist.isNotEmpty) {
        // 找到当前歌曲在播放列表中的索引
        int songIndex = playlist.indexWhere((s) => s['id'] == currentSong['id']);
        
        // 如果找到了当前歌曲，从下一首开始添加
        if (songIndex >= 0) {
          for (int i = 1; i <= 2 && (songIndex + i) < playlist.length; i++) {
            displayList.add(playlist[songIndex + i]);
          }
        } else if (currentIndex >= 0) {
          // 如果currentIndex有效，从那里开始添加
          for (int i = 1; i <= 2 && (currentIndex + i) < playlist.length; i++) {
            displayList.add(playlist[currentIndex + i]);
          }
        } else {
          // 如果都无效，从第一首开始添加（除了当前歌曲）
          for (int i = 0; i < playlist.length && displayList.length < 3; i++) {
            final song = playlist[i];
            if (song['id'] != currentSong['id']) {
              displayList.add(song);
            }
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 整个分组容器
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // 当前播放列表头部（顶部圆角）
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '正在播放~',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '当前列表有${playlist.length}首歌',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 歌曲列表
              if (displayList.isEmpty)
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '暂无播放列表',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // 歌曲列表 - 始终显示3首
                    for (int i = 0; i < displayList.length && i < 3; i++)
                      Container(
                        child: _buildPlaylistSongItem(
                          displayList[i], 
                          i == 0, // isCurrent
                          false, // isFirst (now part of the group)
                          false, // isLast (now part of the group)
                        ),
                      ),
                  ],
                ),
              
              // 查看全部链接（底部圆角）
              if (playlist.length > 5)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullPlaylistPage(
                          playlist: playlist,
                          currentIndex: currentIndex,
                          playerService: widget.playerService,
                          api: widget.api,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '浏览所有',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistSongItem(
    Map<String, dynamic> song,
    bool isCurrent,
    bool isFirst,
    bool isLast,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: song['coverArt'] != null
              ? CachedNetworkImage(
                  imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholderFadeInDuration: Duration(milliseconds: 200),
                  fadeInDuration: Duration(milliseconds: 300),
                  placeholder: (context, url) => Container(
                    width: 56,
                    height: 56,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 56,
                    height: 56,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
        ),
        title: Text(
          song['title'] ?? '未知标题',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            color: isCurrent 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          song['artist'] ?? '未知艺术家',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () {
          if (!isCurrent) {
            final playlist = widget.playerService.currentPlaylist;
            final index = playlist.indexWhere((s) => s['id'] == song['id']);
            if (index != -1) {
              widget.playerService.playSongAt(index);
            }
          }
        },
      ),
    );
  }

  Widget _buildDailyMixSongItem(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> playlist,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: song['coverArt'] != null
              ? CachedNetworkImage(
                  imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholderFadeInDuration: Duration(milliseconds: 200),
                  fadeInDuration: Duration(milliseconds: 300),
                  placeholder: (context, url) => Container(
                    width: 56,
                    height: 56,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 56,
                    height: 56,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
        ),
        title: Text(
          song['title'] ?? '未知标题',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          song['artist'] ?? '未知艺术家',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: () {
            // 更多选项
          },
        ),
        onTap: () => _playSong(song, playlist),
      ),
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
          placeholderFadeInDuration: Duration(milliseconds: 200),
          fadeInDuration: Duration(milliseconds: 300),
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
