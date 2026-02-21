import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/lastfm_api.dart';
import 'package:intl/intl.dart';

enum TimePeriod {
  week('week', '本周'),
  month('month', '本月'),
  quarter('quarter', '本季度'),
  year('year', '今年'),
  overall('overall', '全部');

  final String value;
  final String label;
  const TimePeriod(this.value, this.label);
}

class LastFMStatsPage extends StatefulWidget {
  const LastFMStatsPage({super.key});

  @override
  State<LastFMStatsPage> createState() => _LastFMStatsPageState();
}

class _LastFMStatsPageState extends State<LastFMStatsPage> {
  final LastFMApi _api = LastFMApi();
  
  TimePeriod _selectedPeriod = TimePeriod.overall;
  bool _isLoading = true;
  
  Map<String, dynamic>? _userInfo;
  List<Map<String, dynamic>> _topArtists = [];
  List<Map<String, dynamic>> _topTracks = [];
  List<Map<String, dynamic>> _topAlbums = [];
  
  int _totalPlays = 0;
  int _uniqueArtists = 0;
  int _uniqueTracks = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _api.getUserInfo(),
        _api.getTopArtists(limit: 50, period: _selectedPeriod.value),
        _api.getTopTracks(limit: 50, period: _selectedPeriod.value),
        _api.getTopAlbums(limit: 50, period: _selectedPeriod.value),
      ]);

      final userInfo = results[0] as Map<String, dynamic>;
      final artists = (results[1] as Map<String, dynamic>)['artists'] as List<dynamic>? ?? [];
      final tracks = (results[2] as Map<String, dynamic>)['tracks'] as List<dynamic>? ?? [];
      final albums = (results[3] as Map<String, dynamic>)['albums'] as List<dynamic>? ?? [];

      int totalPlays = 0;
      for (var track in tracks) {
        totalPlays += int.tryParse(track['playcount'] ?? '0') ?? 0;
      }

      setState(() {
        _userInfo = userInfo;
        _topArtists = artists.cast<Map<String, dynamic>>();
        _topTracks = tracks.cast<Map<String, dynamic>>();
        _topAlbums = albums.cast<Map<String, dynamic>>();
        _totalPlays = totalPlays;
        _uniqueArtists = artists.length;
        _uniqueTracks = tracks.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  void _onPeriodChanged(TimePeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('听歌统计'),
        actions: [
          PopupMenuButton<TimePeriod>(
            icon: const Icon(Icons.calendar_today_rounded),
            onSelected: _onPeriodChanged,
            initialValue: _selectedPeriod,
            itemBuilder: (context) => TimePeriod.values.map((period) {
              return PopupMenuItem(
                value: period,
                child: Row(
                  children: [
                    Icon(
                      period == _selectedPeriod ? Icons.check_rounded : Icons.circle_outlined,
                      size: 16,
                    ),
                    const SizedBox(width: 12),
                    Text(period.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewCard(colorScheme),
                  const SizedBox(height: 16),
                  _buildPlayTrendChart(colorScheme),
                  const SizedBox(height: 16),
                  _buildTopArtistsChart(colorScheme),
                  const SizedBox(height: 16),
                  _buildTopTracksList(colorScheme),
                  const SizedBox(height: 16),
                  _buildTopAlbumsList(colorScheme),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCard(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedPeriod.label}统计',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      _userInfo != null ? '用户: ${_userInfo!['name']}' : '',
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '总播放',
                  _totalPlays.toString(),
                  Icons.play_circle_rounded,
                  colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '艺术家',
                  _uniqueArtists.toString(),
                  Icons.person_rounded,
                  colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '歌曲',
                  _uniqueTracks.toString(),
                  Icons.music_note_rounded,
                  colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayTrendChart(ColorScheme colorScheme) {
    final top10Artists = _topArtists.take(10).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '艺术家播放排行',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: top10Artists.isNotEmpty
                    ? (int.tryParse(top10Artists.first['playcount'] ?? '0') ?? 0) * 1.2
                    : 100,
                minY: 0,
                barGroups: top10Artists.asMap().entries.map((entry) {
                  final index = entry.key;
                  final artist = entry.value;
                  final playCount = int.tryParse(artist['playcount'] ?? '0') ?? 0;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: playCount.toDouble(),
                        color: colorScheme.primary,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= top10Artists.length) {
                          return const SizedBox.shrink();
                        }
                        final artist = top10Artists[value.toInt()];
                        final name = artist['name'] as String? ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            name.length > 5 ? '${name.substring(0, 5)}...' : name,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopArtistsChart(ColorScheme colorScheme) {
    final top10Artists = _topArtists.take(10).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '艺术家分布',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: top10Artists.asMap().entries.map((entry) {
                  final artist = entry.value;
                  final playCount = int.tryParse(artist['playcount'] ?? '0') ?? 0;
                  final total = top10Artists.fold<int>(
                    0,
                    (sum, a) => sum + (int.tryParse(a['playcount'] ?? '0') ?? 0),
                  );
                  final percentage = total > 0 ? playCount / total : 0.0;
                  
                  return PieChartSectionData(
                    value: playCount.toDouble(),
                    title: '${(percentage * 100).toStringAsFixed(1)}%',
                    color: Color.lerp(
                      colorScheme.primary,
                      colorScheme.tertiary,
                      entry.key / top10Artists.length,
                    ) ?? colorScheme.primary,
                    radius: 50,
                    titleStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: top10Artists.map((artist) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    artist['name'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTracksList(ColorScheme colorScheme) {
    final top10Tracks = _topTracks.take(10).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '热门歌曲',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...top10Tracks.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          track['artist'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${track['playcount']} 次',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopAlbumsList(ColorScheme colorScheme) {
    final top5Albums = _topAlbums.take(5).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '热门专辑',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...top5Albums.asMap().entries.map((entry) {
            final index = entry.key;
            final album = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          album['artist'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${album['playcount']} 次',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
