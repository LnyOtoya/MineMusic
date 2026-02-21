import 'package:flutter/material.dart';
import 'package:expressive_refresh/expressive_refresh.dart';
import '../services/lastfm_api.dart';
import 'lastfm_auth_page.dart';
import 'settings_page.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import '../utils/app_fonts.dart';

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
  final LastFMApi _api = LastFMApi();
  late TabController _tabController;

  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userInfo;
  List<Map<String, dynamic>> _recentTracks = [];

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
    _tabController.addListener(_onTabChanged);
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    if (_tabController.index == 1 && _isAuthenticated) {
      _loadStatsData();
    }
  }

  Future<void> _checkAuthStatus() async {
    final authenticated = await _api.isAuthenticated();
    
    if (authenticated) {
      await _loadData();
    }
    
    setState(() {
      _isAuthenticated = authenticated;
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _api.getUserInfo(),
        _api.getRecentTracks(limit: 50),
      ]);

      setState(() {
        _userInfo = results[0];
        _recentTracks = results[1]['tracks'] ?? [];
      });
    } catch (e) {
      print('加载数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshRecentTracks() async {
    try {
      final results = await Future.wait([
        _api.getUserInfo(),
        _api.getRecentTracks(limit: 50),
      ]);

      setState(() {
        _userInfo = results[0];
        _recentTracks = results[1]['tracks'] ?? [];
      });
    } catch (e) {
      print('刷新最近播放失败: $e');
    }
  }

  Future<void> _loadStatsData() async {
    if (!_isAuthenticated) return;

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
      
      final recentTracksResult = await _api.getRecentTracks(limit: 200);
      final recentTracks = (recentTracksResult['tracks'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      
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

  Future<void> _handleAuthSuccess() async {
    await _checkAuthStatus();
  }

  Future<void> _handleLogout() async {
    await _api.logout();
    setState(() {
      _isAuthenticated = false;
      _userInfo = null;
      _recentTracks = [];
      _statsTopTrack = null;
      _statsTopArtist = null;
      _statsTopAlbum = null;
      _totalPlayTime = '0h 0m';
      _totalPlays = 0;
      _activeHours = List.filled(24, 0);
      _statsTopTracks = [];
    });
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

    if (!_isAuthenticated) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.audiotrack_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  '未连接 Last.fm',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LastFMAuthPage(
                          onAuthSuccess: () {
                            _handleAuthSuccess();
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('连接 Last.fm'),
                ),
              ],
            ),
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
                    child: Icon(
                      Icons.person_rounded,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
    if (_recentTracks.isEmpty) {
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _recentTracks.length,
        itemBuilder: (context, index) {
          final track = _recentTracks[index];
          return _buildTrackItem(track, index);
        },
      ),
    );
  }

  Widget _buildTrackItem(Map<String, dynamic> track, int index) {
    final images = track['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images.last : null;
    final isNowPlaying = track['isNowPlaying'] as bool? ?? false;
    final playedAt = track['playedAt'] as DateTime?;

    String timeText = '正在播放';
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
        subtitle: Text(
          track['artist'] ?? '',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isNowPlaying
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '正在播放',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                  ),
                ),
              )
            : Text(
                timeText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ExpressiveRefreshIndicator(
      onRefresh: _loadStatsData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最佳艺术家',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_statsTopArtist == null)
                    Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.primary.withOpacity(0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildArtistImage(_statsTopArtist!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statsTopArtist!['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${_statsTopArtist!['playcount'] ?? '0'} 次播放',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
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
          ),
          
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最佳专辑',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_statsTopAlbum == null)
                    Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.primary.withOpacity(0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildAlbumImage(_statsTopAlbum!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statsTopAlbum!['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _statsTopAlbum!['artist'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
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
          ),
          
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最佳单曲',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_statsTopTrack == null)
                    Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.primary.withOpacity(0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildTrackImage(_statsTopTrack!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statsTopTrack!['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _statsTopTrack!['artist'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
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
          ),
          
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '数据概览',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '播放总时长',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _totalPlayTime,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '记录次数',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_totalPlays',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '活跃时间',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(24, (hour) {
                        final intensity = (_activeHours[hour] / 10.0).clamp(0.0, 1.0);
                        final periodColor = _getPeriodColor(colorScheme);
                        return Container(
                          width: 2,
                          height: 40 * intensity,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: periodColor.withOpacity(intensity),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _getHotTracksTitle(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  ..._statsTopTracks.take(5).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final track = entry.value;
                    final playCount = track['playcount'] ?? '0';
                    
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        track['name'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        track['artist'] ?? '',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Chip(
                        label: Text(
                          '$playCount 次',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistImage(Map<String, dynamic> artist) {
    final images = artist['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images.last : null;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person,
            size: 40,
            color: Colors.grey,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
      );
    }
    
    return const Icon(
      Icons.person,
      size: 40,
      color: Colors.grey,
    );
  }

  Widget _buildAlbumImage(Map<String, dynamic> album) {
    final images = album['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images.last : null;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.album,
            size: 40,
            color: Colors.grey,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
      );
    }
    
    return const Icon(
      Icons.album,
      size: 40,
      color: Colors.grey,
    );
  }

  Widget _buildTrackImage(Map<String, dynamic> track) {
    final images = track['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images.last : null;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.music_note,
            size: 40,
            color: Colors.grey,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
      );
    }
    
    return const Icon(
      Icons.music_note,
      size: 40,
      color: Colors.grey,
    );
  }
}
