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
  int _selectedTab = 0; // 0: 专辑, 1: 艺人

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 8),
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
          label: Text('专辑'),
          icon: Icon(Icons.album_rounded),
        ),
        ButtonSegment(
          value: 1,
          label: Text('艺人'),
          icon: Icon(Icons.person_rounded),
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
        return AlbumsTab(api: widget.api, playerService: widget.playerService);
      case 1:
        return ArtistsTab(api: widget.api, playerService: widget.playerService);
      default:
        return AlbumsTab(api: widget.api, playerService: widget.playerService);
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
