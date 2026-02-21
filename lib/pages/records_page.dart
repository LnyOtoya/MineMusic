import 'package:flutter/material.dart';
import 'package:expressive_refresh/expressive_refresh.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import '../utils/app_fonts.dart';
import 'settings_page.dart';
import 'detail_page.dart' as dp;

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
  Map<String, dynamic>? _userInfo;
  List<Map<String, dynamic>> _recentTracks = [];
  int _currentPage = 0;
  final int _pageSize = 20;

  TimePeriod _selectedPeriod = TimePeriod.week;
  Map<String, dynamic>? _statsTopTrack;
  Map<String, dynamic>? _statsTopArtist;
  Map<String, dynamic>? _statsTopAlbum;
  String _totalPlayTime = '0h 0m';
  int _totalPlays = 0;
  List<int> _activeHours = List.filled(24, 0);
  List<Map<String, dynamic>> _statsTopTracks = [];

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    if (_tabController.index == 1) {
      _loadStatsData();
    }
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
      final results = await Future.wait([
        _getUserInfo(),
        _getRecentTracks(),
      ]);

      setState(() {
        _userInfo = results[0] as Map<String, dynamic>?;
        final recentTracks = results[1] as List<Map<String, dynamic>>;
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

  Future<Map<String, dynamic>> _getUserInfo() async {
    return {};
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
      final results = await Future.wait([
        _getUserInfo(),
        _getRecentTracks(),
      ]);

      setState(() {
        _userInfo = results[0] as Map<String, dynamic>?;
        _recentTracks = results[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      print('刷新最近播放失败: $e');
    }
  }

  Future<void> _loadStatsData() async {
    try {
      print('Loading stats data for period: ${_selectedPeriod.value}');
      
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedPeriod) {
        case TimePeriod.week:
          final weekDay = now.weekday;
          final daysSinceMonday = weekDay - 1;
          startDate = DateTime(now.year, now.month, now.day - daysSinceMonday);
          break;
        case TimePeriod.month:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case TimePeriod.year:
          startDate = DateTime(now.year, 1, 1);
          break;
      }
      
      print('Time range: $startDate to $now');
      
      final recentTracks = await _getRecentTracks();
      
      final filteredTracks = recentTracks.where((track) {
        final playedAt = track['playedAt'] as DateTime?;
        if (playedAt == null) return false;
        return playedAt.isAfter(startDate) || playedAt.isAtSameMomentAs(startDate);
      }).toList();
      
      print('Filtered ${filteredTracks.length} tracks from ${recentTracks.length} recent tracks');
      
      final artistStats = <String, int>{};
      final albumStats = <String, Map<String, dynamic>>{};
      final trackStats = <String, Map<String, dynamic>>{};
      final activeHours = List.filled(24, 0);
      int totalPlays = 0;
      
      for (var track in filteredTracks) {
        final artist = track['artist'] as String? ?? '';
        final album = track['album'] as String? ?? '';
        final trackName = track['name'] as String? ?? '';
        final playedAt = track['playedAt'] as DateTime?;
        
        if (playedAt == null) continue;
        
        totalPlays++;
        
        artistStats[artist] = (artistStats[artist] ?? 0) + 1;
        
        final albumKey = '$artist - $album';
        if (!albumStats.containsKey(albumKey)) {
          albumStats[albumKey] = {
            'name': album,
            'artist': artist,
            'playcount': 0,
            'images': track['images'] as List<dynamic>? ?? [],
          };
        }
        albumStats[albumKey]!['playcount'] = (albumStats[albumKey]!['playcount'] as int) + 1;
        
        final trackKey = '$artist - $trackName';
        if (!trackStats.containsKey(trackKey)) {
          trackStats[trackKey] = {
            'name': trackName,
            'artist': artist,
            'playcount': 0,
            'images': track['images'] as List<dynamic>? ?? [],
          };
        }
        trackStats[trackKey]!['playcount'] = (trackStats[trackKey]!['playcount'] as int) + 1;
        
        final hour = playedAt.hour;
        activeHours[hour] = activeHours[hour] + 1;
      }
      
      final totalMinutes = totalPlays * 3;
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      
      final sortedArtists = artistStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final sortedAlbums = albumStats.values.toList()
        ..sort((a, b) => (b['playcount'] as int).compareTo(a['playcount'] as int));
      
      final sortedTracks = trackStats.values.toList()
        ..sort((a, b) => (b['playcount'] as int).compareTo(a['playcount'] as int));
      
      final topTrack = sortedTracks.isNotEmpty ? sortedTracks.first : null;
      final topArtist = sortedArtists.isNotEmpty ? sortedArtists.first : null;
      final topAlbum = sortedAlbums.isNotEmpty ? sortedAlbums.first : null;
      
      final topArtistWithImages = topArtist != null ? {
        'name': topArtist.key,
        'playcount': topArtist.value.toString(),
        'images': [],
      } : null;
      
      setState(() {
        _statsTopTracks = sortedTracks.cast<Map<String, dynamic>>();
        _totalPlayTime = '$hours h $minutes m';
        _totalPlays = totalPlays;
        _activeHours = activeHours;
        _statsTopTrack = topTrack;
        _statsTopArtist = topArtistWithImages;
        _statsTopAlbum = topAlbum;
      });
      
      print('Stats data loaded successfully. Total plays: $totalPlays');
    } catch (e) {
      print('Error loading stats data: $e');
    }
  }

  void _onPeriodChanged(TimePeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadStatsData();
  }

  Color _getPeriodColor(ColorScheme colorScheme) {
    switch (_selectedPeriod) {
      case TimePeriod.week:
        return colorScheme.primary;
      case TimePeriod.month:
        return colorScheme.secondary;
      case TimePeriod.year:
        return colorScheme.tertiary;
    }
  }

  String _getHotTracksTitle() {
    switch (_selectedPeriod) {
      case TimePeriod.week:
        return '本周热歌';
      case TimePeriod.month:
        return '本月热歌';
      case TimePeriod.year:
        return '本年热歌';
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
              _buildPeriodSelector(),
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

  Widget _buildPeriodSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TimePeriod.values.asMap().entries.map((entry) {
          final index = entry.key;
          final period = entry.value;
          final isSelected = _selectedPeriod == period;
          final isFirst = index == 0;
          final isLast = index == TimePeriod.values.length - 1;
          
          return GestureDetector(
            onTap: () => _onPeriodChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: isFirst ? const Radius.circular(19) : Radius.zero,
                  bottomLeft: isFirst ? const Radius.circular(19) : Radius.zero,
                  topRight: isLast ? const Radius.circular(19) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(19) : Radius.zero,
                ),
                border: index > 0
                    ? Border(left: BorderSide(
                            color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                            width: 1,
                          ))
                    : null,
              ),
              child: Text(
                period.label,
                style: TextStyle(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsOverview(),
          const SizedBox(height: 24),
          _buildActiveHoursChart(),
          const SizedBox(height: 24),
          _buildHotTracksList(),
        ],
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
          Text(
            '播放统计',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '总播放时长',
                  _totalPlayTime,
                  Icons.access_time_rounded,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '总播放次数',
                  '$_totalPlays 次',
                  Icons.music_note_rounded,
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTopItemCard(
                  '最热门歌曲',
                  _statsTopTrack?['name'] ?? '无',
                  '',
                  Icons.audiotrack_rounded,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTopItemCard(
                  '最热门艺术家',
                  _statsTopArtist?['name'] ?? '无',
                  '',
                  Icons.person_rounded,
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTopItemCard(
            '最热门专辑',
            _statsTopAlbum?['name'] ?? '无',
            '',
            Icons.album_rounded,
            Theme.of(context).colorScheme.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemCard(String title, String value, String playcount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveHoursChart() {
    final colorScheme = Theme.of(context).colorScheme;
    final maxCount = _activeHours.reduce((a, b) => a > b ? a : b);
    final barHeight = maxCount > 0 ? 200.0 / maxCount : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '24小时活跃度',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _getHotTracksTitle(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _getPeriodColor(colorScheme),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (index) {
                final count = _activeHours[index];
                final height = count * barHeight;
                final isSelected = index == DateTime.now().hour;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? _getPeriodColor(colorScheme)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${index}时',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotTracksList() {
    if (_statsTopTracks.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _getHotTracksTitle(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getPeriodColor(Theme.of(context).colorScheme),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_statsTopTracks.length, (index) {
          final track = _statsTopTracks[index];
          return _buildHotTrackItem(track, index);
        }),
      ],
    );
  }

  Widget _buildHotTrackItem(Map<String, dynamic> track, int index) {
    final images = track['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images.last : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
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
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.music_note_rounded,
                        size: 28,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      );
                    },
                  )
                : Icon(
                    Icons.music_note_rounded,
                    size: 28,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        title: Text(
          track['name'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              track['artist'] ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getPeriodColor(Theme.of(context).colorScheme).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${track['playcount']} 次',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getPeriodColor(Theme.of(context).colorScheme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
