import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'detail_page.dart';
import 'artist_detail_page.dart';

class LibraryPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const LibraryPage({
    super.key,
    required this.api,
    required this.playerService,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int _selectedTab = 0; // 0: 歌曲列表, 1: 专辑, 2: 艺人, 3: 歌单

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
          child: SizedBox(width: double.infinity, child: _buildTabBar()),
        ),

        Expanded(child: _buildCurrentTab()),
      ],
    );
  }

  Widget _buildTabBar() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          label: Text('歌曲'),
          icon: Icon(Icons.music_note_rounded),
        ),
        ButtonSegment(
          value: 1,
          label: Text('专辑'),
          icon: Icon(Icons.album_rounded),
        ),
        ButtonSegment(
          value: 2,
          label: Text('艺人'),
          icon: Icon(Icons.person_rounded),
        ),
        ButtonSegment(
          value: 3,
          label: Text('歌单'),
          icon: Icon(Icons.playlist_play_rounded),
        ),
      ],
      selected: {_selectedTab},
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          _selectedTab = newSelection.first;
        });
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Theme.of(context).colorScheme.primaryContainer;
          }
          return Theme.of(context).colorScheme.surfaceContainerHighest;
        }),
        foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Theme.of(context).colorScheme.onPrimaryContainer;
          }
          return Theme.of(context).colorScheme.onSurfaceVariant;
        }),
      ),
    );
  }

  // 构建当前选中的标签内容
  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case 0:
        return SongsTab(api: widget.api, playerService: widget.playerService);
      case 1:
        return AlbumsTab(api: widget.api, playerService: widget.playerService);
      case 2:
        return ArtistsTab(api: widget.api, playerService: widget.playerService);
      case 3:
        return PlaylistsTab(
          api: widget.api,
          playerService: widget.playerService,
        );
      default:
        return SongsTab(api: widget.api, playerService: widget.playerService);
    }
  }
}

