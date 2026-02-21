import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../services/lastfm_api.dart';
import 'lastfm_auth_page.dart';
import 'lastfm_stats_page_cn.dart';

// 时间周期枚举
enum TimePeriod {
  week('7day', '周'),
  month('1month', '月'),
  year('12month', '年');

  final String value;
  final String label;
  const TimePeriod(this.value, this.label);
}

class LastFMPage extends StatefulWidget {
  const LastFMPage({super.key});

  @override
  State<LastFMPage> createState() => _LastFMPageState();
}

class _LastFMPageState extends State<LastFMPage> with SingleTickerProviderStateMixin {
  final LastFMApi _api = LastFMApi();
  late TabController _tabController;

  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userInfo;
  List<Map<String, dynamic>> _recentTracks = [];
  List<Map<String, dynamic>> _topArtists = [];
  List<Map<String, dynamic>> _topAlbums = [];
  List<Map<String, dynamic>> _topTracks = [];

  // 统计页面状态
  TimePeriod _selectedPeriod = TimePeriod.week;
  Map<String, dynamic>? _statsTopTrack;
  Map<String, dynamic>? _statsTopArtist;
  Map<String, dynamic>? _statsTopAlbum;
  String _totalPlayTime = '0h 0m';
  int _totalPlays = 0;
  List<int> _activeHours = List.filled(24, 0);
  List<int> _dailyPlays = List.filled(7, 0);
  List<Map<String, dynamic>> _statsTopTracks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    
    if (_tabController.index == 1 && _isAuthenticated) {
      _loadStatsData();
    }
  }

  Future<void> _checkAuthStatus() async {
    final authenticated = await _api.isAuthenticated();
    
    if (authenticated) {
      await _loadData();
      await _loadStatsData();
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
        _api.getRecentTracks(limit: 20),
        _api.getTopArtists(limit: 20),
        _api.getTopAlbums(limit: 20),
        _api.getTopTracks(limit: 20),
      ]);

      setState(() {
        _userInfo = results[0];
        _recentTracks = results[1]['tracks'] ?? [];
        _topArtists = results[2]['artists'] ?? [];
        _topAlbums = results[3]['albums'] ?? [];
        _topTracks = results[4]['tracks'] ?? [];
      });
    } catch (e) {
      print('加载数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      _topArtists = [];
      _topAlbums = [];
      _topTracks = [];
      _statsTopTrack = null;
      _statsTopArtist = null;
      _statsTopAlbum = null;
      _totalPlayTime = '0h 0m';
      _totalPlays = 0;
      _activeHours = List.filled(24, 0);
      _dailyPlays = List.filled(7, 0);
      _statsTopTracks = [];
    });
  }

  // 加载统计数据
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
        _dailyPlays = List.filled(7, 0);
        _statsTopTrack = topTrack;
        _statsTopArtist = topArtistWithImages;
        _statsTopAlbum = topAlbum;
      });
      
      print('Stats data loaded successfully. Total plays: $totalPlays');
    } catch (e) {
      print('Error loading stats data: $e');
    }
  }

  // 周期变更处理
  void _onPeriodChanged(TimePeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadStatsData();
  }

  // 获取周期颜色
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

  // 获取热歌列表标题
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

  String _formatPlayCount(String count) {
    final num = int.tryParse(count) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return count;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '正在播放';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final trackDate = DateTime(date.year, date.month, date.day);
    
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';
    
    if (trackDate == today) {
      return timeStr;
    } else if (trackDate == yesterday) {
      return '昨天 $timeStr';
    } else {
      return '${date.month}月${date.day}日 $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Last.fm'),
        actions: [
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadData,
              tooltip: '刷新',
            ),
          if (_isAuthenticated)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'logout') {
                  _showLogoutDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded),
                      SizedBox(width: 12),
                      Text('退出登录'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: _isAuthenticated
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '最近播放'),
                  Tab(text: '统计'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAuthenticated
              ? _buildNotAuthView(colorScheme)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecentTracksTab(colorScheme),
                    _buildStatsTab(colorScheme),
                  ],
                ),
    );
  }

  Widget _buildNotAuthView(ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.audiotrack_rounded,
                size: 80,
                color: colorScheme.primary,
              ),

              const SizedBox(height: 24),

              Text(
                '连接 Last.fm',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                '授权后可以查看您的听歌记录、顶级艺术家等数据',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LastFMAuthPage(
                        onAuthSuccess: _handleAuthSuccess,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.link_rounded),
                label: const Text('连接 Last.fm'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTracksTab(ColorScheme colorScheme) {
    return CustomScrollView(
      slivers: [
        if (_userInfo != null)
          SliverToBoxAdapter(
            child: _buildUserInfoCard(colorScheme),
          ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= _recentTracks.length) return null;
              
              final track = _recentTracks[index];
              return _buildTrackItem(track, colorScheme, index);
            },
            childCount: _recentTracks.length,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard(ColorScheme colorScheme) {
    final images = _userInfo?['images'] as List<dynamic>? ?? [];
    final avatarUrl = images.isNotEmpty ? images.last.toString() : null;

    return Card(
      margin: const EdgeInsets.all(16),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      size: 32,
                      color: colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userInfo?['name'] ?? '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      _buildStatItem(
                        colorScheme,
                        '歌曲',
                        _formatPlayCount(_userInfo?['track_count'] ?? '0'),
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        colorScheme,
                        '艺术家',
                        _formatPlayCount(_userInfo?['artist_count'] ?? '0'),
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        colorScheme,
                        '专辑',
                        _formatPlayCount(_userInfo?['album_count'] ?? '0'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '总播放: ${_formatPlayCount(_userInfo?['playcount'] ?? '0')} 次',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.8),
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

  Widget _buildStatItem(ColorScheme colorScheme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackItem(Map<String, dynamic> track, ColorScheme colorScheme, int index) {
    final images = track['images'] as List<dynamic>? ?? [];
    final coverUrl = images.isNotEmpty ? images.last.toString() : null;
    final isNowPlaying = track['isNowPlaying'] ?? false;

    return ListTile(
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: coverUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                Icons.music_note_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              track['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isNowPlaying ? colorScheme.primary : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isNowPlaying)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '正在播放',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${track['artist']} · ${track['album'] ?? ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatDate(track['playedAt']),
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTopArtistsTab(ColorScheme colorScheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _topArtists.length,
      itemBuilder: (context, index) {
        final artist = _topArtists[index];
        final images = artist['images'] as List<dynamic>? ?? [];
        final coverUrl = images.isNotEmpty ? images.last.toString() : null;

        return Card(
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: coverUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: coverUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    artist['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatPlayCount(artist['playcount'] ?? '0'),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopAlbumsTab(ColorScheme colorScheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _topAlbums.length,
      itemBuilder: (context, index) {
        final album = _topAlbums[index];
        final images = album['images'] as List<dynamic>? ?? [];
        final coverUrl = images.isNotEmpty ? images.last.toString() : null;

        return Card(
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: coverUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: coverUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.album_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    album['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    album['artist'] ?? '',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatPlayCount(album['playcount'] ?? '0'),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopTracksTab(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topTracks.length,
      itemBuilder: (context, index) {
        final track = _topTracks[index];
        final images = track['images'] as List<dynamic>? ?? [];
        final coverUrl = images.isNotEmpty ? images.last.toString() : null;

        return Card(
          child: ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.music_note_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
            title: Text(
              track['name'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track['artist'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatPlayCount(track['playcount'] ?? '0'),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出 Last.fm 登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  // 构建统计标签页
  Widget _buildStatsTab(ColorScheme colorScheme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
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
                          horizontal: 20,
                          vertical: 8,
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
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
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
