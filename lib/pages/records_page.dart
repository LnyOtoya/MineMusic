import 'package:flutter/material.dart';
import 'package:expressive_refresh/expressive_refresh.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import '../utils/app_fonts.dart';
import 'settings_page.dart';
import 'detail_page.dart' as dp;
import 'artist_detail_page.dart';

enum TimePeriod {
  week('7day', '周'),
  month('1month', '月'),
  year('12month', '年');

  final String value;
  final String label;
  const TimePeriod(this.value, this.label);
}

enum RecordTab {
  recent('最近播放'),
  stats('统计');

  final String label;
  const RecordTab(this.label);
}

class RecordsPage extends StatefulWidget {
  final SubsonicApi? api;
  final PlayerService? playerService;
  final Function(ThemeMode)? setThemeMode;

  const RecordsPage({
    super.key,
    this.api,
    this.playerService,
    this.setThemeMode,
  });

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _recentTracks = [];
  int _currentPage = 0;
  final int _pageSize = 20;

  List<Map<String, dynamic>> _topAlbums = [];
  List<Map<String, dynamic>> _topArtists = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadData();
    _loadStatsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final recentTracks = await _getRecentTracks();

      setState(() {
        _recentTracks = recentTracks;
        _hasMore = recentTracks.length >= _pageSize;
      });
    } catch (e) {
      print('加载数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentTracks() async {
    if (widget.api == null) return [];
    return await widget.api!.getRecentAlbums(size: _pageSize, offset: _currentPage * _pageSize);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || widget.api == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newTracks = await widget.api!.getRecentAlbums(
        size: _pageSize,
        offset: (_currentPage + 1) * _pageSize,
      );

      setState(() {
        _recentTracks.addAll(newTracks);
        _currentPage++;
        _hasMore = newTracks.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('加载更多失败: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshRecentTracks() async {
    try {
      final startTime = DateTime.now();
      final recentTracks = await _getRecentTracks();
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime.inMilliseconds < 800) {
        await Future.delayed(Duration(milliseconds: 800 - elapsedTime.inMilliseconds));
      }

      setState(() {
        _recentTracks = recentTracks;
      });
    } catch (e) {
      print('刷新最近播放失败: $e');
    }
  }

  Future<void> _loadStatsData() async {
    try {
      final topAlbums = await widget.api?.getFrequentAlbums(size: 5) ?? [];
      
      final artistStats = <String, Map<String, dynamic>>{};
      
      for (var album in topAlbums) {
        final artist = album['artist'] as String?;
        final artistId = album['artistId'] as String?;
        final albumCoverArt = album['coverArt'] as String?;
        if (artist != null) {
          if (!artistStats.containsKey(artist)) {
            artistStats[artist] = {
              'name': artist,
              'id': artistId,
              'playcount': 0,
              'albumCoverArt': albumCoverArt,
            };
          }
          final playCount = int.tryParse(album['playCount'] as String? ?? '0') ?? 0;
          artistStats[artist]!['playcount'] = (artistStats[artist]!['playcount'] as int) + playCount;
        }
      }
      
      // 获取艺术家列表以获取 coverArt
      final allArtists = await widget.api?.getArtists() ?? [];
      final artistCoverArtMap = <String, String?>{};
      for (var artist in allArtists) {
        final name = artist['name'] as String?;
        final coverArt = artist['coverArt'] as String?;
        if (name != null) {
          artistCoverArtMap[name] = coverArt;
        }
      }
      
      final sortedArtists = artistStats.values.toList()
        ..sort((a, b) => (b['playcount'] as int).compareTo(a['playcount'] as int));
      
      // 将 coverArt 添加到艺术家数据中，如果没有则使用专辑封面
      for (var artist in sortedArtists) {
        final name = artist['name'] as String?;
        if (name != null) {
          final artistCoverArt = artistCoverArtMap[name];
          artist['coverArt'] = artistCoverArt ?? artist['albumCoverArt'];
        }
      }
      
      setState(() {
        _topAlbums = topAlbums;
        _topArtists = sortedArtists;
      });
      
      print('Stats data loaded successfully');
    } catch (e) {
      print('Error loading stats data: $e');
    }
  }

  Future<void> _refreshStatsData() async {
    try {
      final startTime = DateTime.now();
      
      final topAlbums = await widget.api?.getFrequentAlbums(size: 5) ?? [];
      
      final artistStats = <String, Map<String, dynamic>>{};
      
      for (var album in topAlbums) {
        final artist = album['artist'] as String?;
        final artistId = album['artistId'] as String?;
        final albumCoverArt = album['coverArt'] as String?;
        if (artist != null) {
          if (!artistStats.containsKey(artist)) {
            artistStats[artist] = {
              'name': artist,
              'id': artistId,
              'playcount': 0,
              'albumCoverArt': albumCoverArt,
            };
          }
          final playCount = int.tryParse(album['playCount'] as String? ?? '0') ?? 0;
          artistStats[artist]!['playcount'] = (artistStats[artist]!['playcount'] as int) + playCount;
        }
      }
      
      // 获取艺术家列表以获取 coverArt
      final allArtists = await widget.api?.getArtists() ?? [];
      final artistCoverArtMap = <String, String?>{};
      for (var artist in allArtists) {
        final name = artist['name'] as String?;
        final coverArt = artist['coverArt'] as String?;
        if (name != null) {
          artistCoverArtMap[name] = coverArt;
        }
      }
      
      final sortedArtists = artistStats.values.toList()
        ..sort((a, b) => (b['playcount'] as int).compareTo(a['playcount'] as int));
      
      // 将 coverArt 添加到艺术家数据中，如果没有则使用专辑封面
      for (var artist in sortedArtists) {
        final name = artist['name'] as String?;
        if (name != null) {
          final artistCoverArt = artistCoverArtMap[name];
          artist['coverArt'] = artistCoverArt ?? artist['albumCoverArt'];
        }
      }
      
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime.inMilliseconds < 800) {
        await Future.delayed(Duration(milliseconds: 800 - elapsedTime.inMilliseconds));
      }
      
      setState(() {
        _topAlbums = topAlbums;
        _topArtists = sortedArtists;
      });
      
      print('Stats data refreshed successfully');
    } catch (e) {
      print('Error refreshing stats data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = '听歌记录';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.getTextStyle(
                    text: title,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.8,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // _buildPeriodSelector(),
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
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    child: _buildUserAvatar(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Icon(
      Icons.person_rounded,
      color: Theme.of(context).colorScheme.onSecondaryContainer,
      size: 32,
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '最近播放'),
          Tab(text: '统计'),
        ],
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildRecentTracksTab(),
        _buildStatsTab(),
      ],
    );
  }

  Widget _buildRecentTracksTab() {
    if (_recentTracks.isEmpty && !_isLoading) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          height: 300,
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
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无播放记录',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ExpressiveRefreshIndicator(
      onRefresh: _refreshRecentTracks,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _recentTracks.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _recentTracks.length) {
            return _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox.shrink();
          }
          final track = _recentTracks[index];
          return _buildTrackItem(track, index);
        },
      ),
    );
  }

  Widget _buildTrackItem(Map<String, dynamic> track, int index) {
    final coverArtId = track['coverArt'] as String?;
    final playedAt = track['played'] as DateTime?;
    final playCount = track['playCount'] as String?;

    String timeText = '刚刚播放';
    if (playedAt != null) {
      final now = DateTime.now();
      final difference = now.difference(playedAt);
      
      if (difference.inMinutes < 60) {
        timeText = '${difference.inMinutes} 分钟前';
      } else if (difference.inHours < 24) {
        timeText = '${difference.inHours} 小时前';
      } else if (difference.inDays < 7) {
        timeText = '${difference.inDays} 天前';
      } else {
        timeText = '${playedAt.month}月${playedAt.day}日 ${playedAt.hour.toString().padLeft(2, '0')}:${playedAt.minute.toString().padLeft(2, '0')}';
      }
    }

    String coverUrl = '';
    if (widget.api != null && coverArtId != null) {
      coverUrl = widget.api!.getCoverArtUrl(coverArtId);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: coverUrl.isNotEmpty
                ? Image.network(
                    coverUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.album_rounded,
                        size: 28,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      );
                    },
                  )
                : Icon(
                    Icons.album_rounded,
                    size: 28,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        title: Text(
          track['name'] ?? track['title'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track['artist'] ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  timeText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                if (playCount != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$playCount 次',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () async {
          if (track['id'] != null && widget.api != null && widget.playerService != null) {
            final songs = await widget.api!.getSongsByAlbum(track['id']);
            if (songs.isNotEmpty && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => dp.DetailPage(
                    api: widget.api!,
                    playerService: widget.playerService!,
                    item: track,
                    type: dp.DetailType.album,
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildStatsTab() {
    return ExpressiveRefreshIndicator(
      onRefresh: _refreshStatsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsOverview(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopAlbumsSection(),
          const SizedBox(height: 24),
          _buildTopArtistsSection(),
        ],
      ),
    );
  }

  Widget _buildTopAlbumsSection() {
    if (_topAlbums.isEmpty) {
      return _buildEmptySection('最热门专辑', Icons.album_rounded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最热门专辑',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTopAlbumsList(),
      ],
    );
  }

  Widget _buildTopAlbumsList() {
    if (_topAlbums.isEmpty) return const SizedBox.shrink();

    final albums = _topAlbums.take(5).toList();
    if (albums.isEmpty) return const SizedBox.shrink();

    // 使用 MediaQuery 获取屏幕宽度，保证多设备适配
    final screenWidth = MediaQuery.of(context).size.width;

    // 非对称轮播图
    return SizedBox(
      height: 280,
      child: CarouselView(
        // itemExtent 定义主卡片的宽度
        // 使用 screenWidth * 0.65 确保主卡片占屏幕宽度的 65%
        // 这样可以确保：
        // 1. 主卡片完整显示（100% 可见）
        // 2. 屏幕右侧能露出下一张卡片的一部分（35% 宽度）
        // 3. 暗示用户可以向右滚动查看更多内容
        itemExtent: screenWidth * 0.65,
        
        // itemSnapping: true 启用吸附机制
        // 当用户停止滑动时，组件会自动将最靠近边缘的卡片对齐
        // 确保每一张卡片在成为焦点时都是 100% 完整显示的
        itemSnapping: true,
        
        // padding 定义轮播图的内边距
        // 使用 padding 来控制卡片间的缝隙，而不是在 Card 内部加 Margin
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        
        // enableSplash 启用水波纹点击效果
        enableSplash: true,
        
        // onTap 处理卡片点击事件
        onTap: (index) {
          if (index < albums.length) {
            final album = albums[index];
            _onAlbumTap(album);
          }
        },
        
        // children 定义轮播图的子项
        children: albums.map((album) {
          return _buildTopAlbumCard(album, isLarge: true);
        }).toList(),
      ),
    );
  }

  Widget _buildTopAlbumCard(Map<String, dynamic> album, {required bool isLarge}) {
    final coverArtId = album['coverArt'] as String?;

    String coverUrl = '';
    if (widget.api != null && coverArtId != null) {
      coverUrl = widget.api!.getCoverArtUrl(coverArtId);
    }

    return Container(
      decoration: BoxDecoration(
        // 大圆角设计（32.0）
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图片，使用 BoxFit.cover 填充整个卡片
          if (coverUrl.isNotEmpty)
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(context);
              },
            )
          else
            _buildPlaceholder(context),
          
          // 在卡片底部添加渐变遮罩和文本
          if (album['name'] != null || album['artist'] != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (album['name'] != null)
                      Text(
                        album['name'] as String,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (album['artist'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          album['artist'] as String,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建占位符（当图片加载失败或没有图片时）
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        Icons.album_rounded,
        size: 64,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Future<void> _onAlbumTap(Map<String, dynamic> album) async {
    if (album['id'] != null && widget.api != null && widget.playerService != null) {
      final songs = await widget.api!.getSongsByAlbum(album['id']);
      if (songs.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => dp.DetailPage(
              api: widget.api!,
              playerService: widget.playerService!,
              item: album,
              type: dp.DetailType.album,
            ),
          ),
        );
      }
    }
  }

  Widget _buildTopArtistsSection() {
    if (_topArtists.isEmpty) {
      return _buildEmptySection('最热门艺术家', Icons.person_rounded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最热门艺术家',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTopArtistsList(),
      ],
    );
  }

  Widget _buildTopArtistsList() {
    if (_topArtists.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // 最热门艺术家（大头像）
        _buildTopArtistCard(_topArtists[0], isLarge: true),
        if (_topArtists.length > 1) ...[
          const SizedBox(height: 16),
          // 剩下的艺术家（排名列表）
          Column(
            children: _topArtists.skip(1).take(4).toList().asMap().entries.map((entry) {
              final index = entry.key + 2; // 从 #2 开始
              final artist = entry.value;
              return _buildArtistRankItem(artist, index);
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// 构建艺术家排名项（小项）
  Widget _buildArtistRankItem(Map<String, dynamic> artist, int rank) {
    final name = artist['name'] as String? ?? '';
    final playCount = artist['playcount'] as int? ?? 0;
    final coverArtId = artist['coverArt'] as String?;

    String coverUrl = '';
    if (widget.api != null && coverArtId != null) {
      coverUrl = widget.api!.getCoverArtUrl(coverArtId);
    }

    return GestureDetector(
      onTap: () async {
        if (artist['id'] != null && widget.api != null && widget.playerService != null) {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ArtistDetailPage(
                api: widget.api!,
                playerService: widget.playerService!,
                artist: artist,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 排名
            Text(
              '#$rank',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            // 艺术家头像
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          );
                        },
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // 艺术家名字
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // 播放次数
            Text(
              '$playCount 次',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArtistCard(Map<String, dynamic> artist, {required bool isLarge}) {
    final name = artist['name'] as String? ?? '';
    final playCount = artist['playcount'] as int? ?? 0;
    final coverArtId = artist['coverArt'] as String?;

    String coverUrl = '';
    if (widget.api != null && coverArtId != null) {
      coverUrl = widget.api!.getCoverArtUrl(coverArtId);
    }

    return GestureDetector(
      onTap: () async {
        if (artist['id'] != null && widget.api != null && widget.playerService != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistDetailPage(
                api: widget.api!,
                playerService: widget.playerService!,
                artist: artist,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: isLarge ? const EdgeInsets.all(0) : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
        ),
        child: isLarge 
          ? Container(
              height: 240,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 大头像容器
                  Container(
                    width: double.infinity,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: coverUrl.isNotEmpty
                          ? Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person_rounded,
                                  size: 120,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                );
                              },
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 120,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
                  // Top Artist 标签
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Top Artist',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 艺术家名字和排名
                  Positioned(
                    bottom: 48,
                    left: 16,
                    child: Text(
                      '#1 $name',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 播放次数
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Text(
                      '$playCount 次',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(), // 小卡片不再使用，因为我们用排名列表代替
      ),
    );
  }

  Widget _buildEmptySection(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无$title数据',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