// 歌曲列表标签页
class SongsTab extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const SongsTab({super.key, required this.api, required this.playerService});

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab> {
  late Future<List<Map<String, dynamic>>> _songsFuture;
  List<Map<String, dynamic>>? _sortedSongs;

  @override
  void initState() {
    super.initState();
    _songsFuture = widget.api.getAllSongsViaSearch().then((songs) {
      // 排序后缓存到变量
      songs.sort((a, b) {
        final titleA = (a['title'] ?? '').toLowerCase();
        final titleB = (b['title'] ?? '').toLowerCase();
        return titleA.compareTo(titleB);
      });
      _sortedSongs = songs; // 缓存排序结果
      return songs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: 16),
                Text('加载失败: ${snapshot.error}'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _songsFuture = widget.api.getAllSongsViaSearch();
                    });
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final songs = snapshot.data ?? [];

        if (songs.isEmpty) {
          return const Center(child: Text('暂无歌曲'));
        }

        // 按歌曲标题字母顺序排序
        songs.sort((a, b) {
          final titleA = (a['title'] ?? '').toLowerCase();
          final titleB = (b['title'] ?? '').toLowerCase();
          return titleA.compareTo(titleB);
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    _playSong(song);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            child: song['coverArt'] != null
                                ? CachedNetworkImage(
                                    imageUrl: widget.api.getCoverArtUrl(
                                      song['coverArt'],
                                    ),
                                    fit: BoxFit.cover,
                                    width: 56,
                                    height: 56,
                                    placeholder: (context, url) => Icon(
                                      Icons.music_note_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.music_note_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : Icon(
                                    Icons.music_note_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song['title'] ?? '未知标题',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${song['artist'] ?? '未知艺术家'} • ${song['album'] ?? '未知专辑'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDuration(song['duration']),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(String? durationSeconds) {
    if (durationSeconds == null) return '--:--';
    try {
      final duration = int.tryParse(durationSeconds) ?? 0;
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  void _playSong(Map<String, dynamic> song) {
    print('播放歌曲: ${song['title']}');
    print('🎵 歌曲数据: $song');
    // 获取所有歌曲作为播放列表
    if (_sortedSongs != null) {
      // 确保列表已排序并缓存
      widget.playerService.playSong(
        song,
        sourceType: 'song',
        playlist: _sortedSongs, // 传入排序后的列表
      );
    }
  }
}

// 专辑标签页
class AlbumsTab extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const AlbumsTab({super.key, required this.api, required this.playerService});

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> {
  List<Map<String, dynamic>> _allAlbums = [];
  int _offset = 0;
  final int _pageSize = 30; // 每次加载30个专辑
  bool _hasMore = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  // 加载专辑数据
  Future<void> _loadAlbums() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newAlbums = await widget.api.getAlbums(
        size: _pageSize,
        offset: _offset,
      );

      setState(() {
        _allAlbums.addAll(newAlbums);
        _offset += _pageSize;
        _hasMore = newAlbums.length == _pageSize; // 如果返回数量小于页大小，说明没有更多数据
        _isLoading = false;
      });
    } catch (e) {
      print('加载专辑失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 构建加载更多指示器
  Widget _buildLoadMoreIndicator() {
    if (!_hasMore) {
      return const Padding(padding: EdgeInsets.all(16), child: Text('已加载全部专辑'));
    }

    return _isLoading
        ? const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        // 当滚动到列表底部时加载更多
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          _loadAlbums();
        }
        return true;
      },
      child: _allAlbums.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allAlbums.isEmpty
          ? const Center(child: Text('暂无专辑'))
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.55,
                        ),
                    itemCount: _allAlbums.length,
                    itemBuilder: (context, index) {
                      final album = _allAlbums[index];
                      return _buildAlbumCard(album);
                    },
                  ),
                ),
                _buildLoadMoreIndicator(),
              ],
            ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openAlbumDetail(album),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: album['coverArt'] != null
                    ? CachedNetworkImage(
                        imageUrl: widget.api.getCoverArtUrl(album['coverArt']),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.album_rounded,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.album_rounded,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.album_rounded,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album['name'] ?? '未知专辑',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album['artist'] ?? '未知艺术家',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAlbumDetail(Map<String, dynamic> album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          api: widget.api,
          playerService: widget.playerService,
          item: album,
          type: DetailType.album,
        ),
      ),
    );
  }
}

// 艺人标签页
class ArtistsTab extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const ArtistsTab({super.key, required this.api, required this.playerService});

  @override
  State<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {
  late Future<List<Map<String, dynamic>>> _artistsFuture;
  static List<Map<String, dynamic>>? _cachedArtists;

  @override
  void initState() {
    super.initState();
    _artistsFuture = _loadArtistsWithCover();
  }

  Future<List<Map<String, dynamic>>> _loadArtistsWithCover() async {
    if (_cachedArtists != null) {
      return _cachedArtists!;
    }

    final artists = await widget.api.getArtists();

    List<Map<String, dynamic>> artistsWithCover = [];

    for (var artist in artists) {
      String? coverArt;
      try {
        final albums = await widget.api.getAlbumsByArtist(artist['id']);
        if (albums.isNotEmpty && albums[0]['coverArt'] != null) {
          coverArt = albums[0]['coverArt'];
        }
      } catch (e) {
        print('获取艺人 ${artist['name']} 的专辑失败: $e');
      }

      artistsWithCover.add({...artist, 'coverArt': coverArt});
    }

    _cachedArtists = artistsWithCover;
    return artistsWithCover;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _artistsFuture,
      builder: (context, snapshot) {
        // 加载中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('加载艺术家列表中...'),
              ],
            ),
          );
        }

        // 出错
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('加载失败: ${snapshot.error}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _artistsFuture = widget.api.getArtists();
                    });
                  },
                  child: Text('重试'),
                ),
              ],
            ),
          );
        }

        // 成功加载数据
        final artists = snapshot.data ?? [];

        // 按艺术家名称字母顺序排序
        artists.sort((a, b) {
          final nameA = (a['name'] ?? '').toLowerCase();
          final nameB = (b['name'] ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArtistDetailPage(
                          api: widget.api,
                          playerService: widget.playerService,
                          artist: artist,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: artist['coverArt'] != null
                                ? CachedNetworkImage(
                                    imageUrl: widget.api.getCoverArtUrl(
                                      artist['coverArt'],
                                    ),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Icon(
                                      Icons.person_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.person_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artist['name'] ?? '未知艺术家',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '专辑数: ${artist['albumCount'] ?? 0}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 歌单标签页
class PlaylistsTab extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const PlaylistsTab({
    super.key,
    required this.api,
    required this.playerService,
  });

  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  late Future<List<Map<String, dynamic>>> _playlistsFuture;
  static List<Map<String, dynamic>>? _cachedPlaylists;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = _loadPlaylistsWithCover();
  }

  Future<List<Map<String, dynamic>>> _loadPlaylistsWithCover() async {
    if (_cachedPlaylists != null) {
      return _cachedPlaylists!;
    }

    final playlists = await widget.api.getPlaylists();

    List<Map<String, dynamic>> playlistsWithCover = [];

    for (var playlist in playlists) {
      String? coverArt;
      try {
        final songs = await widget.api.getPlaylistSongs(playlist['id']);
        if (songs.isNotEmpty && songs[0]['coverArt'] != null) {
          coverArt = songs[0]['coverArt'];
        }
      } catch (e) {
        print('获取歌单 ${playlist['name']} 的歌曲失败: $e');
      }

      playlistsWithCover.add({...playlist, 'coverArt': coverArt});
    }

    _cachedPlaylists = playlistsWithCover;
    return playlistsWithCover;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _playlistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: 16),
                Text('加载失败: ${snapshot.error}'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _playlistsFuture = widget.api.getPlaylists();
                    });
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final playlists = snapshot.data ?? [];

        if (playlists.isEmpty) {
          return const Center(child: Text('暂无歌单'));
        }

        // 按歌单名称字母顺序排序
        playlists.sort((a, b) {
          final nameA = (a['name'] ?? '').toLowerCase();
          final nameB = (b['name'] ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPage(
                          api: widget.api,
                          playerService: widget.playerService,
                          item: playlist,
                          type: DetailType.playlist,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            child: playlist['coverArt'] != null
                                ? CachedNetworkImage(
                                    imageUrl: widget.api.getCoverArtUrl(
                                      playlist['coverArt'],
                                    ),
                                    fit: BoxFit.cover,
                                    width: 56,
                                    height: 56,
                                    placeholder: (context, url) => Icon(
                                      Icons.playlist_play_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.playlist_play_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : Icon(
                                    Icons.playlist_play_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist['name'] ?? '未知歌单',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '歌曲数: ${playlist['songCount'] ?? 0}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
